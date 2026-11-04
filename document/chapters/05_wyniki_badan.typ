#import "../metadata.typ": *

= Wyniki badań i analiza

== Wyniki dla obrazów bez degradacji i dynamika uczenia
// [Section Guide]: Compare the 25-epoch training and validation trajectories of Model A (EXP-001) and Model B (EXP-002), showing how clean training overfits after Epoch 11 (val loss 0.3328 -> 0.3549) whereas stochastic degradations act as an effective regularizer that improves validation loss monotonically through Epoch 25 (0.3326). Present the pristine test-set comparison table (`accuracy_summary.json`), demonstrating that Model B preserves clean accuracy (87.46% vs. 87.62%, a negligible -0.16 p.p. difference) while improving Macro-Precision (+1.48 p.p.) — directly answering the second part of Research Question 2.
// Recommended citations: @cohen2017emnist, @shorten2019survey, @srivastava2014dropout

== Wpływ degradacji na skuteczność klasyfikacji
// [Section Guide]: Introduce the comparative robustness evaluation across all 19 degradation levels on the 116,323-sample test set (over 4.42 million inference passes) and present the synthetic summary table contrasting Model A and Model B at key severity thresholds. Frame this section around Research Question 1 (collapse dynamics of the baseline model) and Research Question 2 (invariance gains of the robust model).
// Recommended citations: @hendrycks2019benchmarking, @dodge2016understanding

=== Wpływ rozmycia
// [Section Guide]: Analyze the Gaussian blur sweep curve (`blur_curve.png` and `blur.csv` for sigma in [0.0, 3.0]), highlighting that Model A collapses below the 50% threshold around sigma approx 1.25 and plunges to 4.28% at sigma = 3.0, whereas Model B retains 86.20% at sigma = 2.0 (+73.96 p.p.) and 64.44% at sigma = 3.0 (+60.16 p.p.). Emphasize the out-of-distribution generalization finding at sigma in {2.5, 3.0}, which exceeds the maximum blur seen during training (sigma <= 2.0).
// Recommended citations: @vasiljevic2016examining, @dodge2016understanding, @gonzalez2018digital

=== Wpływ szumu
// [Section Guide]: Analyze the additive sensor noise sweep (`noise_curve.png` and `noise.csv` for s in [0.00, 0.20]), contrasting Model A's steep cliff drop beyond s = 0.10 (falling to 37.65% at s = 0.20) with Model B's near-flatline invariance (87.46% -> 86.59%, a total drop of only 0.87 p.p., yielding a +48.94 p.p. advantage). Explain how noise-augmented training forces early convolutional filters to act as implicit spatial low-pass denoisers.
// Recommended citations: @dodge2016understanding, @hendrycks2019benchmarking, @gonzalez2018digital

=== Wpływ zniekształceń perspektywicznych
// [Section Guide]: Analyze the projective homography sweep (`perspective_curve.png` and `perspective.csv` for p in [0.00, 0.25]), explaining why spatial pooling gives Model A partial resilience at small tilts before dropping to 64.36% at p = 0.25, while Model B degrades gracefully to 82.83% (+18.47 p.p. advantage). Compare the linear degradation profile of geometric warps against the non-linear cliff collapses observed under blur and noise.
// Recommended citations: @hartley2004multiple, @hendrycks2019benchmarking

== Analiza macierzy pomyłek i niejednoznaczności klas
// [Section Guide]: Provide a brief umbrella introduction transitioning from aggregate accuracy curves to class-wise error structure across the 62 alphanumeric categories.
// Recommended citations: @cohen2017emnist, @grother2016nist

=== Struktura błędów w macierzy pomyłek
// [Section Guide]: Examine the 62x62 normalized confusion matrices (`confusion_matrix.png` for EXP-001 and EXP-002), pointing out the strong primary diagonal alongside distinct off-diagonal error clusters Parallel to the main diagonal (uppercase vs. lowercase letters) and specific digit-letter collisions (0/O, 1/l/I, 9/q, 5/S, 2/Z). Show that both models exhibit virtually identical structural confusion patterns on clean data.
// Recommended citations: @cohen2017emnist, @grother2016nist

=== Niejednoznaczność par homoglificznych i wielkości liter
// [Section Guide]: Directly answer Research Question 3 by quantifying the impact of unifying the 15 morphologically indistinguishable case pairs under the Case-Insensitive Accuracy metric, which boosts accuracy from 87.62% to 90.96% (+3.34 p.p.) for Model A and from 87.46% to 90.88% (+3.42 p.p.) for Model B. Conclude that over 3.3 p.p. of total test error (~3,880 samples) is an irreducible consequence of cropping isolated characters without baseline or x-height context rather than a classifier flaw.
// Recommended citations: @cohen2017emnist, @grother2016nist

== Analiza wyników dla wielu uruchomień
// [Section Guide — Stage 2 Pending Experiment Slot]: Present the statistical repeatability of the training and robustness results across multiple independent pseudorandom seeds (mean +/- standard deviation of clean accuracy and key degradation points), directly addressing Research Question 4 (seed-agnosticism). (Note: If multi-seed runs are not conducted in Stage 2, omit this section and remove Question 4 from Chapter 1).
// Recommended citations: @hendrycks2019benchmarking

== Ocena modeli na obrazach rzeczywistych
// [Section Guide — Stage 2 Pending Experiment Slot]: Evaluate zero-shot domain transfer of Model A and Model B on external real-world character crops (smartphone photographs under natural lighting/tilt and/or the Chars74k benchmark) to verify whether synthetic training augmentations improve generalization to physical camera captures. (Note: Keep or adapt based on which Stage 2 transfer experiments yield the strongest insights).
// Recommended citations: @campos2009chars74k, @chen2021text

== Analiza wydajności obliczeniowej i profilowanie sprzętowe
// [Section Guide]: Present the empirical hardware profiling results from `practicality.json`: 634,110 parameters, 2.42 MB FP32 weight footprint (7.28 MB full checkpoint), CPU inference latency of 1.08 ms/char at batch=1 (2,122.6 chars/s at batch=32), and GPU latency of 0.59 ms/char at batch=1 (46,171.9 chars/s at batch=32). Discuss practical suitability for real-time edge and embedded Industry 4.0 deployment without cloud accelerators.
// Recommended citations: @paszke2019pytorch, @du2013automatic

== Dyskusja wyników
// [Section Guide]: Synthesize the empirical findings across all experiments: explain why a single multi-degradation training pipeline achieves strong invariance across three mathematically distinct perturbation domains without sacrificing clean-data accuracy (no robustness-accuracy trade-off). Contrast the out-of-distribution resilience under blur with the theoretical error ceiling imposed by homoglyphs, connecting the empirical results back to literature benchmarks.
// Recommended citations: @hendrycks2019benchmarking, @dodge2016understanding, @vasiljevic2016examining, @cohen2017emnist, @shorten2019survey
