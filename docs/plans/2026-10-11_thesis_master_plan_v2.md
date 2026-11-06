# THESIS MASTER PLAN — V2
**Document Type:** Private Working Reference & Scope Control Document  
**Context:** AGH University of Krakow — *Technologie Przemysłu 4.0* (Engineering Project / *Projekt Dyplomowy*)  
**Original Author:** Kamil Sebastian Suhak (Independent Plan / Alternative AI Working Reference)  
**Creation Date / Timestamp:** 2026-10-11T00:00:00+02:00  
**Navigation:** 1 anchor → 2 known facts → 3 research-design choices → 4 experiments → 5 data/validation → 6 metrics → 7 qualitative analysis → 8 CNN architecture → 9 literature/tools → 10 Polish writing handbook → 11 thesis/supervisor/admin → 12 action list.  
**Status Key:** `DONE` = already reported; `REQUIRED` = recommended core; `CANDIDATE` = evaluate value/cost; `PARKED` = intentionally excluded; `VERIFY` = do not repeat as fact before checking code/source.

---

## 1. Central Research Direction

- **Scope:** Classification of a pre-cropped, isolated $32\times32$ grayscale character among 62 labels (0–9, A–Z, a–z), not a complete OCR detection/recognition pipeline.
- **Primary Question:** How does performance change under controlled corruption and how much does degradation-aware training alter that behavior for the same compact CNN?
- **Model Pairing:** Model A = clean-training control; Model B = degradation-aware treatment. Same architecture and evaluation samples make the contrast interpretable; different seeds and checkpoint epochs are sources of variation to quantify.
- **Academic Contribution:** Academic contribution $\ne$ inventing OCR. Controlled experiment, justified corruptions, repeatability, limitations, clear results, and engineering tradeoffs are defensible contributions.
- **Focus Shift:** Prioritize scientific depth over continually adding unrelated training data. Bigger datasets or extra models are not automatically better experiments; they can change domain, label quality, sampling, and preprocessing all at once.
- **Historical Scope Management:** Original project brief mentioned Chars74k, own photographs, EasyOCR, and a web interface. Treat this as scope history, not proof that all items are scientifically necessary. Confirm any formal obligation with supervisor; website/API/ONNX/deployment work is now **PARKED** by choice.

---

## 2. Existing Source-of-Truth Facts (from September 2026 Progress Report)

| Element | Reported Value | Do Not Overclaim |
| :--- | :--- | :--- |
| **Data** | EMNIST ByClass, 62 classes; official test $n=116,323$; fixed seed-123 90/10 training/validation split: 628,139 / 69,794. | Verify manifests and all index mapping. |
| **Image Pipeline** | Original $28\times28$ orientation corrected, 2-pixel black border to $32\times32$; mean 0.1331 and std 0.2870. | Check orientation, normalization order, and transforms. |
| **CNN** | Three conv blocks $32\to64\to128$; classifier $2048\to256\to62$; 634,110 trainable parameters; FP32 weights ~2.42 MB. | Architecture/parameter count from report; audit source. |
| **Training** | AdamW lr 1e-3; weight decay 1e-4; batch 512; 25 epochs; checkpoint at best validation loss. | Record all remaining configs and version IDs. |
| **Models** | Model A: no synthetic training degradations; Model B: each of blur, noise, and perspective applied stochastically at reported 50% probability. | Check composition order, sampling distribution, independence. |
| **Clean Test** | Model A: 87.62% top-1; 75.59% macro-F1. Model B: 87.46% top-1; 74.58% macro-F1. | Difference in points, not relative percent. |
| **Strong Blur $\sigma=3.0$** | Model A 4.28%; Model B 64.44% (B−A +60.16 percentage points). | Outside Model B’s training $\sigma\le2$; does not prove unseen-corruption transfer. |
| **Noise std=0.20** | Model A 37.65%; Model B 86.59% (+48.94 points). | Check test randomization; 0.20 exceeds Model B’s training $\text{std}\le0.15$. |
| **Perspective 0.25** | Model A 64.36%; Model B 82.83% (+18.47 points). | Definition = max corner displacement relative to image dimension. |
| **Learning Curves** | Model A best validation loss 0.3328 (epoch 11); Model B 0.3326 (epoch 25). | Suggests differing training dynamics; not proof of mechanism. |

- **Other Reported Clean Metrics:** Model A/B macro-precision 80.59 / 82.07%; macro-recall 75.30 / 74.56%; case-insensitive accuracy 90.96 / 90.88%.
- Existing plots and metrics are script-generated and the split uses saved index manifests: this is good evidence of process discipline, not a substitute for multi-seed variation estimates.
- **Correction to Earlier AI Summaries:** Do not call ~91% a "theoretical ceiling", classify a 3.3-point metric increase as mathematically unavoidable error, infer that filters learned topological invariants, or declare embedded readiness without specific evidence. Verify whether claimed 50% per augmentation allows multiple transforms on the same sample.

---

## 3. Research Design: Choose Degradations Deliberately

### 3.1 What Belongs in the Degradation Engine?
- **Selection Criteria:** (a) plausible image-formation or acquisition mechanism in a stated use case; (b) visually/physically interpretable control parameter; (c) relevant to $32\times32$ character crops; (d) independent enough to diagnose; (e) computationally reproducible; (f) not merely duplicating an existing transform. No need to cover every real-world failure.

| Candidate | Why It Might Matter | Priority / Concern |
| :--- | :--- | :--- |
| **Gaussian Blur** | Controlled low-pass blur; simple severity parameter $\sigma$; already implemented. | **CORE.** Gaussian is not identical to actual defocus or motion. |
| **Additive Gaussian Noise** | Simple sensor-like intensity perturbation; already implemented. | **CORE.** Real camera noise often depends on signal and processing. |
| **Perspective Warp** | Projective viewing-angle approximation; already implemented. | **CORE.** Large warps may crop/erase glyph rather than merely distort it. |
| **Motion Blur** | Camera/object movement; direction and length offer interpretable knobs. | **CANDIDATE:** useful unseen corruption for transfer check. |
| **Defocus / Disk Blur** | Optical focus error; more physically aligned to out-of-focus lens than Gaussian blur. | **CANDIDATE:** evaluate against Gaussian blur; avoid redundant full study. |
| **Contrast / Brightness / Gamma** | Lighting/exposure change; especially relevant when adapting to natural photos. | **STRONG CANDIDATE;** define polarity and normalization order. |
| **Uneven Illumination / Shadow** | Spatially nonuniform lighting; common in photographed surfaces. | **CANDIDATE;** $32\times32$ crops might make effect difficult to isolate. |
| **Compression / Resampling** | JPEG/ringing/blocking, resizing; preprocessing/channel effects. | **CANDIDATE;** benchmark if target pipeline includes compression. |
| **Occlusion / Glare / Reflections** | Partial information loss, highlights; realistic but hard to parameterize uniformly. | **OPTIONAL;** no arbitrary severity claims. |
| **Rotation / Translation / Scale** | Misalignment and framing; geometry distinct from perspective. | **CANDIDATE** if crop placement is a major practical concern. |
| **Impulse / Shot / Speckle Noise** | Different noise mechanisms than Gaussian. | **OPTIONAL;** useful transfer tests, not all needed as training types. |
| **Mixed Degradations** | More realistic images contain multiple simultaneous artifacts. | **HIGH VALUE** if baseline single-type results are stable. |

*Literature anchor for categorizing common corruptions:* Hendrycks & Dietterich (ICLR 2019), ImageNet-C. Its categories inspire a taxonomy; its severity scale should NOT be copied directly to $32\times32$ handwritten characters without calibration.

### 3.2 How to Justify Severity Ranges, Including "Why Not 50% Perspective?"
- Avoid arbitrary "0–100%" scales. Define transform parameter mathematically, report units, show representative before/after samples, and note actual pixel displacement at $32\times32$.
- Use a pilot on diverse glyphs to mark mild/moderate/severe values: preservation of class identity, percentage of pixels clipped, visible stroke merging, and whether a human can still plausibly read the glyph. This is calibration, not new training.
- At perspective severity 0.25, maximum corner displacement is $0.25 \times 32 = 8$ pixels. At 0.50 it could be 16 pixels: half the crop width, potentially severe clipping/collapse and broken label validity. *"Why not 50%?"* $\to$ because beyond a justified severity range, the task may change from degradation to loss of ground-truth information. Demonstrate with images rather than assert a universal cutoff.
- Separate in-range and beyond-training-range tests (e.g. $\sigma \le 2$ vs. $\sigma = 2.5$ or $3$ for Model B). Extrapolation in the SAME corruption family is not proof of generalization to a DIFFERENT corruption.
- Do not use observed test performance to retroactively tune the final range without documenting that choice. Pilot/validation selection $\to$ freeze final test protocol $\to$ evaluation.
- A severity grid need not be equal-sized steps: denser points around steep accuracy drop-offs can be useful, but define the grid before the final test evaluation or report exploratory status transparently.

### 3.3 Mixed vs. Unseen Corruption Experiments
- **MIXED:** Train Model A clean, Model B with stochastic independent augmentations (existing Model B may already combine them). Test single degradations and pairs (e.g. blur + noise) using a 2D grid or selected controlled combinations. Measure interaction; do not interpret an uncontrolled mixed test as the effect of one specific factor.
- **UNSEEN:** Freeze Model A/B; test motion blur or non-Gaussian noise absent from Model B training. If Model B wins, it suggests transfer beyond exact transform distribution, not universal robustness.
- **LEAVE-ONE-OUT:** Train with blur + noise but not perspective, then test perspective; compare with all-augmentation model. Clean design but costly (multiple extra trainings/seeds).
- **TRAIN-ON-ONE / TEST-ON-ANOTHER:** A cross-corruption transfer matrix (rows = training augmentations, columns = test corruptions) is informative if experiments can be afforded; otherwise a single targeted pair answers the same idea with less work.
- **Record Degradation Order:** Blur $\to$ noise and noise $\to$ blur differ. Geometry before/after blur can change boundaries. Distinguish a combined transform applied to one image from separate single-transform sweeps.

---

## 4. Experiment Portfolio and Decision Gates

### 4.1 REQUIRED Backbone
- **R1:** Lock evaluation protocol + verify current Model A/B artifacts: split manifest, preprocessing, transformation parameter definitions, run IDs, correct test-only evaluation, and script-generated figures.
- **R2:** Multi-seed training for Model A and Model B (aim for 3 independent seeds each if affordable). Same architecture/data split/hyperparameters; report distribution across training seeds, not just best run.
- **R3:** Core single-degradation sweeps for blur/noise/perspective on matched sample IDs, fixed severity grid, clearly controlled evaluation random seeds. Graph $\text{mean} \pm \text{SD}$ or pointwise intervals.
- **R4:** Clean test metrics including top-1 and macro-F1, with class-level error distribution and paired confusion matrices.
- **R5:** Systematic qualitative error panel + CSV of matched Model A/B predictions (see §7).
- **R6:** Maintain one source-of-truth experiment log and machine-readable outputs.

### 4.2 CANDIDATE, Ranked by Research Value
- **C1:** Cross-corruption experiment (unseen motion blur / alternative noise): answers a distinct generalization question and broadens "robustness" beyond training distribution.
- **C2:** Mixed-degradation testing: useful practical stress test, but recommend small pre-registered matrix rather than huge combinatorial sweep.
- **C3:** Training-ablation: clean, blur-only, noise-only, perspective-only, all. High explanatory power, but 4+ additional training regimes $\times$ seeds is expensive.
- **C4:** External photos: modest but valuable realism check; treat separately from synthetic experiment; explicitly exploratory if sample size is small.
- **C5:** Chars74k EnglishImg: external data test; considerable image harmonization and domain shift; worthwhile only if time permits a defensible preprocessing protocol.
- **C6:** Smaller CNN or capacity comparison: only if assessing accuracy vs. complexity becomes a real question; no obligation to invent a new network.
- **C7:** Extra severity samples around performance collapse: can estimate a practical breakdown threshold if severity is interpretable and reproducible.

### 4.3 PARKED / Not Thesis Scope
- **Website, hosted API, ONNX conversion, and deployment work:** Consciously excluded from the current research direction (even though the original project description proposed a website).
- **EasyOCR as MAIN baseline:** Rejected as not like-for-like; can remain a narrowly framed optional demonstration only if supervisor explicitly values it. Model A vs. Model B is sufficient baseline for the training-augmentation causal comparison.
- **Training on "as much extra data as possible":** Deprioritized; more data introduces dataset composition, labeling, and domain confounds while EMNIST already contains a large supervised training corpus. "Diminishing returns" is a hypothesis, not an established fact without a learning-curve experiment.

---

## 5. External Data: Photographs, Chars74k, Fairness

### 5.1 Own Photographs: Train vs. Test
- **TEST-ONLY (Recommended First):** Take a small, deliberately varied set of independent photos/crops, label every character, preserve provenance/acquisition notes, and evaluate frozen Model A and Model B with exactly the same crops. This measures natural-domain transfer; it does NOT augment training.
- *Small sample drawback:* Uncertain estimates, strong sampling bias, unbalanced labels, manual cropping variability, camera/lighting specificity. Treat 30–50 photos as a pilot, not a definitive claim of generalization to "real-world OCR". Consider more characters, multiple capture conditions, and category balance if feasible.
- **TRAINING:** To claim better performance due to real-photo adaptation, create disjoint train/validation/test partitions (ideally split by original photo/session/source to prevent near-duplicate leakage). Compare models with matched architecture and training budget; control total data volume or explicitly admit more-data confounding. Many labeled photos/crops and metadata are needed, especially with 62 classes.
- *Metadata suggestions:* `source_image_id`, `cropped_character_id`, ground truth, camera/device, date/session, lighting, background, print/handwritten, angle, crop coordinates, preprocessing version, consent/privacy.

### 5.2 Chars74k: What Exactly Is Difficult?
- EnglishImg contains segmented natural-scene characters in 62 class directories, with varying original pixel dimensions/scales and segmentation masks. It is NOT already an EMNIST-style uniform white glyph on black $32\times32$ crop.
- *Pipeline decisions:* Inspect labels/variants $\to$ choose RGB-to-grayscale or threshold/mask strategy $\to$ foreground/background polarity $\to$ tight foreground crop $\to$ preserve aspect ratio and margin $\to$ resize to fit $32\times32$ (not necessarily stretch) $\to$ normalize with training statistics $\to$ visual audit by class $\to$ freeze preprocessing.
- The segmentation mask is potentially useful, but using it changes the task from "classify natural scene crop" to "classify segmented foreground". Avoid a preprocessing method that destroys texture/contrast and then claiming failure reflects model weakness alone.
- *TEST FIRST:* Frozen Model A/B on a held-out, adapted EnglishImg set measures cross-dataset generalization. Train on Chars74k only in a separate, clearly labeled adaptation experiment, with leak-free splitting and controls.
- *Important mismatch:* EMNIST handwriting vs. scene/printed lettering; image normalization can erase key source-domain information; performance may reflect both domain shift and preprocessing mismatch. Document examples before and after transformation.

### 5.3 EasyOCR: What the Comparison Would Actually Mean
- EasyOCR Reader on pre-cropped $32\times32$ glyphs with allowlist/upscaling is practical, but may reject detection or produce no text. Count "no detection" separately from wrong class. It does not solve the exact same task as a classifier with provided crop and forced 62-way decision.
- Use recognition-only mode with supplied crops if possible for a fairer comparison; still differs in training data, architecture, objective, and preprocessing. Do NOT claim its score proves CNN better or worse overall.
- For the thesis core, the correct baseline is Model A vs. Model B (same architecture; training corruption differs). An additional small-capacity architecture baseline is meaningful only for capacity claims.

---

## 6. Randomness and Robustness Measurement

### 6.1 What Changes When You Change a Training Seed?

| Source | Changes with Seed | Should Remain Fixed |
| :--- | :--- | :--- |
| **Initialization** | Initial layer weights, fully connected weights; backend stochasticity. | Architecture/layer counts. |
| **Mini-Batch Ordering** | Shuffled order; data-loader worker random streams. | Dataset identity, train/val/test partition. |
| **Augmentation** | Which training samples receive each transform, parameters, random patterns, and order. | Augmentation families, probability rules, and ranges. |
| **Dropout** | Units masked at each step. | Dropout probabilities and layout. |
| **Training Dynamics** | Gradient path, final weights, best epoch/checkpoint and performance. | Loss, optimizer choice, epochs, LR schedule, and stopping rule. |
| **Evaluation Stochasticity** | Noise realization, perspective draw, test augmentations. | Test sample IDs, corruption definition, severity grid, and metric formula. |

- **Crucial Separation:** TRAINING-SEED variation asks: *"Would the conclusion survive another independently trained network?"* EVALUATION-CORRUPTION-SEED variation asks: *"Would it survive a different random noise/warp realization on the same images?"* One cannot substitute for the other. Use a fixed corruption bank per severity shared by Model A/B for a paired comparison; optionally repeat corruption draws to quantify test randomness. Record both seeds and worker settings.
- Retain the same split across training seeds to isolate optimization/augmentation stochasticity. Note GPU non-deterministic operations can still limit bit-for-bit repeatability despite setting seeds.

### 6.2 Is a Single Scalar "Robustness Score" Worth It?
- **Primary Presentation:** Accuracy-vs-severity curves and A/B gaps, including $\text{mean} \pm \text{SD}$. These reveal threshold effects that one number hides.
- **Optional Summaries:** Absolute accuracy drop from clean to a chosen severity; normalized retention = $\text{accuracy}(\text{severity}) / \text{accuracy}(\text{clean})$; area under accuracy-vs-severity curve (AUC, normalized by severity span); worst-case accuracy on a fixed grid; performance at a prespecified meaningful threshold.
- *Caveats:* Normalized retention can exaggerate robustness of a model with poor clean accuracy; AUC depends on chosen severity bounds and sampling grid; cross-corruption averaging requires an explicit weighting/normalization scheme. If you add a composite score, define it and accompany it with raw curves.
- *Correct Reporting:* "+15.56 percentage points", not "15.56% relative improvement"; if using relative percentage, show denominator. For accuracy differences, compute paired sample-level uncertainty or training-seed variability rather than assuming all 116k test cases are independent across repeated runs.

---

## 7. Source-of-Truth Experiment Registry & Qualitative Evidence

### 7.1 One Registry, Not Scattered Notebooks
- Maintain `experiments/registry.csv` (or `.md`) tracking: Experiment ID, Question/comparison, Git commit, Data manifests, Seeds, Model/protocol, Degradation definitions, Checkpoints, Metrics JSON, Decision (Keep / rerun / revise / no thesis relevance).
- Do not claim a reproducibility guarantee if GPU non-determinism is unaddressed; state achieved controls.

### 7.2 Qualitative Analysis of Classification Errors
- Automate a matched sample-level table: sample ID, image crop, true label, Model A prediction + score, Model B prediction + score, top-3 outputs, correctness flags, corruption/severity.
- *Selection Strata:* Model A wrong / Model B right; Model A right / Model B wrong; both wrong; optionally both right despite degradation. Include counterexamples to the headline conclusion. Choose criteria in advance (or random selection within strata), not manual cherry-picking.
- 6–12 carefully selected main-text cases can be sufficient; appendix gets more. One row/figure should be easy to parse: original, degraded input, ground truth, predictions, and top-3 softmax scores.
- Use actual confusion matrices to identify pairs (`O/0`, `I/l/1`, uppercase/lowercase collisions), not assumptions. Top-1 62-way and case-insensitive metrics measure different tasks; do not convert visual ambiguity into a mathematical impossibility claim.
- Softmax output is a confidence score, not necessarily a calibrated probability. An erroneous high score illustrates overconfidence; proving calibration needs separate ECE/reliability analysis.

---

## 8. Architecture Reference: Understand Your CNN Cold

### 8.1 Forward Pass, Shapes & Layer Purpose
- **Input:** $1 \times 32 \times 32$ grayscale. Zero padding preserves original stroke pixels.
- **Block 1:** Conv 1 $\to$ 32 ($3\times3$, pad 1) + BN + ReLU + $2\times2$ MaxPool: $32 \times 16 \times 16$. Local edge/stroke filters; pooling halves spatial size.
- **Block 2:** Conv 32 $\to$ 64 ($3\times3$, pad 1) + BN + ReLU + MaxPool: $64 \times 8 \times 8$. Combines stroke features into corners, curves, and parts.
- **Block 3:** Conv 64 $\to$ 128 ($3\times3$, pad 1) + BN + ReLU + MaxPool: $128 \times 4 \times 4$. Higher-level spatial patterns; fewer positions, more channels.
- **Flatten:** $128 \times 4 \times 4 = 2,048$. Converts feature maps to 1D feature vector; loses explicit 2D grid structure.
- **Dense Head:** $2,048 \to 256$ + BN + ReLU + Dropout ($p=0.5$). Combines spatial features; dropout reduces co-adaptation during training.
- **Output:** $256 \to 62$ logits. One raw score per class; argmax yields predicted character.

*Weight Sharing & Receptive Field:* The $3\times3$ kernel sees a local neighborhood; stacking conv layers expands effective receptive field. After 3 pools: $32 \to 16 \to 8 \to 4$. Dense layer receives 2,048 features with both class information and residual position information. The model has fixed-length output for one glyph, not a variable-length transcript; it cannot locate letters in a full photograph without preprocessing/cropping.

### 8.2 What Training Actually Does & Degradation Mechanics
- At each mini-batch: (1) load images, optionally apply training corruption, normalize; (2) forward pass computes 62 logits per sample; (3) cross-entropy penalizes a low score for the correct label; (4) backpropagation calculates gradients; (5) AdamW updates parameters; (6) repeat. Checkpoint selected by clean validation loss.
- *Why Model A fails:* Distribution shift and loss of discriminative high-frequency stroke patterns.
- *Why Model B survives:* Repeated exposure to varied perturbations forces representation to rely on coarse structural topology.
- *Mechanism distinctions:* Blur merges fine strokes and erases gaps; noise adds false edge gradients; perspective alters aspect ratios and shifts corner coordinates. Model A and Model B differ in training distributions, not architectural capacity. Model B may trade some clean performance or class precision/recall for robustness.

---

## 9. Literature Review & Research Tools

- **Research Questions from Literature:** How is isolated character classification distinguished from end-to-end OCR? What does EMNIST ByClass contain (splits, class imbalance, visually ambiguous labels)? What image corruptions are physically motivated (ImageNet-C)? What does literature establish about seen vs. unseen distortions?
- **Minimal Effective Tool Stack:** Zotero (reference manager with Word/LibreOffice plugin, collections for CNN foundations, OCR datasets, robustness/corruption, augmentation); Google Scholar / ResearchRabbit / Elicit (for discovering citations and filling gaps).
- **Pitfall:** Importing a DOI or PDF does not guarantee correct citation metadata. Verify the citation record and write the claim from the paper, not from an AI summary.

---

## 10. Warsztat pisania naukowego po polsku

- **Podział funkcji zdań:** Rozdziel cztery funkcje: (1) fakt z literatury, (2) opis własnej metody, (3) obserwacja z danych, (4) interpretacja.
- **Stopniowanie pewności:** „Wykazano, że…” (gdy pomiar to wprost uzasadnia), „Wyniki sugerują, że…” (gdy wniosek jest uzasadniony, ale nie jedyny), „Zaobserwowano…” (opis wykresu/tabeli), „Może to wynikać z…” (hipoteza mechanizmu).
- **Zasady dotyczące liczb:** Różnica 85% vs 70% to **15 punktów procentowych**, a nie „15%”. Zawsze podawaj jednostki ($\sigma$ w pikselach, std w skali intensywności 0–1). Bez formalnego testu nie używaj sformułowania „statystycznie istotnie”.
- **Wzór akapitu badawczego:** Metoda $\to$ Obserwacja $\to$ Wniosek $\to$ Zakres/Ograniczenie.
- **Usuwanie żargonu AI:** Eliminuj „W dobie dynamicznego rozwoju sztucznej inteligencji…”, „uniwersalne panaceum”, „perfekcyjna generalizacja”. Zastępuj twierdzenia typu „model nauczył się rozpoznawać topologię” bezpieczniejszym: „wynik jest zgodny z hipotezą, że augmentacja ograniczyła zależność klasyfikacji od drobnych szczegółów obrazu”.

---

## 11. Supervisor, Thesis Structure & AGH Admin

- **Showcase dla Promotora:** Krótki raport w języku polskim: cel i zakres $\to$ zbiór/podział $\to$ architektura i reżim uczenia $\to$ zakresy zakłóceń $\to$ 3 kluczowe wykresy + tabela na danych czystych $\to$ ostrożne wnioski $\to$ ograniczenia (pojedyncze ziarno, degradacje syntetyczne) $\to$ konkretne kolejne kroki.
- **Ramy formalne:** Kierunek wspólny WO i EAIiIB. Zweryfikować wymogi formalne, szablon, bibliografię oraz wytyczne dotyczące deklaracji AI z wydziałem prowadzącym.
- **Zarządzanie zakresem z karty tematu:** Oryginalny opis tematu wspominał o zbiorze mieszanym, fotografiach własnych, Chars74k, EasyOCR i serwisie www. Jeżeli którykolwiek z elementów był traktowany jako zobowiązanie formalne, należy wcześnie omówić z promotorem zawężenie zakresu do badań czysto eksperymentalnych (rezygnacja z serwisu WWW/API/ONNX).

---

## 12. Action List / Decision Checklist

1. Audit existing Model A/B runs, log sources of randomness, and verify script reproducibility.
2. Freeze primary research questions and degradation selection rubric; calibrate severity with visual samples.
3. Implement matched corruption bank and multi-seed Model A/B training (aim 3 seeds); report distribution.
4. Create systematic qualitative analysis from sample-level prediction exports (both Model A/B successes and failures).
5. Decide between mixed-corruption test vs. unseen corruption test (motion blur) based on compute budget.
6. Choose at most one external transfer test (own photos or Chars74k) if time is constrained; keep as test-only.
7. Build Zotero library and draft methods directly from configuration files.
