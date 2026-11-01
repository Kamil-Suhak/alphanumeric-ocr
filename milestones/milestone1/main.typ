// Raport z Etapu 1 (Milestone 1) - Sprawozdanie dla promotora
#set document(title: "Raport Etapu 1: Odporność klasyfikatora alfanumerycznego na degradacje środowiskowe", author: "Kamil Suhak")
#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 2.5cm),
  header: align(right)[#text(size: 8.5pt, fill: rgb("#666666"))[Praca Inżynierska | Raport z Etapu 1 --- Kamil Suhak]],
  footer: context align(center)[#text(size: 9pt)[#counter(page).display()]],
)
#set text(font: ("Times New Roman", "New Computer Modern"), size: 11pt, lang: "pl")
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.1.")

#let results = json("../../experiments/outputs/tables/accuracy_summary.json")
#let hw = json("../../experiments/outputs/tables/practicality.json")

#align(center)[
  #text(size: 16pt, weight: "bold")[Raport z Postępów Prac: Etap 1\ Badanie odporności sieci CNN na degradacje środowiskowe]
  
  #v(0.3cm)
  #text(size: 12pt)[*Autor:* Kamil Suhak | *Kierunek:* Informatyka | *AGH Kraków*]
  #v(0.1cm)
  #text(size: 10pt, fill: rgb("#555555"))[Data złożenia: Październik 2026 | Status: Zaakceptowany przez promotora]
]

#v(0.5cm)
#line(length: 100%, stroke: 0.5pt + rgb("#cccccc"))
#v(0.5cm)

== 1. Cel i zakres zrealizowanego etapu
Celem pierwszego etapu prac było opracowanie i wdrożenie kompletnego potoku badawczego do klasyfikacji izolowanych 62 klas znaków alfanumerycznych (EMNIST ByClass), wytrenowanie modelu bazowego (Model A) oraz modelu z syntetyczną augmentacją degradacyjną (Model B), a także przeprowadzenie rygorystycznych testów porównawczych na 19 poziomach zakłóceń.

== 2. Podsumowanie wyników empirycznych

#figure(
  table(
    columns: (2.5fr, 1.2fr, 1.2fr, 1.3fr),
    align: (left, center, center, center),
    table.header([*Metryka / Warunek*], [*Model A (Czysty)*], [*Model B (Odporny)*], [*Różnica (B - A)*]),
    [Czysty zbiór testowy Top-1], [#results.clean_baseline.accuracy%], [#results.robust_cnn.accuracy%], [#(results.robust_cnn.accuracy - results.clean_baseline.accuracy) p.p.],
    [Czysty zbiór (bez wielkości liter)], [#results.clean_baseline.case_insensitive_accuracy%], [#results.robust_cnn.case_insensitive_accuracy%], [#(results.robust_cnn.case_insensitive_accuracy - results.clean_baseline.case_insensitive_accuracy) p.p.],
    [Rozmycie Gaussa ($sigma = 2.0$)], [#results.clean_baseline.blur_sigma_2_0%], [#results.robust_cnn.blur_sigma_2_0%], [+#(results.robust_cnn.blur_sigma_2_0 - results.clean_baseline.blur_sigma_2_0) p.p.],
    [Rozmycie Gaussa ($sigma = 3.0$)], [#results.clean_baseline.blur_sigma_3_0%], [#results.robust_cnn.blur_sigma_3_0%], [+#(results.robust_cnn.blur_sigma_3_0 - results.clean_baseline.blur_sigma_3_0) p.p.],
    [Szum sensora ($s = 0.20$)], [#results.clean_baseline.noise_std_0_20%], [#results.robust_cnn.noise_std_0_20%], [+#(results.robust_cnn.noise_std_0_20 - results.clean_baseline.noise_std_0_20) p.p.],
    [Perspektywa ($p = 0.25$)], [#results.clean_baseline.perspective_0_25%], [#results.robust_cnn.perspective_0_25%], [+#(results.robust_cnn.perspective_0_25 - results.clean_baseline.perspective_0_25) p.p.],
  ),
  caption: [Syntetyczne zestawienie wyników Etapu 1 na wyizolowanym zbiorze testowym.],
)

== 3. Wykresy odporności na degradacje środowiskowe

#grid(
  columns: (1fr, 1fr),
  gutter: 1cm,
  figure(
    image("../../experiments/outputs/sweeps/blur/blur_curve.png", width: 100%),
    caption: [Rozmycie gaussowskie ($sigma$).],
  ),
  figure(
    image("../../experiments/outputs/sweeps/noise/noise_curve.png", width: 100%),
    caption: [Szum addytywny ($s$).],
  ),
)

#v(0.5cm)
#figure(
  image("../../experiments/outputs/sweeps/perspective/perspective_curve.png", width: 65%),
  caption: [Zniekształcenia perspektywiczne ($p$).],
)

== 4. Pomiary parametrów i wydajności sprzętowej
Zaprojektowana sieć AlphanumericCNN charakteryzuje się następującymi parametrami fizycznymi:
- *Liczba parametrów uczonych:* #hw.total_parameters (~200 tys. unikalnych wag, 634 tys. z kanałami wewnętrznymi).
- *Rozmiar wag na dysku:* #hw.pure_weights_size_mb MB (FP32).
- *Średnie opóźnienie CPU:* #hw.cpu_latency_batch_1_ms ms / próbkę (przepustowość: #hw.cpu_throughput_chars_per_sec znaków/s).
- *Średnie opóźnienie GPU:* #hw.gpu_latency_batch_1_ms ms / próbkę (przepustowość: #hw.gpu_throughput_chars_per_sec znaków/s).

== 5. Zadania zrealizowane i plan na Etap 2
- [x] Implementacja selektywnego pobierania i korekty orientacji EMNIST ByClass.
- [x] Opracowanie silnika degradacji w dziedzinie ciągłej (rozmycie, szum, homografia).
- [x] Wytrenowanie modeli EXP-001 (Baseline) i EXP-002 (Robust).
- [x] Wykonanie pełnych sweepów porównawczych na 116 323 próbkach testowych.
- [ ] *Plan na Etap 2:* Przygotowanie własnego zbioru fotografii rzeczywistych znaków alfanumerycznych, transfer na bazę Chars74K oraz implementacja wieloziarnowej walidacji krzyżowej (seed-agnostic validation).
