from pathlib import Path

# Ścieżki w ramach monorepozytorium
EXPERIMENTS_ROOT = Path(__file__).resolve().parent.parent
REPO_ROOT = EXPERIMENTS_ROOT.parent

# Zbiory danych (przechowywane centralnie w katalogu repozytorium)
DATA_DIR = REPO_ROOT / "data"
RAW_EMNIST_DIR = DATA_DIR / "raw" / "emnist"
PROCESSED_DIR = DATA_DIR / "processed"
MANIFESTS_DIR = EXPERIMENTS_ROOT / "manifests"

# Wyjścia eksperymentów (zorganizowane semantycznie i numerowane)
OUTPUTS_DIR = EXPERIMENTS_ROOT / "outputs"
RUNS_DIR = OUTPUTS_DIR / "runs"
SWEEPS_DIR = OUTPUTS_DIR / "sweeps"
DIAGNOSTICS_DIR = OUTPUTS_DIR / "diagnostics"
TABLES_DIR = OUTPUTS_DIR / "tables"

# Kompatybilność wsteczna z historycznymi skryptami
PROJECT_ROOT = EXPERIMENTS_ROOT
RESULTS_DIR = OUTPUTS_DIR
FIGURES_DIR = DIAGNOSTICS_DIR

# Parametry normalizacji wyznaczone eksperymentalnie na 90% zbioru treningowego ByClass po dopełnieniu zerami (scripts/compute_normalization.py)
EMNIST_MEAN = 0.1331
EMNIST_STD = 0.2870
