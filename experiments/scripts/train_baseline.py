from pathlib import Path
import sys

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(PROJECT_ROOT))

from src.training.runner import run_train_cli


if __name__ == "__main__":
    run_train_cli(
        default_config=PROJECT_ROOT / "configs" / "baseline.yaml",
        description="Train clean baseline CNN (EXP-001).",
    )
