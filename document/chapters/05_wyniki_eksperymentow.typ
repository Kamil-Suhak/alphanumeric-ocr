#import "../metadata.typ": *
#import "../template/agh_thesis.typ": fmt_val, fmt_diff

// Dynamiczne wczytanie danych z plików JSON generowanych przez moduł eksperymentów
#let results = json("../../experiments/outputs/tables/accuracy_summary.json")
#let hw = json("../../experiments/outputs/tables/practicality.json")

= Wyniki eksperymentów i analiza porównawcza

== Porównanie na czystym zbiorze testowym EMNIST
Ewaluację przeprowadzono na pełnym, wyizolowanym zbiorze testowym EMNIST ByClass (116 323 próbek). 

#figure(
  table(
    columns: (2fr, 1.2fr, 1.2fr, 1.2fr),
    align: (left, center, center, center),
    table.header([*Metryka*], [*Model A (Czysty)*], [*Model B (Odporny)*], [*Różnica (B - A)*]),
    [Dokładność Top-1 (Accuracy)], [#fmt_val(results.clean_baseline.accuracy)], [#fmt_val(results.robust_cnn.accuracy)], [#fmt_diff(results.robust_cnn.accuracy - results.clean_baseline.accuracy)],
    [Dokładność bez wielkości liter], [#fmt_val(results.clean_baseline.case_insensitive_accuracy)], [#fmt_val(results.robust_cnn.case_insensitive_accuracy)], [#fmt_diff(results.robust_cnn.case_insensitive_accuracy - results.clean_baseline.case_insensitive_accuracy)],
    [Macro-Precision], [#fmt_val(results.clean_baseline.macro_precision)], [#fmt_val(results.robust_cnn.macro_precision)], [#fmt_diff(results.robust_cnn.macro_precision - results.clean_baseline.macro_precision)],
    [Macro-Recall], [#fmt_val(results.clean_baseline.macro_recall)], [#fmt_val(results.robust_cnn.macro_recall)], [#fmt_diff(results.robust_cnn.macro_recall - results.clean_baseline.macro_recall)],
    [Macro-F1], [#fmt_val(results.clean_baseline.macro_f1)], [#fmt_val(results.robust_cnn.macro_f1)], [#fmt_diff(results.robust_cnn.macro_f1 - results.clean_baseline.macro_f1)],
  ),
  caption: [Zestawienie metryk ewaluacji na czystym zbiorze testowym EMNIST ByClass.],
) <tab-czyste-metryki>

Wprowadzenie syntetycznych degradacji do potoku treningowego nie spowodowało degradacji zdolności dyskryminacyjnych modelu na czystych danych (spadek Top-1 zaledwie o 0,16 p.p.). Co istotne, model B osiągnął wyższą precyzję makro (+1,48 p.p.), co wskazuje na bardziej konserwatywne rozkłady prawdopodobieństwa na wyjściu softmax.

== Dynamika odporności na degradacje środowiskowe
Oba modele poddano testom na 19 dyskretnych poziomach degradacji o wzrastającym nasileniu.

#figure(
  table(
    columns: (2.5fr, 1.2fr, 1.2fr, 1.3fr),
    align: (left, center, center, center),
    table.header([*Warunek degradacji*], [*Model A (Czysty)*], [*Model B (Odporny)*], [*Zysk Modelu B*]),
    [Rozmycie Gaussa ($sigma = 1.0$)], [#fmt_val(results.clean_baseline.blur_sigma_1_0)], [#fmt_val(results.robust_cnn.blur_sigma_1_0)], [#fmt_diff(results.robust_cnn.blur_sigma_1_0 - results.clean_baseline.blur_sigma_1_0)],
    [Rozmycie Gaussa ($sigma = 2.0$)], [#fmt_val(results.clean_baseline.blur_sigma_2_0)], [#fmt_val(results.robust_cnn.blur_sigma_2_0)], [#fmt_diff(results.robust_cnn.blur_sigma_2_0 - results.clean_baseline.blur_sigma_2_0)],
    [Rozmycie Gaussa ($sigma = 3.0$)], [#fmt_val(results.clean_baseline.blur_sigma_3_0)], [#fmt_val(results.robust_cnn.blur_sigma_3_0)], [#fmt_diff(results.robust_cnn.blur_sigma_3_0 - results.clean_baseline.blur_sigma_3_0)],
    [Szum Gaussa ($s = 0.15$)], [#fmt_val(results.clean_baseline.noise_std_0_15)], [#fmt_val(results.robust_cnn.noise_std_0_15)], [#fmt_diff(results.robust_cnn.noise_std_0_15 - results.clean_baseline.noise_std_0_15)],
    [Szum Gaussa ($s = 0.20$)], [#fmt_val(results.clean_baseline.noise_std_0_20)], [#fmt_val(results.robust_cnn.noise_std_0_20)], [#fmt_diff(results.robust_cnn.noise_std_0_20 - results.clean_baseline.noise_std_0_20)],
    [Perspektywa ($p = 0.15$)], [#fmt_val(results.clean_baseline.perspective_0_15)], [#fmt_val(results.robust_cnn.perspective_0_15)], [#fmt_diff(results.robust_cnn.perspective_0_15 - results.clean_baseline.perspective_0_15)],
    [Perspektywa ($p = 0.25$)], [#fmt_val(results.clean_baseline.perspective_0_25)], [#fmt_val(results.robust_cnn.perspective_0_25)], [#fmt_diff(results.robust_cnn.perspective_0_25 - results.clean_baseline.perspective_0_25)],
  ),
  caption: [Porównanie dokładności w wybranych punktach krytycznych zaburzeń wejściowych.],
) <tab-sweepy-tabela>

=== Odporność na rozmycie optyczne
Wraz ze wzrostem odchylenia standardowego rozmycia $sigma$, Model A doznaje katastrofalnego załamania dokładności: przy $sigma = 2.0$ jego skuteczność wynosi zaledwie 12,24%, a przy $sigma = 3.0$ spada do 4,28%. W tym samym reżimie Model B utrzymuje odpowiednio 86,20% oraz 64,44% dokładności, co stanowi przewagę rzędu *+60,16 punktu procentowego*.

#figure(
  image("../../experiments/outputs/sweeps/blur/blur_curve.png", width: 85%),
  caption: [Krzywa odporności na rozmycie gaussowskie w funkcji odchylenia standardowego $sigma$.],
) <fig-blur-curve>

=== Odporność na szum sensora
W obecności addytywnego szumu gaussowskiego Model B wykazuje niemal pełną niezmienniczość: spadek dokładności z 87,46% na czystych danych do 86,59% przy $s = 0.20$ wynosi poniżej 0,9 p.p. Dokładność Modelu A spada w tym punkcie do 37,65%.

#figure(
  image("../../experiments/outputs/sweeps/noise/noise_curve.png", width: 85%),
  caption: [Krzywa odporności na addytywny szum gaussowski w funkcji odchylenia $s$.],
) <fig-noise-curve>

=== Odporność na zniekształcenia perspektywiczne
#figure(
  image("../../experiments/outputs/sweeps/perspective/perspective_curve.png", width: 85%),
  caption: [Krzywa odporności na deformacje perspektywiczne w funkcji współczynnika $p$.],
) <fig-perspective-curve>

== Profilowanie sprzętowe i praktyczność wdrożeniowa
#figure(
  table(
    columns: (2.5fr, 2fr),
    align: (left, right),
    table.header([*Wskaźnik sprzętowy*], [*Wartość pomiarowa*]),
    [Liczba parametrów (wszystkie uczone)], [#hw.total_parameters],
    [Rozmiar pliku wag (FP32)], [#hw.pure_weights_size_mb MB],
    [Pełny punkt kontrolny ze stanem optymalizatora], [#hw.checkpoint_size_mb MB],
    [Opóźnienie na CPU (batch = 1)], [#hw.cpu_latency_batch_1_ms ms / znak],
    [Przepustowość CPU (batch = 32)], [#hw.cpu_throughput_chars_per_sec znaków / sek.],
    [Opóźnienie na GPU (batch = 1)], [#hw.gpu_latency_batch_1_ms ms / znak],
    [Przepustowość GPU (batch = 32)], [#hw.gpu_throughput_chars_per_sec znaków / sek.],
  ),
  caption: [Pomiary wydajnościowe modelu AlphanumericCNN.],
) <tab-hardware-practicality>

#block(fill: rgb("#f5f5f7"), inset: 1em, radius: 4pt)[
  #text(weight: "bold")[Wytyczne redakcyjne do rozwinięcia rozdziału:]
  - [ ] Wstawić macierze pomyłek dla EXP-001 oraz EXP-002 (`experiments/outputs/runs/EXP-001_baseline/confusion_matrix.png`).
  - [ ] Omówić rozkłady pomyłek dla poszczególnych klas znaków cyfrowych vs literowych.
]
