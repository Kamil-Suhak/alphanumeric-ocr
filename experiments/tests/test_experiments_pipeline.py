import csv
import json
from pathlib import Path
import numpy as np
from PIL import Image
import pytest
import torch
from torch.utils.data import DataLoader, TensorDataset

from scripts import benchmark_edge_optimization as edge_script
from scripts import evaluate_compounded_stress as compound_script
from scripts import evaluate_motion_blur_ood as motion_script
from scripts import export_error_diagnostics as error_script
from scripts import generate_gradcam as gradcam_script
from scripts import summarize_sweeps as summarize_script
from src.data.emnist import CHAR_TO_INDEX
from src.models.cnn import AlphanumericCNN
from src.utils.metrics import AMBIGUOUS_CASE_PAIRS


def _make_dummy_emnist_like_dataset(num_per_class: int = 1):
    rng = np.random.default_rng(123)
    items = []
    for label in range(62):
        for _ in range(num_per_class):
            arr = rng.integers(0, 255, size=(28, 28), dtype=np.uint8)
            items.append((Image.fromarray(arr, mode="L"), label))
    return items


def test_gradcam_end_to_end_on_synthetic_model(tmp_path: Path) -> None:
    model_a = AlphanumericCNN(num_classes=62).eval()
    model_b = AlphanumericCNN(num_classes=62).eval()
    gradcam_script.disable_inplace_relu(model_a)
    gradcam_script.disable_inplace_relu(model_b)

    x = torch.randn(1, 1, 32, 32)
    cam, pred_idx, conf = gradcam_script.compute_gradcam(model_a, x, model_a.features[8])
    assert cam.shape == (32, 32)
    assert cam.dtype == np.float32
    assert 0.0 <= float(cam.min()) <= float(cam.max()) <= 1.0
    assert 0 <= pred_idx < 62
    assert 0.0 <= conf <= 1.0

    raw_ds = _make_dummy_emnist_like_dataset(num_per_class=1)
    sample_indices = {c: CHAR_TO_INDEX[c] for c in ["A", "8", "B", "0"]}
    out_png = tmp_path / "gradcam.png"
    gradcam_script.generate_gradcam_figure(
        raw_dataset=raw_ds,
        model_a=model_a,
        model_b=model_b,
        sample_indices=sample_indices,
        layer_idx=8,
        eval_seed=123,
        device=torch.device("cpu"),
        output_path=out_png,
    )
    assert out_png.is_file()
    assert out_png.stat().st_size > 1000


def test_onnx_fp32_export_and_static_int8_quantization(tmp_path: Path) -> None:
    model = AlphanumericCNN(num_classes=62).eval()
    fp32_path = edge_script.export_onnx_fp32(model, tmp_path / "model_fp32.onnx")
    assert fp32_path.is_file()

    calib_x = torch.randn(16, 1, 32, 32, dtype=torch.float32)
    calib_y = torch.arange(16, dtype=torch.long) % 62
    calib_loader = DataLoader(TensorDataset(calib_x, calib_y), batch_size=8, shuffle=False)

    int8_path = edge_script.quantize_onnx_static_int8(
        fp32_path, tmp_path / "model_int8.onnx", calib_loader=calib_loader
    )
    assert int8_path.is_file()
    assert int8_path.stat().st_size < fp32_path.stat().st_size

    fp32_sess = edge_script.create_ort_session(fp32_path, threads=1)
    int8_sess = edge_script.create_ort_session(int8_path, threads=1)

    lat_fp32 = edge_script.benchmark_onnx_cpu(fp32_sess, batch_size=1, warmup=2, iterations=5)
    lat_int8 = edge_script.benchmark_onnx_cpu(int8_sess, batch_size=1, warmup=2, iterations=5)
    assert lat_fp32 > 0.0
    assert lat_int8 > 0.0

    eval_loader = DataLoader(TensorDataset(calib_x, calib_y), batch_size=8, shuffle=False)
    m_fp32 = edge_script.evaluate_onnx_session(fp32_sess, eval_loader)
    m_int8 = edge_script.evaluate_onnx_session(int8_sess, eval_loader)
    assert 0.0 <= m_fp32["accuracy"] <= 1.0
    assert 0.0 <= m_int8["accuracy"] <= 1.0


def test_error_stratification_and_homoglyph_breakdown() -> None:
    y_true = np.array(
        [
            CHAR_TO_INDEX["C"],
            CHAR_TO_INDEX["c"],
            CHAR_TO_INDEX["0"],
            CHAR_TO_INDEX["O"],
            CHAR_TO_INDEX["A"],
        ]
    )
    pred_a = np.array(
        [
            CHAR_TO_INDEX["c"],  # A fail (case swap), B pass
            CHAR_TO_INDEX["C"],  # A fail (case swap), B pass
            CHAR_TO_INDEX["O"],  # both fail (0->O)
            CHAR_TO_INDEX["O"],  # A pass, B fail
            CHAR_TO_INDEX["A"],  # both pass
        ]
    )
    pred_b = np.array(
        [
            CHAR_TO_INDEX["C"],
            CHAR_TO_INDEX["c"],
            CHAR_TO_INDEX["o"],
            CHAR_TO_INDEX["0"],
            CHAR_TO_INDEX["A"],
        ]
    )

    quadrants, counts = error_script.stratify_quadrants(y_true, pred_a, pred_b)
    assert counts == {"a_fail_b_pass": 2, "a_pass_b_fail": 1, "both_fail": 1, "both_pass": 1}
    assert list(quadrants) == ["a_fail_b_pass", "a_fail_b_pass", "both_fail", "a_pass_b_fail", "both_pass"]

    breakdown = error_script.compute_homoglyph_breakdown(y_true, pred_a, pred_b)
    case_map = {item["pair"]: item for item in breakdown["ambiguous_case_pairs"]}
    assert case_map["C/c"]["model_a_case_swap_pct"] == 100.0
    assert case_map["C/c"]["model_b_case_swap_pct"] == 0.0

    group_map = {item["key"]: item for item in breakdown["digit_letter_groups"]}
    assert group_map["0_O_o"]["total_samples"] == 2
    assert group_map["0_O_o"]["model_a_in_group_confusion_pct"] == 50.0
    assert group_map["0_O_o"]["model_b_in_group_confusion_pct"] == 100.0
    assert len(AMBIGUOUS_CASE_PAIRS) == 15


def test_summarize_sweeps_multi_seed_and_ablation_uses_explicit_seeds(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    runs_dir = tmp_path / "runs"
    sweeps_dir = tmp_path / "sweeps"
    monkeypatch.setattr(summarize_script, "RUNS_DIR", runs_dir)
    monkeypatch.setattr(summarize_script, "SWEEPS_DIR", sweeps_dir)

    all_runs = [
        "EXP-001_baseline_seed123",
        "EXP-001_baseline_seed456",
        "EXP-001_baseline_seed789",
        "EXP-002_robust_seed123",
        "EXP-002_robust_seed456",
        "EXP-002_robust_seed789",
        "EXP-003_ablation_blur_seed123",
        "EXP-004_ablation_noise_seed123",
        "EXP-005_ablation_perspective_seed123",
    ]
    severities = {
        "blur": [0.0, 1.0, 2.0, 3.0],
        "noise": [0.0, 0.15, 0.20],
        "perspective": [0.0, 0.15, 0.25],
    }

    for run in all_runs:
        run_path = runs_dir / run
        run_path.mkdir(parents=True, exist_ok=True)
        with open(run_path / "test_results.json", "w", encoding="utf-8") as f:
            json.dump({"accuracy": 0.85, "macro_f1": 0.75, "case_insensitive_accuracy": 0.90}, f)

        sweep_run_dir = sweeps_dir / "by_run" / run
        sweep_run_dir.mkdir(parents=True, exist_ok=True)
        for deg, levels in severities.items():
            with open(sweep_run_dir / f"{deg}.csv", "w", newline="", encoding="utf-8") as f:
                writer = csv.writer(f)
                writer.writerow(["severity", "accuracy", "case_insensitive_accuracy", "macro_f1"])
                base_acc = 85.0 if "robust" in run else 50.0
                for sev in levels:
                    writer.writerow([f"{sev:.2f}", f"{base_acc:.2f}", "88.00", "70.00"])

    multi = summarize_script.summarize_multi_seed([123, 456, 789])
    assert multi["seeds"] == [123, 456, 789]
    assert multi["clean"]["model_a"]["accuracy"]["mean"] == 85.0
    assert multi["sweeps"]["blur"][0]["delta_mean_pp"] == 35.0

    ablation = summarize_script.summarize_ablation()
    assert set(ablation["models"].keys()) == set(summarize_script.ABLATION_MODELS.keys())
    assert ablation["models"]["EXP-003_ablation_blur_seed123"]["degradations"]["blur"]["points"]["2.0"] == 50.0


def test_compounded_stress_and_motion_blur_ood_pipelines(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    dummy_ds = _make_dummy_emnist_like_dataset(num_per_class=1)
    model_a = AlphanumericCNN(num_classes=62).eval()
    model_b = AlphanumericCNN(num_classes=62).eval()

    monkeypatch.setattr(
        compound_script,
        "load_eval_model",
        lambda run_name, device: model_a if "baseline" in run_name else model_b,
    )
    compound_report = compound_script.evaluate_compounded_runs(
        run_names=["EXP-001_baseline_seed123", "EXP-002_robust_seed123"],
        raw_test=dummy_ds,
        device=torch.device("cpu"),
        eval_seed=123,
        batch_size=32,
        max_samples=16,
    )
    assert compound_report["num_samples"] == 16
    assert set(compound_report["runs"]["EXP-001_baseline_seed123"].keys()) == {
        "clean",
        "tier_1_mild",
        "tier_2_moderate",
        "tier_3_harsh",
    }
    assert "accuracy_diff_pp" in compound_report["comparison"]

    monkeypatch.setattr(motion_script, "SWEEPS_DIR", tmp_path / "sweeps")
    monkeypatch.setattr(
        motion_script,
        "load_eval_model",
        lambda run_name, device: model_a if "baseline" in run_name else model_b,
    )
    motion_report = motion_script.evaluate_motion_blur_runs(
        run_names=["EXP-001_baseline_seed123", "EXP-002_robust_seed123"],
        raw_test=dummy_ds,
        device=torch.device("cpu"),
        eval_seed=123,
        batch_size=32,
        max_samples=16,
    )
    raw_series = motion_report.pop("raw_series")
    curve_png = tmp_path / "motion_blur_curve.png"
    motion_script.plot_motion_blur_curves(raw_series, curve_png)
    assert curve_png.is_file()
    assert (tmp_path / "sweeps" / "by_run" / "EXP-001_baseline_seed123" / "motion_blur.csv").is_file()
    assert len(motion_report["runs"]["EXP-001_baseline_seed123"]) == 6

