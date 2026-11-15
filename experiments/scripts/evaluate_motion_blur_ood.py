import argparse
import json
from pathlib import Path
import sys
from typing import Any, Dict, List, Optional
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import torch
from torch.utils.data import Subset
from torchvision.datasets import EMNIST

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(PROJECT_ROOT))

from src.config import RAW_EMNIST_DIR, SWEEPS_DIR, TABLES_DIR
from src.data.transforms import MOTION_BLUR_KERNEL_SIZES
from src.experiments.degradation_sweep import run_single_sweep, save_single_run_sweep_csv
from src.training.runner import load_eval_model


def plot_motion_blur_curves(
    results_by_run: Dict[str, List[Dict[str, float]]],
    save_path: Path,
) -> None:
    """Wykres porównawczy odporności OOD na poziome rozmycie ruchowe."""
    plt.figure(figsize=(8, 5))
    colors = ["#d62728", "#2ca02c", "#1f77b4", "#ff7f0e", "#9467bd"]
    markers = ["o", "s", "^", "D", "v"]

    for idx, (run_name, rows) in enumerate(results_by_run.items()):
        kernels = [r["severity"] for r in rows]
        accs = [r["accuracy"] * 100.0 for r in rows]
        plt.plot(
            kernels,
            accs,
            marker=markers[idx % len(markers)],
            color=colors[idx % len(colors)],
            lw=2,
            label=run_name,
        )

    plt.axhline(50.0, color="gray", linestyle=":", label="Próg 50%")
    plt.xticks([1] + MOTION_BLUR_KERNEL_SIZES, ["Clean"] + [str(k) for k in MOTION_BLUR_KERNEL_SIZES])
    plt.xlabel("Długość jądra rozmycia ruchowego k (px, kąt 0°)")
    plt.ylabel("Dokładność Top-1 (%)")
    plt.title("Generalizacja OOD: Poziome rozmycie ruchowe")
    plt.ylim(0, 100)
    plt.grid(True, linestyle=":", alpha=0.6)
    plt.legend()
    plt.tight_layout()

    save_path.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(save_path, dpi=200)
    plt.close()


def evaluate_motion_blur_runs(
    run_names: List[str],
    raw_test: EMNIST,
    device: torch.device,
    eval_seed: int = 123,
    batch_size: int = 512,
    max_samples: Optional[int] = None,
) -> Dict[str, Any]:
    """Ewaluacja OOD na poziomym rozmyciu ruchowym (k=3..11) z czystym punktem odniesienia."""
    dataset = raw_test if max_samples is None else Subset(raw_test, list(range(min(max_samples, len(raw_test)))))
    results_by_run: Dict[str, List[Dict[str, float]]] = {}

    for run_name in run_names:
        print(f"\n=== Ewaluacja OOD (Motion Blur): {run_name} ===")
        model = load_eval_model(run_name, device=device)

        clean_row = run_single_sweep(
            model, dataset, "clean", [1], device=device, batch_size=batch_size, eval_seed=eval_seed
        )
        motion_rows = run_single_sweep(
            model,
            dataset,
            "motion_blur",
            MOTION_BLUR_KERNEL_SIZES,
            device=device,
            batch_size=batch_size,
            eval_seed=eval_seed,
        )
        combined_rows = clean_row + motion_rows
        results_by_run[run_name] = combined_rows
        save_single_run_sweep_csv(combined_rows, SWEEPS_DIR / "by_run" / run_name / "motion_blur.csv")

    return {
        "eval_seed": eval_seed,
        "num_samples": len(dataset),
        "angle_deg": 0.0,
        "kernel_sizes": MOTION_BLUR_KERNEL_SIZES,
        "runs": {
            run_name: [
                {
                    "kernel_size": int(r["severity"]),
                    "accuracy_pct": round(r["accuracy"] * 100.0, 2),
                    "macro_f1_pct": round(r["macro_f1"] * 100.0, 2),
                    "case_insensitive_acc_pct": round(r["case_insensitive_accuracy"] * 100.0, 2),
                }
                for r in rows
            ]
            for run_name, rows in results_by_run.items()
        },
        "raw_series": results_by_run,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="EXP-009: Horizontal motion blur out-of-distribution benchmark.")
    parser.add_argument(
        "--runs",
        nargs="+",
        default=["EXP-001_baseline_seed123", "EXP-002_robust_seed123", "EXP-003_ablation_blur_seed123"],
    )
    parser.add_argument("--eval-seed", type=int, default=123)
    parser.add_argument("--batch-size", type=int, default=512)
    parser.add_argument("--max-samples", type=int, default=None)
    parser.add_argument("--output", type=Path, default=TABLES_DIR / "motion_blur_ood.json")
    parser.add_argument("--plot-output", type=Path, default=SWEEPS_DIR / "motion_blur" / "motion_blur_curve.png")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    raw_test = EMNIST(root=str(RAW_EMNIST_DIR), split="byclass", train=False, download=False, transform=None)

    report = evaluate_motion_blur_runs(
        run_names=args.runs,
        raw_test=raw_test,
        device=device,
        eval_seed=args.eval_seed,
        batch_size=args.batch_size,
        max_samples=args.max_samples,
    )
    raw_series = report.pop("raw_series")
    plot_motion_blur_curves(raw_series, args.plot_output)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
    print(f"\nZapisano wyniki OOD Motion Blur do: {args.output}")
    print(f"Zapisano wykres krzywej OOD do: {args.plot_output}")


if __name__ == "__main__":
    main()
