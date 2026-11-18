# Alphanumeric OCR — CNN Robustness Study (AGH Engineering Thesis)

**Author:** Kamil Sebastian Suhak | **Supervisor:** dr hab. inż. Adam Głowacz  
**Field:** Technologie Przemysłu 4.0 (WEAIiIB, AGH University of Krakow)

---

## Overview
Monorepo for the engineering thesis *„Rozpoznawanie znaków alfanumerycznych w trudnych warunkach środowiskowych z zastosowaniem konwolucyjnych sieci neuronowych”*:
- **`document/`** — Typst thesis source (`document/main.typ`) + Hayagriva YAML bibliography.
- **`experiments/`** — Python 3.14 / PyTorch research pipeline (`AlphanumericCNN`, EMNIST ByClass, synthetic degradations, ONNX INT8 quantization, Grad-CAM, OOD & error diagnostics).
- **`milestones/`** — Supervisor progress reports (`milestone1/`, `milestone2/`).

> **Documentation & Specs:** All project documentation, agent invariants, experiment specifications (`EXP-000`–`EXP-010`), and project state live in the Obsidian vault at `~/notes/wiki/University/Thesis/`.

---

## Quickstart

```bash
# 1. Restore Python 3.14 environment & run tests
uv sync
uv run pytest -v

# 2. Download EMNIST ByClass (into git-ignored data/raw/emnist/)
uv run python experiments/scripts/download_emnist_byclass.py

# 3. Compile thesis PDF
typst compile --root . document/main.typ "Praca_Inzynierska_Kamil_Suhak.pdf"
```
