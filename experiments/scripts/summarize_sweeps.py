import argparse
import csv
import json
from pathlib import Path
import sys
from typing import Any, Dict, List
import numpy as np

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(PROJECT_ROOT))

from src.config import RUNS_DIR, SWEEPS_DIR, TABLES_DIR

SEEDS = [123, 456, 789]
DEGRADATIONS = ["blur", "noise", "perspective"]

ABLATION_MODELS = {
    "EXP-001_baseline_seed123": "Clean Baseline (A)",
    "EXP-003_ablation_blur_seed123": "Blur Only",
    "EXP-004_ablation_noise_seed123": "Noise Only",
    "EXP-005_ablation_perspective_seed123": "Perspective Only",
    "EXP-002_robust_seed123": "All Combined (B)",
}


def read_test_json(run_name: str) -> Dict[str, float]:
    path = RUNS_DIR / run_name / "test_results.json"
    if not path.is_file():
        raise FileNotFoundError(f"Missing test_results.json for {run_name}: {path}")
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def read_sweep_csv(run_name: str, deg_type: str) -> List[Dict[str, float]]:
    path = SWEEPS_DIR / "by_run" / run_name / f"{deg_type}.csv"
    if not path.is_file():
        raise FileNotFoundError(f"Missing per-run sweep CSV for {run_name}/{deg_type}: {path}")
    rows = []
    with open(path, "r", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            rows.append({k: float(v) for k, v in row.items()})
    return rows


def mean_std(values: List[float]) -> Dict[str, float]:
    arr = np.asarray(values, dtype=np.float64)
    return {
        "mean": round(float(arr.mean()), 2),
        "std": round(float(arr.std(ddof=1)) if len(arr) > 1 else 0.0, 2),
    }


def summarize_multi_seed(seeds: List[int]) -> Dict[str, Any]:
    summary: Dict[str, Any] = {"seeds": seeds, "clean": {}, "sweeps": {}}
    groups = {
        "model_a": [f"EXP-001_baseline_seed{s}" for s in seeds],
        "model_b": [f"EXP-002_robust_seed{s}" for s in seeds],
    }

    for group_key, run_names in groups.items():
        clean_runs = [read_test_json(r) for r in run_names]
        summary["clean"][group_key] = {
            "accuracy": mean_std([r["accuracy"] * 100.0 for r in clean_runs]),
            "macro_f1": mean_std([r["macro_f1"] * 100.0 for r in clean_runs]),
            "case_insensitive_accuracy": mean_std([r["case_insensitive_accuracy"] * 100.0 for r in clean_runs]),
        }

    for deg in DEGRADATIONS:
        a_rows_by_seed = [read_sweep_csv(r, deg) for r in groups["model_a"]]
        b_rows_by_seed = [read_sweep_csv(r, deg) for r in groups["model_b"]]
        severities = [row["severity"] for row in a_rows_by_seed[0]]
        levels_out = []
        for idx, sev in enumerate(severities):
            a_acc = [seed_rows[idx]["accuracy"] for seed_rows in a_rows_by_seed]
            b_acc = [seed_rows[idx]["accuracy"] for seed_rows in b_rows_by_seed]
            a_stats = mean_std(a_acc)
            b_stats = mean_std(b_acc)
            levels_out.append({
                "severity": sev,
                "model_a_acc_mean": a_stats["mean"],
                "model_a_acc_std": a_stats["std"],
                "model_b_acc_mean": b_stats["mean"],
                "model_b_acc_std": b_stats["std"],
                "delta_mean_pp": round(float(np.mean(np.asarray(b_acc) - np.asarray(a_acc))), 2),
            })
        summary["sweeps"][deg] = levels_out

    return summary


def summarize_ablation() -> Dict[str, Any]:
    matrix: Dict[str, Any] = {"models": {}}
    key_points = {
        "blur": [1.0, 2.0, 3.0],
        "noise": [0.15, 0.20],
        "perspective": [0.15, 0.25],
    }

    for run_name, label in ABLATION_MODELS.items():
        clean = read_test_json(run_name)
        entry: Dict[str, Any] = {
            "label": label,
            "clean_accuracy": round(clean["accuracy"] * 100.0, 2),
            "clean_macro_f1": round(clean["macro_f1"] * 100.0, 2),
            "clean_case_insensitive": round(clean["case_insensitive_accuracy"] * 100.0, 2),
            "degradations": {},
        }
        for deg in DEGRADATIONS:
            rows = read_sweep_csv(run_name, deg)
            by_sev = {round(r["severity"], 2): r["accuracy"] for r in rows}
            entry["degradations"][deg] = {
                "mean_accuracy": round(float(np.mean([r["accuracy"] for r in rows])), 2),
                "points": {str(sev): round(by_sev[sev], 2) for sev in key_points[deg] if sev in by_sev},
            }
        matrix["models"][run_name] = entry

    return matrix


def main() -> None:
    parser = argparse.ArgumentParser(description="EXP-006: Aggregate multi-seed and ablation sweeps.")
    parser.add_argument("--mode", choices=["all", "multi-seed", "ablation"], default="all")
    parser.add_argument("--seeds", nargs="+", type=int, default=SEEDS)
    args = parser.parse_args()

    TABLES_DIR.mkdir(parents=True, exist_ok=True)
    if args.mode in ("all", "multi-seed"):
        out_path = TABLES_DIR / "multi_seed_summary.json"
        data = summarize_multi_seed(args.seeds)
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        print(f"Saved: {out_path}")

    if args.mode in ("all", "ablation"):
        out_path = TABLES_DIR / "ablation_cross_matrix.json"
        data = summarize_ablation()
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        print(f"Saved: {out_path}")


if __name__ == "__main__":
    main()
