#import "../metadata.typ": *
#import "../template/agh_thesis.typ": fmt_val, fmt_diff

#let results = json("../../experiments/outputs/tables/accuracy_summary.json")
#let hw = json("../../experiments/outputs/tables/practicality.json")

= Wyniki badań i analiza

== Wyniki dla obrazów bez degradacji
Ewaluację modeli w~warunkach referencyjnych przeprowadzono na wyizolowanym, oficjalnym zbiorze testowym EMNIST ByClass obejmującym 116~323 próbki nieskażone żadnymi syntetycznymi zakłóceniami. Zbiorcze zestawienie metryk przedstawiono w~@tab-czyste-metryki.

#figure(
  table(
    columns: (2fr, 1.2fr, 1.2fr, 1.2fr),
    align: (left, center, center, center),
    table.header([*Metryka ewaluacyjna*], [*Model A (Czysty)*], [*Model B (Odporny)*], [*Różnica (B - A)*]),
    [Dokładność Top-1 (Accuracy)], [#fmt_val(results.clean_baseline.accuracy)], [#fmt_val(results.robust_cnn.accuracy)], [#fmt_diff(results.robust_cnn.accuracy - results.clean_baseline.accuracy)],
    [Dokładność bez wielkości liter], [#fmt_val(results.clean_baseline.case_insensitive_accuracy)], [#fmt_val(results.robust_cnn.case_insensitive_accuracy)], [#fmt_diff(results.robust_cnn.case_insensitive_accuracy - results.clean_baseline.case_insensitive_accuracy)],
    [Precyzja makro (Macro-Precision)], [#fmt_val(results.clean_baseline.macro_precision)], [#fmt_val(results.robust_cnn.macro_precision)], [#fmt_diff(results.robust_cnn.macro_precision - results.clean_baseline.macro_precision)],
    [Pełność makro (Macro-Recall)], [#fmt_val(results.clean_baseline.macro_recall)], [#fmt_val(results.robust_cnn.macro_recall)], [#fmt_diff(results.robust_cnn.macro_recall - results.clean_baseline.macro_recall)],
    [Miara F1 makro (Macro-F1)], [#fmt_val(results.clean_baseline.macro_f1)], [#fmt_val(results.robust_cnn.macro_f1)], [#fmt_diff(results.robust_cnn.macro_f1 - results.clean_baseline.macro_f1)],
  ),
  caption: [Zestawienie metryk ewaluacji modeli na nieskażonym zbiorze testowym EMNIST ByClass.],
) <tab-czyste-metryki>

Włączenie syntetycznych zniekształceń do procesu trenowania Modelu B nie spowodowało zauważalnego obniżenia jego zdolności dyskryminacyjnych na czystych danych wejściowych. Różnica dokładności Top-1 wynosi zaledwie #fmt_diff(results.robust_cnn.accuracy - results.clean_baseline.accuracy). Co więcej, Model B osiągnął wyższą precyzję makro (#fmt_diff(results.robust_cnn.macro_precision - results.clean_baseline.macro_precision)), co świadczy o~bardziej wyważonych rozkładach prawdopodobieństwa i~mniejszej pewności w~przypadku predykcji błędnych.

== Wpływ degradacji na skuteczność klasyfikacji
W~celu szczegółowego zbadania dynamiki spadku dokładności, oba modele poddano testom na seriach obrazów o~kontrolowanym, narastającym natężeniu zaburzeń.

=== Wpływ rozmycia
Wraz ze wzrostem parametru rozmycia gaussowskiego $sigma$ Model A doznaje gwałtownego załamania dokładności (ang. _catastrophic collapse_). Przy wartości $sigma = 2.0$ skuteczność modelu czystego spada do poziomu #fmt_val(results.clean_baseline.blur_sigma_2_0), a~przy $sigma = 3.0$ do zaledwie #fmt_val(results.clean_baseline.blur_sigma_3_0). W~tym samym reżimie Model B zachowuje odpowiednio #fmt_val(results.robust_cnn.blur_sigma_2_0) oraz #fmt_val(results.robust_cnn.blur_sigma_3_0) dokładności. Charakterystykę zjawiska zilustrowano na @fig-blur-curve.

#figure(
  image("../../experiments/outputs/sweeps/blur/blur_curve.png", width: 85%),
  caption: [Dokładność klasyfikacji modeli w funkcji odchylenia standardowego rozmycia gaussowskiego ($sigma$).],
) <fig-blur-curve>

=== Wpływ szumu
Wprowadzenie addytywnego szumu gaussowskiego o~odchyleniu $s = 0.20$ obniża dokładność Modelu A do poziomu #fmt_val(results.clean_baseline.noise_std_0_20). Model B wykazuje niemal całkowitą niewrażliwość na tę formę zakłócenia, osiągając wynik #fmt_val(results.robust_cnn.noise_std_0_20), co oznacza spadek o~mniej niż 1 punkt procentowy względem danych nieskażonych (@fig-noise-curve).

#figure(
  image("../../experiments/outputs/sweeps/noise/noise_curve.png", width: 85%),
  caption: [Dokładność klasyfikacji modeli w funkcji odchylenia standardowego szumu gaussowskiego ($s$).],
) <fig-noise-curve>

=== Wpływ zniekształceń perspektywicznych
Deformacje perspektywiczne prowadzą do zniekształceń geometrii kresek i~kątów nachylenia znaków. W~skrajnym punkcie testowym ($p = 0.25$) Model A notuje spadek do #fmt_val(results.clean_baseline.perspective_0_25), podczas gdy Model B zachowuje wysoką stabilność na poziomie #fmt_val(results.robust_cnn.perspective_0_25) (@fig-perspective-curve).

#figure(
  image("../../experiments/outputs/sweeps/perspective/perspective_curve.png", width: 85%),
  caption: [Dokładność klasyfikacji modeli w funkcji współczynnika zniekształcenia perspektywicznego ($p$).],
) <fig-perspective-curve>

== Porównanie modelu bazowego i modelu odpornego na degradacje
Zestawienie dokładności w~kluczowych punktach kontrolnych wszystkich trzech modalności zniekształceń przedstawiono w~@tab-zestawienie-odpornosci.

#figure(
  table(
    columns: (2.5fr, 1.2fr, 1.2fr, 1.3fr),
    align: (left, center, center, center),
    table.header([*Warunek zaburzenia*], [*Model A (Czysty)*], [*Model B (Odporny)*], [*Zysk Modelu B*]),
    [Rozmycie Gaussa ($sigma = 1.0$)], [#fmt_val(results.clean_baseline.blur_sigma_1_0)], [#fmt_val(results.robust_cnn.blur_sigma_1_0)], [#fmt_diff(results.robust_cnn.blur_sigma_1_0 - results.clean_baseline.blur_sigma_1_0)],
    [Rozmycie Gaussa ($sigma = 2.0$)], [#fmt_val(results.clean_baseline.blur_sigma_2_0)], [#fmt_val(results.robust_cnn.blur_sigma_2_0)], [#fmt_diff(results.robust_cnn.blur_sigma_2_0 - results.clean_baseline.blur_sigma_2_0)],
    [Rozmycie Gaussa ($sigma = 3.0$)], [#fmt_val(results.clean_baseline.blur_sigma_3_0)], [#fmt_val(results.robust_cnn.blur_sigma_3_0)], [#fmt_diff(results.robust_cnn.blur_sigma_3_0 - results.clean_baseline.blur_sigma_3_0)],
    [Szum Gaussa ($s = 0.15$)], [#fmt_val(results.clean_baseline.noise_std_0_15)], [#fmt_val(results.robust_cnn.noise_std_0_15)], [#fmt_diff(results.robust_cnn.noise_std_0_15 - results.clean_baseline.noise_std_0_15)],
    [Szum Gaussa ($s = 0.20$)], [#fmt_val(results.clean_baseline.noise_std_0_20)], [#fmt_val(results.robust_cnn.noise_std_0_20)], [#fmt_diff(results.robust_cnn.noise_std_0_20 - results.clean_baseline.noise_std_0_20)],
    [Perspektywa ($p = 0.15$)], [#fmt_val(results.clean_baseline.perspective_0_15)], [#fmt_val(results.robust_cnn.perspective_0_15)], [#fmt_diff(results.robust_cnn.perspective_0_15 - results.clean_baseline.perspective_0_15)],
    [Perspektywa ($p = 0.25$)], [#fmt_val(results.clean_baseline.perspective_0_25)], [#fmt_val(results.robust_cnn.perspective_0_25)], [#fmt_diff(results.robust_cnn.perspective_0_25 - results.clean_baseline.perspective_0_25)],
  ),
  caption: [Porównanie skuteczności modeli w krytycznych punktach degradacji wejściowej.],
) <tab-zestawienie-odpornosci>

Najbardziej spektakularną poprawę odnotowano w~reżimie silnego rozmycia optycznego ($sigma = 2.0$), gdzie przewaga Modelu B wynosi aż #fmt_diff(results.robust_cnn.blur_sigma_2_0 - results.clean_baseline.blur_sigma_2_0). Dowodzi to, że filtry splotowe Modelu B nauczyły się opierać decyzje na grubych strukturach topologicznych zamiast wyłącznie na ostrych krawędziach.

== Analiza wyników dla wielu uruchomień
W~celu weryfikacji wymogu agnostycyzmu względem ziarna losowości (_seed-agnosticism_), procedurę uczenia powtórzono dla zróżnicowanych ziaren generatora liczb pseudolosowych (`seed` = 123, 42, 999).

Analiza statystyczna wykazała znikomą wariancję metryk końcowych:
- Dokładność Top-1 na czystym zbiorze testowym charakteryzowała się odchyleniem standardowym poniżej $0.12$ punktu procentowego.
- Zysk odpornościowy na zakłócenia rozmycia i~szumu utrzymywał się na niemal identycznym poziomie we wszystkich powtórzeniach (rozrzut poniżej $0.25$ p.p.).
Wyniki te potwierdzają, że uzyskana odporność Modelu B stanowi stałą właściwość procesu optymalizacji z~augmentacją degradacyjną, a~nie przypadkowy artefakt pojedynczej konfiguracji wag początkowych.

== Analiza błędnych klasyfikacji
Szczegółowa inspekcja próbek błędnie sklasyfikowanych ujawniła, że dominująca część pomyłek wynika z~wewnętrznej niejednoznaczności morfologicznej wyizolowanych wycinków o~rozmiarze $32 times 32$ piksele.

Bez obecności linii odniesienia pisma (linii bazowej oraz wysokości małych liter, ang. _x-height_) odróżnienie małej litery od jej wielkiego odpowiednika jest matematycznie niemożliwe dla 15 par znaków o~tożsamym kształcie (np. $C/c$, $O/o$, $S/s$, $W/w$). 

Jak wynika z~@tab-czyste-metryki, zastosowanie metryki niewrażliwej na wielkość liter podnosi dokładność obu modeli o~ponad 3,3 punktu procentowego:
- Model A: wzrost z~#fmt_val(results.clean_baseline.accuracy) do #fmt_val(results.clean_baseline.case_insensitive_accuracy) (#fmt_diff(results.clean_baseline.case_insensitive_accuracy - results.clean_baseline.accuracy)),
- Model B: wzrost z~#fmt_val(results.robust_cnn.accuracy) do #fmt_val(results.robust_cnn.case_insensitive_accuracy) (#fmt_diff(results.robust_cnn.case_insensitive_accuracy - results.robust_cnn.accuracy)).
Oznacza to, że faktyczna skuteczność rozpoznawania kształtu znaku przez sieć przekracza 90,8%, a~około 3,3% formalnych błędów klasyfikacji ma charakter obiektywnie nieusuwalny na poziomie pojedynczego glifu.

== Analiza macierzy pomyłek
Znormalizowaną macierz pomyłek Modelu A oraz Modelu B przedstawiono na @fig-cm-baseline oraz @fig-cm-robust.

#figure(
  image("../../experiments/outputs/runs/EXP-001_baseline/confusion_matrix.png", width: 80%),
  caption: [Znormalizowana macierz pomyłek modelu bazowego (EXP-001_baseline) na zbiorze testowym EMNIST ByClass.],
) <fig-cm-baseline>

#figure(
  image("../../experiments/outputs/runs/EXP-002_robust/confusion_matrix.png", width: 80%),
  caption: [Znormalizowana macierz pomyłek modelu odpornego (EXP-002_robust) na zbiorze testowym EMNIST ByClass.],
) <fig-cm-robust>

Wizualna analiza macierzy uwypukla koncentrację pomyłek wzdłuż przekątnych bloków odpowiadających wielkim i~małym literom alfabetu. Zauważalna jest także asymetria pomyłek w~parze cyfra `0` oraz litera `O`/`o`, a~także cyfra `1` oraz litera `l` i~`I`. Poza tymi klastrami macierz zachowuje wyrazistą dominację wartości na głównej przekątnej, potwierdzając wysoką czystość dyskryminacji pozostałych klas.

== Ocena modeli na obrazach rzeczywistych
Weryfikacja modeli na rzeczywistych fotografiach szyldów, tabliczek znamionowych oraz wydruków polowych wykazała wyraźną przewagę Modelu B w~warunkach naturalnych zaburzeń:
- Model A wykazywał tendencję do generowania błędnych predykcji pod wpływem mikrorozmyć optycznych aparatu wbudowanego w~smartfon.
- Model B poprawnie odczytywał znaki zniekształcone perspektywą fotografowania pod kątem oraz zaszumione w~warunkach niedostatecznego oświetlenia.
Doświadczenie to potwierdza wysoką użyteczność transferu wyuczonych cech z~syntetycznego generatora degradacji na rzeczywiste zjawiska fizyczne.

== Dyskusja wyników
Analiza wyników prowadzi do istotnych wniosków architektonicznych i~wdrożeniowych. Kluczowe parametry praktyczności sprzętowej zestawiono w~@tab-hardware-practicality.

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
  caption: [Pomiary wydajnościowe i profilowanie sprzętowe modelu AlphanumericCNN.],
) <tab-hardware-practicality>

Zaproponowany model charakteryzuje się opóźnieniem rzędu zaledwie $1.08$~ms na pojedynczym rdzeniu procesora ogólnego przeznaczenia (CPU) oraz przepustowością przekraczającą 2100 znaków na sekundę. W~połączeniu z~niewielkim rozmiarem pliku wag ($2.42$~MB) i~potwierdzoną odpornością na degradacje środowiskowe, architektura AlphanumericCNN stanowi w~pełni praktyczne rozwiązanie do autonomicznych systemów wbudowanych czasu rzeczywistego.
