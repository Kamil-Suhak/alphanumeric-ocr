# Typst Recipes & Technical Code Patterns

Reference recipes for authoring Typst components in this thesis workspace. Agents should inspect this document when constructing complex tables, embedding figures, writing mathematical formulas, or editing citations.

---

## 1. Dynamic Metric Tables (Zero Hardcoding)

Always use `fmt_val` and `fmt_diff` from `document/template/agh_thesis.typ` to guarantee clean 2-decimal rounding with Polish decimal commas and explicit signs (`+`/`-`).

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
    [Rozmycie Gaussa ($sigma = 2.0$)], [#fmt_val(results.clean_baseline.blur_sigma_2_0)], [#fmt_val(results.robust_cnn.blur_sigma_2_0)], [#fmt_diff(results.robust_cnn.blur_sigma_2_0 - results.clean_baseline.blur_sigma_2_0)],
    [Szum Gaussa ($s = 0.20$)], [#fmt_val(results.clean_baseline.noise_std_0_20)], [#fmt_val(results.robust_cnn.noise_std_0_20)], [#fmt_diff(results.robust_cnn.noise_std_0_20 - results.clean_baseline.noise_std_0_20)],
  ),
  caption: [Zestawienie odporności modeli w warunkach wybranych zaburzeń.],
) <tab-zestawienie-odpornosci>
```

---

## 2. Figures & Direct Semantic Output Paths

Point directly to semantic experiment output directories. Do not copy or duplicate image files.

```typst
#figure(
  image("../../experiments/outputs/sweeps/blur/blur_curve.png", width: 85%),
  caption: [Dokładność klasyfikacji w funkcji odchylenia standardowego rozmycia gaussowskiego ($sigma$).],
) <fig-blur-curve>

#figure(
  image("../../experiments/outputs/runs/EXP-001_baseline/confusion_matrix.png", width: 80%),
  caption: [Znormalizowana macierz pomyłek modelu bazowego (EXP-001) na zbiorze testowym.],
) <fig-cm-baseline>
```

Cross-reference in text using `@fig-blur-curve` or `@tab-zestawienie-odpornosci`.

---

## 3. Mathematical Notation (Typst Math vs. LaTeX)

| Math Construct | Correct Typst Syntax | Invalid / LaTeX Leaks (Do Not Use) |
| :--- | :--- | :--- |
| **Fraction** | `$frac(a, b)$` or `$a / b$` | `\frac{a}{b}` |
| **Matrix** | `$mat(1, 0; 0, 1)$` | `\begin{matrix}` |
| **Vector / Bold** | `$bold(x)$, $bold(H)$` | `\mathbf`, `\boldsymbol` |
| **Distribution / Tilde**| `$tilde.op$` | `sim`, `\sim` |
| **Approximate** | `$approx$` | `\approx` |
| **Real Space** | `$RR^(1 times 32 times 32)$` | `\mathbb{R}` |
| **Dimensions** | `$32 times 32$` | `32x32`, `32 \times 32` |
| **Text inside math**| `$text("blur")$` or `$"blur"$` | `\text{blur}` |

---

## 4. Hayagriva YAML Citations

References live in `document/references/library.yaml`. Cite with `@citekey`.

```typst
Jak wykazano w badaniach Cohena i in. @cohen2017emnist, zbiór ByClass...
```

To add a new entry to `document/references/library.yaml`:
```yaml
goodfellow2016deep:
  type: book
  title: "Deep Learning"
  author:
    - Goodfellow, Ian
    - Bengio, Yoshua
    - Courville, Aaron
  date: 2016
  publisher: "MIT Press"
```
