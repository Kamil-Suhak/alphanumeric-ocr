import argparse
import json
from pathlib import Path
import sys
import time
from typing import Any, Dict, Iterator, List, Optional, Tuple
import numpy as np
import onnx
import onnxruntime as ort
from onnxruntime.quantization import CalibrationDataReader, QuantFormat, QuantType, quantize_static
import torch
from torch.utils.data import DataLoader, Subset
from torchvision.datasets import EMNIST

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(PROJECT_ROOT))

from src.config import RAW_EMNIST_DIR, RUNS_DIR, TABLES_DIR, resolve_checkpoint_path
from src.data.emnist import get_raw_emnist_datasets
from src.experiments.degradation_sweep import ControlledDegradationDataset, build_degradation_fn
from src.training.evaluate import evaluate_model
from src.training.runner import load_eval_model
from src.utils.metrics import compute_metrics

EDGE_EVAL_CONDITIONS: List[Tuple[str, str, float]] = [
    ("clean", "clean", 0.0),
    ("blur_2.0", "blur", 2.0),
    ("noise_0.20", "noise", 0.20),
    ("perspective_0.25", "perspective", 0.25),
]


class EmnistCalibrationDataReader(CalibrationDataReader):
    """Dostarcza próbki walidacyjne (bez użycia zbioru testowego) do kalibracji statycznej INT8."""

    def __init__(self, loader: DataLoader, input_name: str):
        self.input_name = input_name
        self._batches: List[np.ndarray] = [images.numpy().astype(np.float32) for images, _ in loader]
        self._iter: Iterator[np.ndarray] = iter(self._batches)

    def get_next(self) -> Optional[Dict[str, np.ndarray]]:
        batch = next(self._iter, None)
        if batch is None:
            return None
        return {self.input_name: batch}

    def rewind(self) -> None:
        self._iter = iter(self._batches)


def export_onnx_fp32(model: torch.nn.Module, output_path: Path) -> Path:
    """Eksportuje model PyTorch AlphanumericCNN do formatu ONNX FP32 z dynamicznym rozmiarem partii."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    model_cpu = model.cpu().eval()
    dummy_input = torch.randn(1, 1, 32, 32, dtype=torch.float32)
    torch.onnx.export(
        model_cpu,
        dummy_input,
        str(output_path),
        input_names=["input"],
        output_names=["logits"],
        dynamic_axes={"input": {0: "batch_size"}, "logits": {0: "batch_size"}},
        opset_version=18,
        dynamo=False,
    )
    onnx_model = onnx.load(str(output_path))
    onnx.checker.check_model(onnx_model)
    return output_path


def quantize_onnx_static_int8(
    fp32_onnx_path: Path,
    int8_onnx_path: Path,
    calib_loader: DataLoader,
) -> Path:
    """Wykonuje statyczną kwantyzację post-treningową (QDQ INT8/UINT8) na podstawie danych walidacyjnych."""
    int8_onnx_path.parent.mkdir(parents=True, exist_ok=True)
    session = ort.InferenceSession(str(fp32_onnx_path), providers=["CPUExecutionProvider"])
    input_name = session.get_inputs()[0].name
    reader = EmnistCalibrationDataReader(calib_loader, input_name=input_name)

    quantize_static(
        model_input=str(fp32_onnx_path),
        model_output=str(int8_onnx_path),
        calibration_data_reader=reader,
        quant_format=QuantFormat.QDQ,
        activation_type=QuantType.QUInt8,
        weight_type=QuantType.QInt8,
    )
    return int8_onnx_path


def create_ort_session(onnx_path: Path, threads: Optional[int] = None) -> ort.InferenceSession:
    opts = ort.SessionOptions()
    if threads is not None:
        opts.intra_op_num_threads = threads
    return ort.InferenceSession(str(onnx_path), sess_options=opts, providers=["CPUExecutionProvider"])


def benchmark_pytorch_cpu(model: torch.nn.Module, batch_size: int, warmup: int, iterations: int) -> float:
    model.eval()
    dummy = torch.randn(batch_size, 1, 32, 32, dtype=torch.float32)
    with torch.no_grad():
        for _ in range(warmup):
            _ = model(dummy)
        start = time.perf_counter()
        for _ in range(iterations):
            _ = model(dummy)
        elapsed = time.perf_counter() - start
    return (elapsed / iterations) * 1000.0


def benchmark_onnx_cpu(session: ort.InferenceSession, batch_size: int, warmup: int, iterations: int) -> float:
    input_name = session.get_inputs()[0].name
    output_name = session.get_outputs()[0].name
    dummy = np.random.default_rng(0).standard_normal((batch_size, 1, 32, 32), dtype=np.float32)
    for _ in range(warmup):
        _ = session.run([output_name], {input_name: dummy})
    start = time.perf_counter()
    for _ in range(iterations):
        _ = session.run([output_name], {input_name: dummy})
    elapsed = time.perf_counter() - start
    return (elapsed / iterations) * 1000.0


def evaluate_onnx_session(session: ort.InferenceSession, loader: DataLoader) -> Dict[str, Any]:
    input_name = session.get_inputs()[0].name
    output_name = session.get_outputs()[0].name
    y_true_parts: List[np.ndarray] = []
    y_pred_parts: List[np.ndarray] = []

    for images, targets in loader:
        logits = session.run([output_name], {input_name: images.numpy().astype(np.float32)})[0]
        preds = logits.argmax(axis=1)
        y_true_parts.append(targets.numpy())
        y_pred_parts.append(preds)

    y_true = np.concatenate(y_true_parts)
    y_pred = np.concatenate(y_pred_parts)
    return compute_metrics(y_true, y_pred)


def run_edge_benchmark(
    run_name: str,
    calib_samples: int = 1000,
    eval_seed: int = 123,
    batch_size: int = 512,
    warmup: int = 100,
    iterations: int = 1000,
    max_eval_samples: Optional[int] = None,
    threads: Optional[int] = None,
    onnx_dir: Optional[Path] = None,
) -> Dict[str, Any]:
    """Eksportuje ONNX FP32/INT8, profiluje opóźnienia CPU i mierzy retencję dokładności."""
    cpu = torch.device("cpu")
    model = load_eval_model(run_name, device=cpu)
    ckpt_path = resolve_checkpoint_path(run_name)
    total_params = sum(p.numel() for p in model.parameters())
    fp32_weights_mb = (total_params * 4) / (1024 * 1024)

    _, val_set, _ = get_raw_emnist_datasets(seed=123)
    calib_count = min(calib_samples, len(val_set))
    calib_subset = Subset(val_set, list(range(calib_count)))
    calib_loader = DataLoader(calib_subset, batch_size=min(64, calib_count), shuffle=False)

    target_onnx_dir = onnx_dir if onnx_dir is not None else (RUNS_DIR / Path(run_name).name / "onnx")
    fp32_onnx_path = export_onnx_fp32(model, target_onnx_dir / "model_fp32.onnx")
    int8_onnx_path = quantize_onnx_static_int8(
        fp32_onnx_path, target_onnx_dir / "model_int8.onnx", calib_loader=calib_loader
    )

    fp32_sess = create_ort_session(fp32_onnx_path, threads=threads)
    int8_sess = create_ort_session(int8_onnx_path, threads=threads)

    pt_b1 = benchmark_pytorch_cpu(model, batch_size=1, warmup=warmup, iterations=iterations)
    pt_b32 = benchmark_pytorch_cpu(model, batch_size=32, warmup=warmup, iterations=iterations)
    ort_fp32_b1 = benchmark_onnx_cpu(fp32_sess, batch_size=1, warmup=warmup, iterations=iterations)
    ort_fp32_b32 = benchmark_onnx_cpu(fp32_sess, batch_size=32, warmup=warmup, iterations=iterations)
    ort_int8_b1 = benchmark_onnx_cpu(int8_sess, batch_size=1, warmup=warmup, iterations=iterations)
    ort_int8_b32 = benchmark_onnx_cpu(int8_sess, batch_size=32, warmup=warmup, iterations=iterations)

    raw_test = EMNIST(root=str(RAW_EMNIST_DIR), split="byclass", train=False, download=False, transform=None)
    if max_eval_samples is None:
        eval_ds = raw_test
    else:
        eval_ds = Subset(raw_test, list(range(min(max_eval_samples, len(raw_test)))))

    accuracy_by_variant: Dict[str, Dict[str, Dict[str, float]]] = {
        "pytorch_fp32": {},
        "onnx_fp32": {},
        "onnx_int8": {},
    }

    for cond_name, deg_type, level in EDGE_EVAL_CONDITIONS:
        deg_fn = build_degradation_fn(deg_type, level)
        ctrl_ds = ControlledDegradationDataset(eval_ds, degradation_fn=deg_fn, seed=eval_seed)
        loader = DataLoader(ctrl_ds, batch_size=batch_size, shuffle=False)

        pt_metrics, _, _ = evaluate_model(model, loader, device=cpu)
        ort_fp32_metrics = evaluate_onnx_session(fp32_sess, loader)
        ort_int8_metrics = evaluate_onnx_session(int8_sess, loader)

        for variant_key, m in [
            ("pytorch_fp32", pt_metrics),
            ("onnx_fp32", ort_fp32_metrics),
            ("onnx_int8", ort_int8_metrics),
        ]:
            accuracy_by_variant[variant_key][cond_name] = {
                "accuracy_pct": round(m["accuracy"] * 100.0, 2),
                "macro_f1_pct": round(m["macro_f1"] * 100.0, 2),
                "case_insensitive_acc_pct": round(m["case_insensitive_accuracy"] * 100.0, 2),
            }

    fp32_onnx_mb = fp32_onnx_path.stat().st_size / (1024 * 1024)
    int8_onnx_mb = int8_onnx_path.stat().st_size / (1024 * 1024)

    return {
        "source_run": run_name,
        "checkpoint_path": str(ckpt_path),
        "calibration_samples": calib_count,
        "eval_samples": len(eval_ds),
        "eval_seed": eval_seed,
        "benchmark_config": {"warmup": warmup, "iterations": iterations, "threads": threads},
        "artifacts": {
            "fp32_onnx_path": str(fp32_onnx_path),
            "int8_onnx_path": str(int8_onnx_path),
        },
        "variants": {
            "pytorch_fp32": {
                "size_mb": round(fp32_weights_mb, 3),
                "checkpoint_size_mb": round(ckpt_path.stat().st_size / (1024 * 1024), 3),
                "cpu_latency_b1_ms": round(pt_b1, 3),
                "cpu_latency_b32_ms": round(pt_b32, 3),
                "cpu_throughput_b32_chars_sec": round(32000.0 / pt_b32, 1),
                "evaluation": accuracy_by_variant["pytorch_fp32"],
            },
            "onnx_fp32": {
                "size_mb": round(fp32_onnx_mb, 3),
                "cpu_latency_b1_ms": round(ort_fp32_b1, 3),
                "cpu_latency_b32_ms": round(ort_fp32_b32, 3),
                "cpu_throughput_b32_chars_sec": round(32000.0 / ort_fp32_b32, 1),
                "evaluation": accuracy_by_variant["onnx_fp32"],
            },
            "onnx_int8": {
                "size_mb": round(int8_onnx_mb, 3),
                "compression_vs_onnx_fp32": round(fp32_onnx_mb / max(int8_onnx_mb, 1e-6), 2),
                "cpu_latency_b1_ms": round(ort_int8_b1, 3),
                "cpu_latency_b32_ms": round(ort_int8_b32, 3),
                "cpu_throughput_b32_chars_sec": round(32000.0 / ort_int8_b32, 1),
                "evaluation": accuracy_by_variant["onnx_int8"],
            },
        },
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="EXP-008: ONNX FP32/INT8 quantization & CPU runtime benchmark.")
    parser.add_argument("--run", type=str, default="EXP-002_robust_seed123")
    parser.add_argument("--calib-samples", type=int, default=1000)
    parser.add_argument("--eval-seed", type=int, default=123)
    parser.add_argument("--batch-size", type=int, default=512)
    parser.add_argument("--warmup", type=int, default=100)
    parser.add_argument("--iterations", type=int, default=1000)
    parser.add_argument("--max-eval-samples", type=int, default=None)
    parser.add_argument("--threads", type=int, default=None)
    parser.add_argument("--output", type=Path, default=TABLES_DIR / "edge_practicality.json")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    report = run_edge_benchmark(
        run_name=args.run,
        calib_samples=args.calib_samples,
        eval_seed=args.eval_seed,
        batch_size=args.batch_size,
        warmup=args.warmup,
        iterations=args.iterations,
        max_eval_samples=args.max_eval_samples,
        threads=args.threads,
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
    print(f"Zapisano wyniki benchmarku edge do: {args.output}")


if __name__ == "__main__":
    main()
