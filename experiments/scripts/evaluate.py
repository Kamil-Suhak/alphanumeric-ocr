import argparse
from pathlib import Path
import sys
import torch
from torchvision.datasets import EMNIST

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(PROJECT_ROOT))

from src.config import RAW_EMNIST_DIR, SWEEPS_DIR
from src.data.transforms import (
    BLUR_SEVERITY_LEVELS,
    NOISE_SEVERITY_LEVELS,
    PERSPECTIVE_SEVERITY_LEVELS,
)
from src.experiments.degradation_sweep import (
    plot_robustness_curve,
    run_single_sweep,
    save_single_run_sweep_csv,
    save_sweep_csv,
)
from src.training.runner import load_eval_model

SWEEP_DEFINITIONS = [
    ("blur", BLUR_SEVERITY_LEVELS, "Rozmycie gaussowskie ($\\sigma$)", "Odporność na rozmycie gaussowskie"),
    ("noise", NOISE_SEVERITY_LEVELS, "Szum gaussowski ($\\sigma$)", "Odporność na szum gaussowski"),
    (
        "perspective",
        PERSPECTIVE_SEVERITY_LEVELS,
        "Zniekształcenie perspektywiczne",
        "Odporność na zniekształcenia perspektywiczne",
    ),
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="EXP-006: Deterministic degradation sweep evaluator.")
    parser.add_argument(
        "--runs",
        nargs="+",
        default=None,
        help="List of run folder names under experiments/outputs/runs/ to evaluate.",
    )
    parser.add_argument(
        "--clean-run",
        type=str,
        default="EXP-001_baseline_seed123",
        help="Baseline run name for pairwise comparison plots.",
    )
    parser.add_argument(
        "--robust-run",
        type=str,
        default="EXP-002_robust_seed123",
        help="Robust run name for pairwise comparison plots.",
    )
    parser.add_argument("--eval-seed", type=int, default=123, help="Sample-indexed seed for test corruptions.")
    parser.add_argument("--batch-size", type=int, default=512)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Ewaluacja odporności modeli na urządzeniu: {device} (eval_seed={args.eval_seed})")

    raw_test = EMNIST(root=str(RAW_EMNIST_DIR), split="byclass", train=False, download=False, transform=None)
    print(f"Wczytano {len(raw_test):,} próbek zbioru testowego.")

    target_runs = args.runs if args.runs is not None else [args.clean_run, args.robust_run]
    all_results = {}

    for run_name in target_runs:
        print(f"\n=== Ewaluacja modelu: {run_name} ===")
        model = load_eval_model(run_name, device=device)
        all_results[run_name] = {}

        for deg_type, levels, _, _ in SWEEP_DEFINITIONS:
            print(f"--- Sweep: {deg_type} ---")
            res = run_single_sweep(
                model,
                raw_test,
                deg_type,
                levels,
                device=device,
                batch_size=args.batch_size,
                eval_seed=args.eval_seed,
            )
            all_results[run_name][deg_type] = res
            per_run_csv = SWEEPS_DIR / "by_run" / run_name / f"{deg_type}.csv"
            save_single_run_sweep_csv(res, per_run_csv)

    if args.runs is None:
        for deg_type, _, xlabel, title in SWEEP_DEFINITIONS:
            clean_res = all_results[args.clean_run][deg_type]
            robust_res = all_results[args.robust_run][deg_type]
            out_subdir = SWEEPS_DIR / deg_type
            save_sweep_csv(clean_res, robust_res, out_subdir / f"{deg_type}.csv")
            plot_robustness_curve(clean_res, robust_res, xlabel, title, out_subdir / f"{deg_type}_curve.png")

    print("\nTesty odporności zakończone pomyślnie.")


if __name__ == "__main__":
    main()
