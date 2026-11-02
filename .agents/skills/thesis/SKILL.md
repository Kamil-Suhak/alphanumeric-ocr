---
name: thesis
description: Expert authoring, drafting, reviewing, and style guide for the engineering thesis in Typst. Enforces academic Polish tone, prevents LLM prose pathologies, ensures proper typographical cadence, and provides verified recipes for Typst tables, figures, math, and data binding.
---

# Engineering Thesis Craft & Review Guide (`thesis`)

This skill establishes the operational and stylistic standards for authoring, editing, and reviewing chapters, tables, formulas, and figures in Typst for this engineering thesis (*Badanie odporności kompaktowej sieci CNN na degradacje środowiskowe w zadaniu klasyfikacji znaków alfanumerycznych*).

---

## 1. Quick Reference & Auxiliary Files

To minimize context token usage, detailed reference material is partitioned into dedicated documents:

| Reference Document | Purpose & When to Inspect |
| :--- | :--- |
| [`references/prose_examples.md`](./references/prose_examples.md) | **Style & Cadence Ground Truth:** Contains real **Good** and **Bad** prose benchmarks. Read when drafting paragraphs or evaluating prose tone. |
| [`references/typst_recipes.md`](./references/typst_recipes.md) | **Technical Code Recipes:** Exact syntax for dynamic tables (`fmt_diff`), semantic figures, math formulas, and Hayagriva YAML citations. |

---

## 2. The Seven Golden Rules of Academic Prose

When generating Polish academic text, strictly adhere to these rules:

1. **Eliminate Overdramatic & Absolute Claims:**
   - **Banned vocabulary:** *"bezsprzecznie"*, *"uniwersalne panaceum"*, *"perfekcyjna generalizacja"*, *"zerowe opóźnienie"*, *"drastycznie"*, *"matematycznie niemożliwe"* (chyba że towarzyszy temu formalny dowód twierdzenia).
   - **Required stance:** State measured, empirical facts bounded by test conditions (*"wyniki sugerują"*, *"zaobserwowano istotny wzrost o 15,5 p.p."*, *"w warunkach badanego zbioru testowego"*).
2. **Cognitive Cadence & Breathing Room:**
   - Never pile 4–5 dense technical specifications into a single breath.
   - Use natural transitions that give the reader mental space to absorb information: *"W tym kontekście warto zauważyć, że..."*, *"Z praktycznego punktu widzenia oznacza to..."*, *"Niemniej jednak..."*.
3. **Sentence Length Budget (Max 25–30 Words):**
   - Break multi-clause run-ons into 2 or 3 distinct sentences. Alternate between medium explanatory sentences and short, punchy 8-word summaries.
4. **Acronym Hygiene:**
   - Never stack parenthetical acronyms (e.g. avoid: *"rozpoznawanie tekstu (OCR) w widzeniu komputerowym (CV) przy użyciu sieci (CNN)"*).
   - Define an acronym once on first use with Polish/English gloss. Omit acronyms used only once or twice; write the full phrase instead.
5. **Academic Polish Register:**
   - Use consistent *pluralis auctoris* (*"wytrenowaliśmy"*, *"zaobserwowaliśmy"*) or formal passive (*"wytrenowano"*, *"w pracy zbadano"*). Never use first-person singular (*"ja"*).
6. **Twarde Spacje (Non-Breaking Spaces):**
   - Single-letter prepositions/conjunctions (`w`, `z`, `o`, `i`, `a`, `u`) must be bound to the next word with `~` in Typst (`w~niniejszej pracy`, `z~uwagi na`).
7. **Decimal Comma & Unit Spacing:**
   - Polish academic notation strictly uses decimal commas: `87,46%`, `1,08~ms`, `-0,16~p.p.`, `32~times~32~pikseli`.

---

## 3. Typst Technical Guardrails

- **Zero Hardcoding:** Load empirical numbers dynamically via `#let results = json(...)`. Use `#fmt_val()` and `#fmt_diff()` from `template/agh_thesis.typ` to guarantee clean 2-decimal rounding and explicit `+`/`-` signs.
- **Direct Output Paths:** Figures link directly to semantic paths in `experiments/outputs/` (e.g. `../../experiments/outputs/sweeps/blur/blur_curve.png`).
- **Heading Hygiene:** Never write manual numbers in heading strings (e.g. write `= Wstęp`, **never** `= 1. Wstęp`) when `#set heading(numbering: ...)` is active.
- **Hayagriva Citations:** Use `@citekey` referencing `document/references/library.yaml`. Zero LaTeX `\cite{}` macros.

---

## 4. The 4-Step Self-Review Protocol

Before delivering any drafted text or table to the user, autonomously execute this checklist:

1. **Compilation Check (Mandatory):**
   - Run: `typst compile --root . document/main.typ document/main.pdf`
   - Verify exit code 0 with **zero warnings** and zero layout overflows.
2. **Data & Precision Pass:**
   - Verify no raw IEEE 754 float glitches (e.g. `0.1600000000000108`).
   - Confirm all numbers match values in `accuracy_summary.json` or `practicality.json`.
3. **Heading Pass:**
   - Confirm no duplicate numbering (e.g. no `0.2. 2.`) in document and milestone headers.
4. **Cadence & Tone Pass:**
   - Read the text mentally: Does it sound like an objective, measured engineer presenting empirical data? Check against [`references/prose_examples.md`](./references/prose_examples.md) if in doubt.
