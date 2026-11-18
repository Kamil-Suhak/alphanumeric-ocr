#import "../metadata.typ": *

= Metodyka badań

== Zbiór danych
// [Wskazówki autorskie]: Scharakteryzować benchmark EMNIST ByClass (814 255 monochromatycznych glifów w 62 klasach: 10 cyfr, 26 wielkich i 26 małych liter alfabetu łacińskiego) oraz jego genezę z bazy NIST Special Database 19. Zwrócić uwagę na znaczne, naturalne niezrównoważenie klas oraz wprowadzić problem obiektywnej niejednoznaczności morfologicznej 15 par homoglificznych (np. C/c, O/o, S/s, 0/O, 1/l/I) na pojedynczych wycinkach znaków pozbawionych linii bazowej i kontekstu wysokości tekstu.
// Rekomendowana literatura: @cohen2017emnist, @grother2016nist
#lorem(130)

#lorem(130)

#lorem(120)

== Przygotowanie danych
// [Wskazówki autorskie]: Szczegółowo udokumentować deterministyczny potok przetwarzania wstępnego: korektę transpozycji macierzy w surowym formacie EMNIST, kadrowanie glifów $28 times 28$ do tensora $32 times 32$ za pomocą dwupikselowego czarnego obramowania (ang. zero-padding) zamiast interpolacji (co zapobiega rozmyciu cienkich kresek), oraz standaryzację intensywności pikseli na podstawie empirycznych statystyk podzbioru uczącego ($mu = 0,1331$, $sigma = 0,2870$).
// Rekomendowana literatura: @cohen2017emnist, @lecun1998lenet
#lorem(130)

#lorem(130)

#lorem(120)

== Architektura modelu
// [Wskazówki autorskie]: Przedstawić pełną specyfikację autorskiej architektury AlphanumericCNN (trzy bloki $3 times 3$ Conv2d + BatchNorm2d + ReLU + $2 times 2$ MaxPool2d o liczbie kanałów $1 -> 32 -> 64 -> 128$, po których następuje głowica $2048 -> 256 -> 62$ z warstwą BatchNorm1d i Dropout $p = 0,5$). Podać dokładną liczbę parametrów (634 110 parametrów uczonych; 2,42 MB w formacie FP32) oraz uzasadnić wybór zwartej architektury jednokierunkowej zamiast masywnych modeli ResNet czy sekwencyjnych CRNN.
// Rekomendowana literatura: @lecun1998lenet, @ioffe2015batchnorm, @srivastava2014dropout, @he2015delving
#lorem(130)

#lorem(130)

#lorem(120)

== Scenariusze degradacji obrazów
// [Wskazówki autorskie]: Wprowadzić parametryczny symulator degradacji odtwarzający trzy fizyczne zjawiska degradacji obrazu w rzeczywistych warunkach akwizycji. Zdefiniować dyskretne siatki poziomów zaburzeń wykorzystane w testach odporności (łącznie 19 punktów pomiarowych dla rozmycia, szumu i perspektywy) oraz odwołać się do siatki próbek wizualnych (degradation_samples.png).
// Rekomendowana literatura: @hendrycks2019benchmarking, @dodge2016understanding, @gonzalez2018digital
#lorem(130)

=== Rozmycie gaussowskie
// [Wskazówki autorskie]: Sformułować zjawisko rozmycia optycznego i utraty ostrości jako splot z dwuwymiarowym izotropowym jądrem Gaussa o odchyleniu standardowym $sigma in [0,0; 3,0]$, z dynamicznym doborem rozmiaru okna $k = 2 ceil(3 sigma) + 1$ eliminującym ucięcie wag na brzegach. Wyjaśnić, jak narastające $sigma$ tłumi wysokie częstotliwości krawędzi znaków i zlewa sąsiadujące pętle morfologiczne.
// Rekomendowana literatura: @gonzalez2018digital, @vasiljevic2016examining
#lorem(130)

#lorem(130)

=== Szum addytywny matrycy
// [Wskazówki autorskie]: Sformułować zaszumienie sensora CMOS w warunkach niedoświetlenia i wysokiego wzmocnienia ISO jako addytywny biały szum gaussowski $eta tilde.op cal(N)(0, s^2)$ o odchyleniu $s in [0,00; 0,20]$, z przycięciem wartości do zakresu dynamicznego $[0, 1]$. Omówić, jak stochastyczne fluktuacje pikseli degradują lokalny kontrast i generują fałszywe gradienty krawędziowe.
// Rekomendowana literatura: @gonzalez2018digital, @dodge2016understanding
#lorem(130)

#lorem(130)

=== Zniekształcenia perspektywiczne
// [Wskazówki autorskie]: Sformułować nieliniowe skośne ujęcie kamery za pomocą dwuwymiarowej homografii rzutowej $bold(H) in RR^(3 times 3)$ wyznaczanej z losowych przesunięć czterech narożników obrazu w zakresie $[-p dot min(H, W), +p dot min(H, W)]$ dla parametru $p in [0,00; 0,25]$. Opisać wsteczne próbkowanie dwuliniowe ze stałym zerowym dopełnieniem brzegów.
// Rekomendowana literatura: @hartley2004multiple, @chen2021text
#lorem(130)

#lorem(130)

=== Złożone scenariusze zakłóceń i rozmycie ruchowe (OOD)
// [Wskazówki autorskie]: Zdefiniować dwa dodatkowe protokoły testowe uruchamiane wyłącznie na zamrożonych checkpointach (EXP-009): (1) jednoczesną sekwencję degradacji Perspective -> Blur -> Noise na trzech poziomach intensywności (tier_1_mild: p=0,08, sigma=0,8, s=0,04; tier_2_moderate: p=0,15, sigma=1,5, s=0,08; tier_3_harsh: p=0,22, sigma=2,2, s=0,14) oraz (2) kierunkowe poziome rozmycie ruchowe (angle=0,0 deg) o długości jądra L in {3, 5, 7, 9, 11} pikseli, niewystępujące w procesie uczenia (test OOD).
// Rekomendowana literatura: @hendrycks2019benchmarking, @vasiljevic2016examining
#lorem(130)

== Strategie uczenia modeli
// [Wskazówki autorskie]: Zdefiniować kontrolowany eksperyment porównawczy wariantów o identycznej strukturze AlphanumericCNN i hiperparametrach optymalizatora (AdamW, lr = 1e-3, weight_decay = 1e-4, rozmiar partii = 512, 25 epok), powtarzany dla trzech niezależnych ziaren losowości (123, 456, 789) w modelach głównych oraz rozszerzony o badanie ablacyjne pojedynczych czynników (EXP-003–EXP-005).
// Rekomendowana literatura: @loshchilov2017adamw, @shorten2019survey
#lorem(120)

=== Model bazowy
// [Wskazówki autorskie]: Opisać reżim uczenia Modelu A (EXP-001, Clean Baseline), trenowanego wyłącznie na wzorcowych, dopełnionych zerami próbkach EMNIST bez modyfikacji syntetycznych (dla ziaren 123, 456 i 789). Wskazać jego rolę jako punktu odniesienia wyznaczającego górną granicę dokładności na danych czystych oraz bazową podatność na przesunięcia rozkładu wejściowego.
// Rekomendowana literatura: @cohen2017emnist
#lorem(125)

#lorem(125)

=== Model uczony z uwzględnieniem degradacji i warianty ablacyjne
// [Wskazówki autorskie]: Opisać potok stochastycznej augmentacji w locie dla Modelu B (EXP-002, Robust CNN, ziarna 123, 456, 789), gdzie każdy obraz uczący podlega niezależnemu zniekształceniu perspektywicznemu ($p <= 0,25$), rozmyciu Gaussa ($sigma <= 2,0$) oraz szumowi matrycy ($s <= 0,15$), każde z prawdopodobieństwem 0,5. Wyjaśnić celowe ograniczenie $sigma <= 2,0$ w treningu (generalizacja OOD dla $sigma in {2,5; 3,0}$) oraz przedstawić trzy warianty ablacyjne (EXP-003: tylko rozmycie, EXP-004: tylko szum, EXP-005: tylko perspektywa) służące izolacji wpływu poszczególnych modalności i transferu między nimi.
// Rekomendowana literatura: @shorten2019survey, @hendrycks2019benchmarking, @vasiljevic2016examining
#lorem(135)

#lorem(135)

== Metody oceny modeli
// [Wskazówki autorskie]: Zdefiniować ilościowe metryki ewaluacyjne: dokładność ogólną (Top-1 Accuracy), precyzję, pełność i miarę F1 w wariancie makro (uzasadniając konieczność średniej makro przy niezrównoważeniu EMNIST ByClass), krytyczny próg załamania dokładności (50%) oraz dokładność bez rozróżniania wielkości liter (Case-Insensitive Accuracy) ujednolicającą 15 par niejednoznacznych morfologicznie w celu wyizolowania obiektywnego błędu homoglificznego.
// Rekomendowana literatura: @cohen2017emnist, @grother2016nist, @hendrycks2019benchmarking
#lorem(130)

#lorem(130)

#lorem(130)

== Protokół eksperymentalny i reprodukowalność badań
// [Wskazówki autorskie]: Zintegrować protokół prowadzenia eksperymentów i gwarancje powtarzalności: całkowitą izolację nienaruszonego zbioru testowego (116 323 próbek), utrwalone manifesty podziału 90/10 na zbiór uczący i walidacyjny (628 139 / 69 793 próbek), mechanizm zapisu checkpointu ściśle dla minimum straty walidacyjnej, deterministyczny generator ewaluacyjny indeksowany parą (eval_seed, sample_idx) gwarantujący identyczne zniekształcenia na poziomie pojedynczego piksela dla każdego modelu, protokół statycznej kwantyzacji QDQ INT8 w ONNX Runtime (kalibracja na 1 000 próbkach z val_indices.csv) oraz procedurę pomiaru opóźnienia inferencji (rozgrzewka + 1000 iteracji pomiarowych dla partii 1 i 32).
// Rekomendowana literatura: @paszke2019pytorch, @cohen2017emnist
#lorem(130)

#lorem(130)

#lorem(120)
