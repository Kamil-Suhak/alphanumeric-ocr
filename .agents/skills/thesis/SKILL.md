---
name: thesis
description: Expert authoring, drafting, reviewing, and style guide for the engineering thesis in Typst. Enforces academic Polish tone, prevents LLM prose pathologies, ensures proper typographical cadence, and provides verified recipes for Typst tables, figures, math, and data binding.
---

# Engineering Thesis Craft & Review Guide (`thesis`)

This skill establishes the operational and stylistic standards for assisting the author in writing, editing, and reviewing chapters, tables, formulas, and figures in Typst for this engineering thesis (*Rozpoznawanie znaków alfanumerycznych w trudnych warunkach środowiskowych z zastosowaniem konwolucyjnych sieci neuronowych*).

---

## 1. Quick Reference & Auxiliary Files

| Reference Document | Purpose & When to Inspect |
| :--- | :--- |
| [`references/prose_examples.md`](./references/prose_examples.md) | **Style & Cadence Ground Truth:** Real **Good** and **Bad** Polish academic prose benchmarks. |
| [`references/typst_recipes.md`](./references/typst_recipes.md) | **Technical Code Recipes:** Syntax for dynamic tables (`fmt_diff`), semantic figures, math formulas, and Hayagriva YAML citations. |
| `/home/kamils/notes/wiki/University/Thesis/References/` | **Obsidian Companion Vault:** Stores chapter writing briefs and paper digests mapped to `@citekey`s in `document/references/library.yaml`. |

---

## 2. Author-Driven Sprint Workflow (`Brief -> Draft -> Reconstruction`)

The author writes the thesis content in focused sessions; the agent handles domain research, citation lookup, Typst data binding, and academic Polish reconstruction.

### Mode A — Obsidian Reference Brief (`brief <chapter/section>`)
Before the author drafts a chapter or section, the agent inspects the relevant Python code (`experiments/src/`, `experiments/scripts/`), JSON/CSV tables (`experiments/outputs/tables/`), and `document/references/library.yaml`, then writes or updates a Markdown brief in `/home/kamils/notes/wiki/University/Thesis/References/` (linked from `References.md`) instead of cluttering `.typ` files with long comments:
1. **Domain & Code TL;DR:** Plain-English explanation of the CNN/signal-processing concepts and exact repo implementation facts.
2. **Citation Digest:** Relevant `@citekey`s from `library.yaml`, summarizing what each paper actually says and which claim it supports (flagging if a new reference should be added).
3. **Polish Glossary & Snippets:** Key English-to-Polish technical terms plus ready-to-use `#let` JSON/CSV variable paths and math expressions.
4. **Paragraph Spine:** A 1-line-per-paragraph logical progression.

### Mode B — Fast "Ponglish" Rough Draft (Author's Speed Pass)
The author writes directly in `.typ` at full speed—mixing Polish and English, using telegraphic fragments or colloquial phrasing—and drops inline shorthand tags wherever they would otherwise pause:
- **Inline English terms or `[pl: term]`:** Translate to natural Polish academic terminology.
- **`[cite?]`:** Match and insert the appropriate `@citekey` from `library.yaml`.
- **`[check: question or claim]`:** Verify against CNN theory or repo code; answer in chat and correct the clause only if inaccurate.
- **`[data: description]`:** Replace with dynamic `#fmt_val()` / `#fmt_diff()` bindings from `experiments/outputs/tables/*.json` or `*.csv`.

### Mode C — Content-Locked Academic Reconstruction (`cleanup <section>`)
When processing a user-written draft in `.typ`, obey the **Lock vs. Transform** boundary strictly:
1. **Content & Causal Logic Lock (Strictly Frozen):**
   - **Never** invent new claims, add unstated technical reasons, pad paragraphs with filler, or reorder the author's arguments.
   - If Sentence 2 already follows naturally from Sentence 1 by subject matter, **never** inject mechanical connector fluff (*"W nawiązaniu do powyższego..."*, *"W tym kontekście warto zauważyć, że..."*).
2. **Full Academic Register Reconstruction (Unconstrained on Style & Structure):**
   - Do **not** perform a timid spellcheck that leaves spoken or colloquial phrasing intact.
   - Fully reconstruct shorthand, telegraphic fragments, Ponglish, and stream-of-consciousness run-ons into formal, impersonal Polish academic prose (*styl naukowy*: *"zastosowano"*, *"wykazano"*, *"pozwala to uniknąć"*), enforcing the rules in Section 3.
3. **Surgical Flagging in Chat:**
   - Resolve `[cite?]`, `[data: ...]`, and `[check: ...]` tags, answering `[check: ...]` questions explicitly in chat.
   - Flag genuine logical jumps between paragraphs in chat and propose a concise bridge for approval rather than fabricating transitions silently.

---

## 3. Rules of Polish Academic Prose

1. **Eliminate Overdramatic & Absolute Claims:**
   - **Banned vocabulary:** *"bezsprzecznie"*, *"uniwersalne panaceum"*, *"perfekcyjna generalizacja"*, *"zerowe opóźnienie"*, *"drastycznie"*, *"matematycznie niemożliwe"* (without formal proof).
   - **Required stance:** State measured, empirical facts bounded by test conditions (*"wyniki sugerują"*, *"zaobserwowano wzrost o 15,5 p.p."*, *"w warunkach badanego zbioru testowego"*).
2. **Cognitive Cadence (No Dense Concept Walls):**
   - Never pile 4–5 dense technical specifications into a single breath; split complex explanations across 2–3 clear sentences without adding empty filler.
3. **Sentence Length Budget (Max 25–30 Words):**
   - Break multi-clause run-ons into 2 or 3 distinct sentences. Alternate medium explanatory sentences with concise summary sentences.
4. **Acronym Hygiene:**
   - Never stack parenthetical acronyms (avoid *"rozpoznawanie tekstu (OCR) w widzeniu komputerowym (CV) przy użyciu sieci (CNN)"*).
   - Define an acronym once on first use with Polish/English gloss. Omit acronyms used only once or twice; write the full phrase instead.
5. **Academic Polish Register:**
   - Use consistent impersonal forms (*"wytrenowano"*, *"zbadano"*, *"wykazano"*). Never use first-person singular (*"ja"*) or *pluralis auctoris* (*"zaobserwowaliśmy"*).
6. **Twarde Spacje (Non-Breaking Spaces):**
   - Single-letter prepositions/conjunctions (`w`, `z`, `o`, `i`, `a`, `u`) must be bound to the next word with `~` in Typst (`w~niniejszej pracy`, `z~uwagi na`).
7. **Decimal Comma & Unit Spacing:**
   - Polish academic notation uses decimal commas: `87,46%`, `1,08~ms`, `-0,16~p.p.`, `32~times~32~pikseli`.

---

## 4. Typst Technical Guardrails

- **Zero Hardcoding:** Load empirical numbers dynamically via `#let results = json(...)`. Use `#fmt_val()` and `#fmt_diff()` from `template/agh_thesis.typ` for 2-decimal rounding and explicit `+`/`-` signs.
- **Direct Output Paths:** Figures link directly to semantic paths in `experiments/outputs/` (e.g. `../../experiments/outputs/sweeps/blur/blur_curve.png`).
- **Heading Hygiene:** Never write manual numbers in heading strings (write `= Wstęp`, **never** `= 1. Wstęp`) when `#set heading(numbering: ...)` is active.
- **Hayagriva Citations:** Use `@citekey` referencing `document/references/library.yaml`. Zero LaTeX `\cite{}` macros.

---

## 5. Self-Review Checklist

Before finishing any chapter or section edit:
1. **Compilation Check (Mandatory):** Run `typst compile --root . document/main.typ document/main.pdf` and verify exit code 0 with zero layout overflows or unexpected warnings.
2. **Data & Precision Pass:** Verify zero raw IEEE 754 float artifacts (e.g. `0.1600000000000108`) and confirm all bound paths match `experiments/outputs/tables/*.json` or `*.csv`.
3. **Heading & Tag Pass:** Confirm zero duplicate numbering and verify no unresolved `[cite?]`, `[check: ...]`, or `[data: ...]` tags remain in the edited section.

---

## 6. Chapter-End Reviewer Subagent (`academic-reviewer`)

To catch factual slips and citation gaps without overpolicing style during drafting:

### When to Invoke
- **Only at Chapter Completion or Explicit User Request:** Spawn the read-only reviewer subagent only when an entire chapter is finished or when the user explicitly asks for a review/audit. Never invoke it for single-section cleanups or minor editorial fixes.

### Subagent Core Invariants
1. **Strictly Read-Only (`EnableWriteTools: false`):** Returns an objective review report only.
2. **Scoped Critique:** Focus strictly on `Empirical Rigor`, `Technical Accuracy`, `Citation Integrity`, `Logical Coherence & Scope`, and `Typography & Formatting` — do **not** rewrite or nitpick the author's valid phrasing.
3. **Zero Fabricated Criticisms:** Never invent flaws to fill a quota. If a chapter is accurate and well-cited, state that concisely.
4. **Structured Findings:** Report each genuine issue with **Category**, **Severity** (`Critical`, `Major`, `Minor`, `Observation`), **Evidence** (verbatim quote + file/line), and **Actionable Recommendation**.
