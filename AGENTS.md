# AI Agent Protocol & Operational Invariants

This document establishes the binding architectural constraints, operational invariants, and file conventions for all AI assistants (e.g. Antigravity, Claude, Copilot) operating within this repository.

---

## 1. Non-Negotiable Invariants

1. **Safety & Git Operations:**
   - **Never push changes to any remote repository** without explicit user instruction.
   - Use Conventional Commits **without scope parentheses**: `<type>: <description>` (e.g., `feat: add noise sweep`, `chore: update yaml bibliography`). Allowed types: `docs`, `refactor`, `chore`, `test`, `feat`, `fix`, `visual`.
   - Never overwrite or delete trained model checkpoints (`*.pt`, `best.pt`) or raw benchmark outputs.

2. **Empirical Integrity & Dynamic Binding:**
   - **Zero Hardcoding in Thesis Text:** When authoring or revising Typst chapters, never hardcode or fabricate empirical metrics (accuracy, F1, latency, parameter counts). All values must be imported dynamically from `experiments/outputs/tables/*.json` or `*.csv` (e.g. `#let results = json(...)`).
   - **Floating Point Precision & Metric Formatting:**
     - **NEVER output raw unrounded IEEE 754 arithmetic in document text or tables** (e.g. `#(val_b - val_a)`). Raw subtractions result in precision artifacts such as `-0.1600000000000108 p.p.` or `+73.96000000000001 p.p.`.
     - Always use dedicated rounding and formatting helpers: `fmt_diff(val)` and `fmt_val(val)` (from `template/agh_thesis.typ`) or `calc.round(val, digits: 2)`.
     - Ensure explicit sign indicators (`+` / `-`) for differences and use the Polish decimal comma (`,`) consistently.
   - **Seed Agnosticism Invariant:** Do not assume a single fixed seed (e.g. 123) is sufficient for scientific conclusions. Experiments must support parameterized seeds across runs to demonstrate statistical robustness and seed-agnosticism.

3. **Heading Hierarchy & Numbering Discipline:**
   - **No Duplicate Section Numbering:** When `#set heading(numbering: ...)` is active in Typst, **NEVER include manual numbers in heading strings**. For example, write `= Podsumowanie wyników empirycznych`, **NEVER** `= 2. Podsumowanie wyników empirycznych`.
   - **Correct Heading Level for Standalone Reports:** In standalone milestone reports (`milestones/milestone<n>/main.typ`), use top-level headings (`=`) for primary sections so Typst does not prepend a zero chapter counter (which causes `0.2. 2.`).

4. **Data Isolation & Split Integrity:**
   - The official EMNIST test split (**116,323 samples**) is strictly isolated and frozen. Under no circumstances may test samples be used for fitting normalization, hyperparameter tuning, or degradation parameter selection.
   - Training and validation splits are permanently locked in `experiments/manifests/train_indices.csv` and `val_indices.csv`.

5. **Experiment Output Organization & Diligent Naming:**
   - Every experiment run must be placed in a dedicated, numbered, or semantically named folder under `experiments/outputs/runs/` (e.g., `EXP-001_baseline/`, `EXP-002_robust/`).
   - Never save loose figures directly to `experiments/outputs/`. Route figures to their specific subdirectories:
     - `experiments/outputs/runs/<RUN_ID>/` for run-specific curves and confusion matrices.
     - `experiments/outputs/sweeps/<degradation>/` for comparative sweep curves and CSV data.
     - `experiments/outputs/diagnostics/` for inspection grids and orientation checks.
     - `experiments/outputs/tables/` for aggregated JSON/CSV summary tables.

6. **Document & Citation Standards:**
   - **Typst Only:** LaTeX is deprecated. Do not introduce TeX files, `.aux`, `.bcf`, or BibTeX `.bib` files.
   - **Hayagriva YAML Bibliography:** All references must be stored in `document/references/library.yaml` using strict Hayagriva YAML schema (`type: article`, `type: conference`, `author: [...]`, `date: ...`).
   - **Supervisor Milestones:** Independent progress reports submitted to the supervisor reside in `milestones/milestone<n>/` as standalone Typst workspaces.

---

## 2. Repository Layout & Role Mapping

```text
alphanumeric_ocr/
├── document/             # Main thesis document (Typst)
│   ├── main.typ          # Root entrypoint
│   ├── metadata.typ      # Title, author, supervisor, faculty settings
│   ├── template/         # AGH layout & formatting specifications (agh_thesis.typ)
│   ├── chapters/         # Modular chapter files (01_wstep.typ ... 06_wnioski.typ)
│   └── references/       # Hayagriva YAML bibliography (library.yaml)
│
├── experiments/          # Python research engine
│   ├── configs/          # YAML experiment configurations (baseline, robust)
│   ├── manifests/        # Persistent dataset split manifests (train/val indices)
│   ├── src/              # Core library (models, transforms, training, evaluation)
│   ├── scripts/          # CLI driver scripts
│   └── outputs/          # Strictly organized and numbered experiment artifacts
│       ├── runs/         # Per-experiment directories (EXP-001_baseline, EXP-002_robust)
│       ├── sweeps/       # Degradation sweeps (blur, noise, perspective)
│       ├── diagnostics/  # Data checks and sample grids
│       └── tables/       # JSON and CSV tables consumed by Typst
│
├── milestones/           # Dedicated supervisor submission workspaces
│   ├── milestone1/       # Milestone 1 Typst report & original source documents
│   └── milestone2/       # Milestone 2 workspace (upcoming phases)
│
└── data/                 # Raw datasets (excluded from Git)
    └── raw/emnist/       # EMNIST ByClass binary idx files
```

---

## 3. Toolchain & Execution Commands

- **Python Management:** Always use `uv` for python dependencies and script execution:
  - Add dependency: `uv add <package>`
  - Run script: `uv run python experiments/scripts/<script>.py`
- **Typst Compilation:**
  - Compile thesis: `typst compile --root . document/main.typ document/main.pdf`
  - Compile milestone: `typst compile --root . milestones/milestone1/main.typ milestones/milestone1/milestone1_report.pdf`
  - Code/markup formatting: `typstyle -i document/**/*.typ`
