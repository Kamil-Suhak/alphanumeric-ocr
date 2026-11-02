---
name: thesis
description: Expert authoring, drafting, reviewing, and style guide for the engineering thesis in Typst. Enforces academic Polish tone, prevents LLM prose pathologies, ensures proper typographical cadence, and provides verified recipes for Typst tables, figures, math, and data binding.
---

# Engineering Thesis Craft & Review Guide (`thesis`)

This skill establishes the definitive standard for drafting, editing, and reviewing chapters, tables, formulas, and figures in Typst for this engineering thesis (*Badanie odporności kompaktowej sieci CNN na degradacje środowiskowe w zadaniu klasyfikacji znaków alfanumerycznych*).

---

## 1. The Academic Stance: Anti-AI Slop & Rhetorical Cadence

Large Language Models naturally drift toward dense, hyper-inflated, marketing-style prose full of stacked jargon and dramatic claims. Academic engineering writing at AGH UST requires the exact opposite: **measured humility, intellectual honesty, structural breathing room, and strict empirical grounding.**

### 1.1 The Seven Golden Style Rules

1. **Eliminate Overdramatic & Absolute Claims:**
   - **Never write:** *"bezsprzecznie dowodzi"*, *"uniwersalne panaceum"*, *"perfekcyjna generalizacja"*, *"zerowe opóźnienie"*, *"matematycznie niemożliwe"* (chyba że przedstawiasz formalny dowód twierdzenia).
   - **Instead write:** *"wyniki sugerują"*, *"zaobserwowano istotną poprawę o 15,5 p.p."*, *"średnie opóźnienie wynosi 1,08 ms"*, *"ze względu na brak linii bazowej znaki C i c są trudne do jednoznacznego rozróżnienia"*.
   - Treat every conclusion as bounded by your experimental setup: *"w warunkach badanego zbioru testowego"*, *"dla przyjętego zakresu zaburzeń"*.

2. **Pacing & Cognitive Cadence (Breathing Room):**
   - Dense technical facts must be separated by natural transitions that give the reader mental space to absorb information.
   - Do not fire 5 dense architectural specifications in one breath. Introduce the concept, state the technical detail, and explain *why* it matters or *how* it connects to the research question.
   - Use measured transitional phrases: *"W tym kontekście warto zauważyć, że..."*, *"Należy jednak podkreślić, iż..."*, *"Z praktycznego punktu widzenia oznacza to..."*.

3. **Sentence Length Control (Max 25–30 Words):**
   - LLMs tend to generate 60-word run-on sentences with 5 subordinate clauses.
   - Break multi-clause sentences into 2 or 3 distinct, crisp sentences.
   - Alternate sentence lengths: follow a 20-word explanatory sentence with a short, punchy 8-word summary (*"Podejście to ogranicza ryzyko przeuczenia."*).

4. **Strict Acronym Hygiene:**
   - **Do not stack parenthetical acronyms** (e.g. avoid: *"rozpoznawanie tekstu (OCR) w widzeniu komputerowym (CV) przy użyciu sieci (CNN)"*).
   - Define an acronym **only on its first occurrence** in the chapter: *"konwolucyjne sieci neuronowe (ang. Convolutional Neural Networks, CNN)"*.
   - Never define an acronym that is used only once or twice; write the full phrase instead.
   - Assume your reader is an educated engineer: you do not need to define well-known general acronyms everywhere (e.g., CPU, GPU, RAM, CSV, JSON).

5. **Polish Academic Register (Pluralis Auctoris & Passive Voice):**
   - Use standard Polish academic style:
     - Pluralis auctoris (*"wytrenowaliśmy"*, *"zaobserwowaliśmy"*, *"przeprowadziliśmy analizę"*), OR
     - Formal impersonal/passive (*"wytrenowano"*, *"zaobserwowano"*, *"w pracy zbadano"*).
   - Maintain the chosen voice consistently within a given chapter.

6. **Twarde Spacje (Non-Breaking Spaces):**
   - In Polish typography, single-letter prepositions and conjunctions (`w`, `z`, `o`, `i`, `a`, `u`) must never hang at the end of a line.
   - In Typst, tie them to the following word with a tilde: `w~niniejszej pracy`, `z~uwagi na`, `o~wartości`, `i~dokładności`.

7. **Decimal Comma & Unit Spacing:**
   - Polish academic notation strictly uses the decimal comma: `87,46%` (not `87.46%`), `1,08 ms` (not `1.08 ms`), `0,16 p.p.` (not `0.16 p.p.`).
   - Separate numbers from physical units with a non-breaking space: `1,08~ms`, `32~times~32~pikseli`, `2,42~MB`.

---

## 2. Prose Benchmark: Good vs. Bad Examples

Study these two contrasting passages carefully to calibrate your tone before writing any paragraph.

### 2.1 The Target Standard (Good Example)
> Rozpoznawanie tekstu to dziedzina wizji komputerowej, której głównym celem jest ekstrakcja i konwersja informacji tekstowej z obrazów wejściowych do postaci cyfrowej. Metody te od lat znajdują zastosowanie m.in. w automatyzacji przemysłu oraz w inteligentnych systemach transportowych (np. w kontroli ruchu drogowego), a obecnie coraz powszechniej trafiają do urządzeń konsumenckich i aplikacji codziennego użytku. O ile rozpoznawanie znaków na obrazach o wysokiej jakości i jednolitym kontraście można dziś uznać za zagadnienie w dużej mierze rozwiązane, o tyle proces ten staje się znacznie bardziej skomplikowany w trudnych warunkach środowiskowych tzn. przy niskiej rozdzielczości, perspektywicznych zniekształceniach znaków, niekorzystnym oświetleniu czy wysokim poziomie szumu cyfrowego.
>
> Współcześnie wiodącym podejściem do rozpoznawania tekstu, radzącym sobie z tego typu zakłóceniami, jest wykorzystanie głębokich sieci neuronowych. Wśród nich szczególną rolę w zadaniach związanych z analizą danych wizualnych odgrywają konwolucyjne sieci neuronowe (ang. Convolutional Neural Networks, CNN). Dzięki zdolności do samodzielnej ekstrakcji cech przestrzennych, architektury te wykazują dobrą odporność na lokalne zniekształcenia. Niemniej jednak, osiągnięcie zadowalającej skuteczności w warunkach skrajnej lub wielopoziomowej degradacji środowiskowej wymaga zarówno odpowiedniego doboru architektury modelu, jak i zastosowania zaawansowanych technik augmentacji danych oraz wstępnego przetwarzania obrazu.
>
> Głównym celem niniejszej pracy inżynierskiej jest zbadanie skuteczności konwolucyjnych sieci neuronowych w zadaniu klasyfikacji znaków alfanumerycznych poddanych degradacji środowiskowej różnej intensywności. W ramach przeprowadzonych badań opracowano proces syntetycznej degradacji danych, symulujący zróżnicowane zakłócenia dobrane na podstawie zjawisk rzeczywiście występujących w zdjęciach wykonanych w niekorzystnych warunkach, a następnie przeprowadzono analizę porównawczą modeli trenowanych na obrazach wzorcowych oraz obrazach zniekształconych. Pozwoliło to ocenić odporność sieci na poszczególne rodzaje zakłóceń oraz określić wpływ doboru danych treningowych na ogólną zdolność generalizacji modelu.

#### Why this works:
- **Measured, credible claims:** Acknowledges clean recognition as "largely solved" (*"w dużej mierze rozwiązane"*) while accurately situating the open challenge in degraded environments.
- **Rhythmic breathing room:** Concepts are introduced progressively (domain $\rightarrow$ applications $\rightarrow$ limitations of standard setups $\rightarrow$ deep learning $\rightarrow$ CNNs $\rightarrow$ thesis goal).
- **Clean acronym pacing:** CNN is introduced smoothly with English gloss; no redundant stacking of CV, OCR, ANN, ML.
- **Logical bridges:** Uses natural cohesive connectors (*"O ile..., o tyle..."*, *"Wśród nich szczególną rolę..."*, *"Niemniej jednak..."*).

---

### 2.2 The Anti-Pattern (Bad Example — DO NOT WRITE LIKE THIS)
> Współczesna rewolucja w dziedzinie sztucznej inteligencji bezsprzecznie dowodzi, że tradycyjne paradygmaty widzenia komputerowego są obecnie całkowicie przestarzałe, a głębokie uczenie maszynowe stanowi uniwersalne panaceum na wszelkie wyzwania związane z ekstrakcją deskryptorów alfanumerycznych w dynamicznych środowiskach brzegowych. Wykorzystując zaawansowane topologie DCNN zintegrowane z mechanizmami CBAM, FPN oraz wieloskalową aproksymacją cech w architekturze YOLOv8-OCR zoptymalizowanej za pomocą kwantyzacji INT8 pod akceleratory NPU/TPU, niniejsza implementacja eliminuje wpływ degradacji optycznej, zjawiska aberracji chromatycznej, fluktuacji oświetlenia typu HDR i zaszumienia addytywnego Gaussa na poziomie SNR < 5 dB, zapewniając bezbłędną estymację wektorów cech. Zastosowanie hybrydowego podejścia łączącego konwolucje separowalne z residualnymi połączeniami skrótowymi i adaptacyjnym dropoutem w warstwie FC nie tylko drastycznie redukuje FLOPs o rząd wielkości bez jakiejkolwiek degradacji mAP, ale wręcz gwarantuje perfekcyjną generalizację modelu na dowolnym zbiorze walidacyjnym, deklasując dotychczasowe rozwiązania literaturowe pod każdym względem.

#### Fatal Flaws:
- **Buzzword soup & acronym asphyxiation:** DCNN, CBAM, FPN, YOLOv8-OCR, INT8, NPU, TPU, HDR, SNR, FC, FLOPs, mAP packed into two breathless sentences.
- **Grandiose marketing hype:** *"bezsprzecznie dowodzi"*, *"całkowicie przestarzałe"*, *"uniwersalne panaceum"*, *"eliminuje wpływ"*, *"bezbłędną estymację"*, *"gwarantuje perfekcyjną generalizację"*, *"deklasując rozwiązania literaturowe"*.
- **Zero breathing room:** Sentences exceed 50 words with endless cascading participle clauses.
- **Intellectual dishonesty:** No model "guarantees perfect generalization on any validation set" or "completely eliminates degradation". A thesis committee will reject this immediately.

---

## 3. Typst Recipes & Technical Execution

### 3.1 Dynamic Tables (Zero Hardcoding)
Always import `fmt_val` and `fmt_diff` from `../template/agh_thesis.typ`. Never output raw unrounded arithmetic.

```typst
#import "../metadata.typ": *
#import "../template/agh_thesis.typ": fmt_val, fmt_diff

#let results = json("../../experiments/outputs/tables/accuracy_summary.json")

#figure(
  table(
    columns: (2.5fr, 1.2fr, 1.2fr, 1.3fr),
    align: (left, center, center, center),
    table.header([*Warunek degradacji*], [*Model A (Czysty)*], [*Model B (Odporny)*], [*Różnica (B - A)*]),
    [Rozmycie Gaussa ($sigma = 1.0$)], [#fmt_val(results.clean_baseline.blur_sigma_1_0)], [#fmt_val(results.robust_cnn.blur_sigma_1_0)], [#fmt_diff(results.robust_cnn.blur_sigma_1_0 - results.clean_baseline.blur_sigma_1_0)],
    [Szum Gaussa ($s = 0.20$)], [#fmt_val(results.clean_baseline.noise_std_0_20)], [#fmt_val(results.robust_cnn.noise_std_0_20)], [#fmt_diff(results.robust_cnn.noise_std_0_20 - results.clean_baseline.noise_std_0_20)],
  ),
  caption: [Zestawienie odporności modeli w warunkach wybranych zaburzeń.],
) <tab-zestawienie-odpornosci>
```

### 3.2 Figures & Direct Semantic Output Paths
Point directly to `experiments/outputs/` without copying or renaming files. Place captions on bottom.

```typst
#figure(
  image("../../experiments/outputs/sweeps/blur/blur_curve.png", width: 85%),
  caption: [Dokładność klasyfikacji w funkcji odchylenia standardowego rozmycia gaussowskiego ($sigma$).],
) <fig-blur-curve>

Wykres przedstawiony na @fig-blur-curve obrazuje dynamikę załamania modelu bazowego...
```

### 3.3 Math Equations (Typst Math vs. LaTeX Pitfalls)
- **Fractions:** `$frac(a, b)$` or `$a / b$` (NEVER `\frac{a}{b}`).
- **Matrices:** `$mat(1, 0; 0, 1)$` (NEVER `\begin{matrix}`).
- **Vectors / Bold:** `$bold(x)$, $bold(H)$` (NEVER `\mathbf` or `\boldsymbol`).
- **Operators:** `$tilde.op$` for tilde/distributed, `$approx$` for approximate, `$times$` for dimensions ($32 times 32$).
- **Sets & Real numbers:** `$RR^(1 times 32 times 32)$, $cal(X)$, $subset.eq$`.

### 3.4 Citations (Hayagriva YAML)
- Citations use `@citekey` directly in text:
  ```typst
  Zgodnie z badaniami przeprowadzonymi przez Cohena i in. @cohen2017emnist, zbiór ByClass...
  ```
- All keys must exist in `document/references/library.yaml`. Never use LaTeX `\cite{}`.

---

## 4. The 4-Step Self-Review Protocol

Before finalizing any drafted section, chapter, or table, execute this autonomous checklist:

1. **Compilation Check (Mandatory):**
   - Run: `typst compile --root . document/main.typ document/main.pdf`
   - Ensure the process exits with code 0 and produces **zero warnings**.
2. **Precision & Number Audit:**
   - Are there any raw floats with trailing digits like `0.1600000000000108`? If yes, apply `fmt_diff()` or `fmt_val()`.
   - Are numbers backed by `accuracy_summary.json` or `practicality.json`?
3. **Heading & Numbering Check:**
   - Are there manual numbers written in heading text (e.g., `= 1. Wstęp`)? **Strip them**. Typst numbers headings automatically.
   - In standalone milestone reports, are primary sections level-1 (`=`) to prevent `0.2. 2.`?
4. **Cadence & Tone Audit:**
   - Read the text aloud mentally: Does it sound like an engineer presenting empirical data, or an AI sales pitch?
   - Are any sentences longer than 3 lines? Break them up.
   - Are single-letter prepositions tied with `~`?
