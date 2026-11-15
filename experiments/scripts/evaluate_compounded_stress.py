import argparse
import json
from pathlib import Path
import sys
from typing import Any, Dict, List, Optional
import torch
from torch.utils.data import DataLoader, Subset
from torchvision.datasets import EMNIST

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(PROJECT_ROOT))

from src.config import RAW_EMNIST_DIR, TABLES_DIR
from src.data.transforms import COMPOUND_STRESS_TIERS
from src.experiments.degradation_sweep import ControlledDegradationDataset, build_degradation_fn
from src.training.evaluate import evaluate_model
from src.training.runner import load_eval_model


def evaluate_compounded_runs(
    run_names: List[str],
    raw_test: EMNIST,
    device: torch.device,
    eval_seed: int = 123,
    batch_size: int = 512,
    max_samples: Optional[int] = None,
) -> Dict[str, Any]:
    """Ewaluacja modeli na czystym zbiorze testowym i trzech poziomach degradacji złożonej."""
    dataset = raw_test if max_samples is None else Subset(raw_test, list(range(min(max_samples, len(raw_test)))))
    num_workers = 2 if torch.cuda.is_available() else 0
    pin_memory = torch.cuda.is_available()

    regimes: Dict[str, Optional[Dict[str, float]]] = {"clean": None, **COMPOUND_STRESS_TIERS}
    output: Dict[str, Any] = {
        "eval_seed": eval_seed,
        "num_samples": len(dataset),
        "tiers": COMPOUND_STRESS_TIERS,
        "runs": {},
    }

    for run_name in run_names:
        print(f"\n=== Ewaluacja stresu złożonego: {run_name} ===")
        model = load_eval_model(run_name, device=device)
        run_metrics: Dict[str, Dict[str, float]] = {}
        clean_acc: Optional[float] = None

        for regime_name, params in regimes.items():
            deg_fn = None if params is None else build_degradation_fn("compound", params)
            ds = ControlledDegradationDataset(dataset, degradation_fn=deg_fn, seed=eval_seed)
            loader = DataLoader(
                ds,
                batch_size=batch_size,
                shuffle=False,
                num_workers=num_workers,
                pin_memory=pin_memory,
            )
            metrics, _, _ = evaluate_model(model, loader, device=device)

            acc_pct = metrics["accuracy"] * 100.0
            if regime_name == "clean":
                clean_acc = acc_pct
            retention = (acc_pct / clean_acc * 100.0) if clean_acc and clean_acc > 0 else 0.0

            run_metrics[regime_name] = {
                "accuracy_pct": round(acc_pct, 2),
                "macro_f1_pct": round(metrics["macro_f1"] * 100.0, 2),
                "case_insensitive_acc_pct": round(metrics["case_insensitive_accuracy"] * 100.0, 2),
                "retention_pct": round(retention, 2),
            }
            print(
                f"  {regime_name:16s} | Acc={acc_pct:5.2f}% | "
                f"Macro-F1={metrics['macro_f1'] * 100:5.2f}% | Ret={retention:5.1f}%"
            )

        output["runs"][run_name] = run_metrics

    if len(run_names) >= 2:
        run_a, run_b = run_names[0], run_names[1]
        output["comparison"] = {
            "baseline_run": run_a,
            "robust_run": run_b,
            "accuracy_diff_pp": {
                tier: round(
                    output["runs"][run_b][tier]["accuracy_pct"] - output["runs"][run_a][tier]["accuracy_pct"],
                    2,
                )
                for tier in regimes
            },
        }
    return output


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="EXP-009: Compounded multi-degradation stress benchmark.")
    parser.add_argument(
        "--runs",
        nargs="+",
        default=["EXP-001_baseline_seed123", "EXP-002_robust_seed123"],
    )
    parser.add_argument("--eval-seed", type=int, default=123)
    parser.add_argument("--batch-size", type=int, default=512)
    parser.add_argument("--max-samples", type=int, default=None, help="Optional subset limit for fast validation.")
    parser.add_argument("--output", type=Path, default=TABLES_DIR / "compounded_stress.json")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    raw_test = EMNIST(root=str(RAW_EMNIST_DIR), split="byclass", train=False, download=False, transform=None)

    report = evaluate_compounded_runs(
        run_names=args.runs,
        raw_test=raw_test,
        device=device,
        eval_seed=args.eval_seed,
        batch_size=args.batch_size,
        max_samples=args.max_samples,
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
    print(f"\nZapisano wyniki testu złożonego do: {args.output}")


if __name__ == "__main__":
    main()
