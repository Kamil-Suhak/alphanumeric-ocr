# Developer & Author Workflow Guide

This guide describes the day-to-day workflow for writing your engineering thesis, running machine learning experiments, and preparing milestone reports for your thesis supervisor.

---

## 1. Quickstart & Tooling

### Installed Software
- **Typst CLI:** `0.15.1` (installed via Winget)
- **VS Code Extension:** `Tinymist Typst` (`myriad-dreamin.tinymist`)
- **Python Package Manager:** `uv` `0.13.6` (installed via Winget)

### VS Code Live Preview
1. Open the repository root in VS Code.
2. Open `document/main.typ` (or any chapter file).
3. Press `Ctrl + K`, then `V` (or click the Tinymist preview icon in the editor toolbar).
4. As you type, the PDF preview updates instantaneously in sub-100 milliseconds without disk thrashing.

---

## 2. Thesis Writing & Typst Conventions

### Chapter Structure
All thesis chapters live in `document/chapters/`:
- `01_wstep.typ`: Introduction, motivation, and research hypotheses.
- `02_teoria_i_literatura.typ`: Theoretical background, OCR evolution, CNNs, and degradation models.
- `03_cel_i_zakres.typ`: 62-class problem specification, ambiguity pairs, and dataset partitioning.
- `04_metodyka_i_architektura.typ`: AlphanumericCNN architecture and synthetic degradation pipeline.
- `05_wyniki_eksperymentow.typ`: Dynamic comparison tables and empirical robustness curves.
- `06_wnioski_i_rozwoj.typ`: Conclusions, verified hypotheses, limitations, and future directions.

### Managing References (Hayagriva YAML)
BibTeX is no longer used. Add references directly to `document/references/library.yaml`:

```yaml
author2025paper:
  type: conference
  title: "Title of the Publication"
  author:
    - Surname, Firstname
  date: 2025
  parent:
    title: "Proceedings of Conference"
  serial-number:
    doi: 10.1234/example.doi
```

To cite in your Typst text, simply write:
```typst
Jak wykazano w badaniach @author2025paper, augmentacja...
```

### Dynamic Results Binding (Zero Hardcoded Numbers)
Never manually transcribe numbers from Python into the text. In `document/chapters/05_wyniki_eksperymentow.typ`:
```typst
#let results = json("../../experiments/outputs/tables/accuracy_summary.json")

Dokładność modelu bazowego wyniosła #results.clean_baseline.accuracy%,
podczas gdy model odporny osiągnął #results.robust_cnn.accuracy%.
```

---

## 3. Machine Learning Experiments Workflow

### Managing Dependencies with `uv`
The project uses `pyproject.toml` managed by `uv`:
```bash
# Sync environment
uv sync

# Add a new package
uv add albumentations
```

### Running Experiments
Always execute scripts through `uv run`:
```bash
# Train clean baseline (EXP-001)
uv run python experiments/scripts/train_baseline.py

# Train robust model (EXP-002)
uv run python experiments/scripts/train_robust.py

# Run comparative robustness sweeps (blur, noise, perspective)
uv run python experiments/scripts/evaluate.py

# Benchmark latency and parameters
uv run python experiments/scripts/benchmark_practicality.py
```

### Experiment Output Routing
Output files are organized strictly by purpose:
- `experiments/outputs/runs/EXP-001_baseline/`: Checkpoint `best.pt`, training curves, confusion matrix.
- `experiments/outputs/runs/EXP-002_robust/`: Checkpoint `best.pt`, training curves, confusion matrix.
- `experiments/outputs/sweeps/`: Subfolders for `blur/`, `noise/`, `perspective/` containing CSVs and PNGs.
- `experiments/outputs/tables/`: Aggregated summary files (`accuracy_summary.json`, `practicality.json`).

---

## 4. Supervisor Milestone Reports

When preparing progress reports for your thesis supervisor:
1. Navigate to `milestones/milestone<n>/` (e.g. `milestones/milestone1/` or `milestones/milestone2/`).
2. Edit `main.typ`. It is a compact, independent Typst project pre-configured for executive reporting.
3. Compile to PDF:
   ```bash
   typst compile --root . milestones/milestone1/main.typ milestones/milestone1/raport_etap1.pdf
   ```
4. All original Word docs and submitted PDFs are safely preserved in `milestones/milestone1/source_docs/`.

---

## 5. Exporting the Final Submission PDF

To generate the complete, publication-ready thesis PDF:
```bash
typst compile --root . document/main.typ "Praca_Inzynierska_Kamil_Suhak.pdf"
```
Marginesy (3.0 cm oprawa / 2.0 cm zewn.), interlinia (1.25 dla WEAIiIB), strona tytułowa AGH i spisy treści/rysunków/tabel generują się w pełni automatycznie.
