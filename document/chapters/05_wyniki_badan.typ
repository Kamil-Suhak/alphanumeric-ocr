#import "../metadata.typ": *

= Wyniki badań i analiza

== Wyniki dla obrazów bez degradacji i dynamika uczenia
// [Wskazówki autorskie]: Zestawić 25-epokowe trajektorie uczenia i walidacji Modelu A (EXP-001) oraz Modelu B (EXP-002), wykazując, że uczenie na danych czystych prowadzi do przetrenowania po 11. epoce (wzrost straty walidacyjnej z 0,3328 do 0,3549), podczas gdy stochastyczna augmentacja pełni rolę regularizatora pozwalającego na monotoniczny spadek straty walidacyjnej aż do 25. epoki (0,3326). Zaprezentować tabelę porównawczą na nienaruszonym zbiorze testowym (accuracy_summary.json), potwierdzając zachowanie skuteczności Modelu B na czystych danych (87,46% vs 87,62%, minimalny spadek o 0,16 p.p.) przy wzroście precyzji makro (+1,48 p.p.) – odpowiadając wprost na drugą część Pytania Badawczego 2.
// Rekomendowana literatura: @cohen2017emnist, @shorten2019survey, @srivastava2014dropout

== Wpływ degradacji na skuteczność klasyfikacji
// [Wskazówki autorskie]: Wprowadzić do analizy odporności na wszystkich 19 poziomach degradacji na pełnym zbiorze testowym (116 323 próbki, ponad 4,42 mln operacji inferencji) i przedstawić syntetyczną tabelę porównawczą Modelu A i Modelu B dla kluczowych progów zakłóceń. Ustrukturyzować analizę wokół Pytania Badawczego 1 (dynamika załamania modelu bazowego) oraz Pytania Badawczego 2 (skala zysku odporności modelu odpornego).
// Rekomendowana literatura: @hendrycks2019benchmarking, @dodge2016understanding

=== Wpływ rozmycia
// [Wskazówki autorskie]: Dokonać szczegółowej analizy krzywej odporności na rozmycie gaussowskie (blur_curve.png oraz blur.csv dla $sigma in [0,0; 3,0]$), wskazując, że Model A przekracza próg załamania 50% już przy $sigma approx 1,25$ i drastycznie spada do 4,28% przy $sigma = 3,0$, podczas gdy Model B zachowuje 86,20% przy $sigma = 2,0$ (+73,96 p.p.) oraz 64,44% przy $sigma = 3,0$ (+60,16 p.p.). Podkreślić kluczowy wniosek o generalizacji poza dziedzinę uczącą (ang. out-of-distribution) dla $sigma in {2,5; 3,0}$, mimo że maksymalne rozmycie treningowe wynosiło $sigma = 2,0$.
// Rekomendowana literatura: @vasiljevic2016examining, @dodge2016understanding, @gonzalez2018digital

=== Wpływ szumu
// [Wskazówki autorskie]: Zanalizować przebieg krzywej odporności na szum sensora (noise_curve.png oraz noise.csv dla $s in [0,00; 0,20]$), kontrastując gwałtowne załamanie Modelu A powyżej $s = 0,10$ (spadek do 37,65% przy $s = 0,20$) z niemal całkowitą niewrażliwością Modelu B (spadek z 87,46% do zaledwie 86,59%, czyli ubytek poniżej 0,9 p.p., co daje przewagę +48,94 p.p.). Wyjaśnić, w jaki sposób uczenie z szumem wymusza na początkowych filtrach splotowych funkcję niejawnych, dolnoprzepustowych filtrów odszumiających.
// Rekomendowana literatura: @dodge2016understanding, @hendrycks2019benchmarking, @gonzalez2018digital

=== Wpływ zniekształceń perspektywicznych
// [Wskazówki autorskie]: Zanalizować przebieg odporności na dystorsję perspektywiczną (perspective_curve.png oraz perspective.csv dla $p in [0,00; 0,25]$), wyjaśniając, dlaczego agregacja cech w warstwach Max Pooling zapewnia Modelowi A częściową tolerancję na małe kąty skośne, zanim nastąpi spadek do 64,36% przy $p = 0,25$, podczas gdy Model B łagodnie zachowuje 82,83% (+18,47 p.p.). Zestawić liniowy charakter degradacji przy przekształceniach geometrycznych z nieliniowymi klifami obserwowanymi przy rozmyciu i szumie.
// Rekomendowana literatura: @hartley2004multiple, @hendrycks2019benchmarking

== Analiza macierzy pomyłek i niejednoznaczności klas
// [Wskazówki autorskie]: Zapewnić zwięzłe wprowadzenie przechodzące od zagregowanych krzywych dokładności do szczegółowej struktury pomyłek w podziale na 62 kategorie znaków alfanumerycznych.
// Rekomendowana literatura: @cohen2017emnist, @grother2016nist

=== Struktura błędów w macierzy pomyłek
// [Wskazówki autorskie]: Przeanalizować znormalizowane macierze pomyłek $62 times 62$ (confusion_matrix.png dla EXP-001 i EXP-002), wskazując dominującą główną przekątną oraz wyraziste pasma błędów równoległe do przekątnej (zamiana wielkich i małych liter przesuniętych o 26 pozycji) i konkretne kolizje między cyframi a literami (0/O, 1/l/I, 9/q, 5/S, 2/Z). Wykazać, że oba modele wykazują niemal identyczny rozkład strukturalny pomyłek na danych czystych.
// Rekomendowana literatura: @cohen2017emnist, @grother2016nist

=== Niejednoznaczność par homoglificznych i wielkości liter
// [Wskazówki autorskie]: Bezpośrednio odpowiedzieć na Pytanie Badawcze 3, przedstawiając ilościowe skutki ujednolicenia 15 par znaków nierozróżnialnych morfologicznie w metryce Case-Insensitive Accuracy, co podnosi wynik z 87,62% do 90,96% (+3,34 p.p.) dla Modelu A oraz z 87,46% do 90,88% (+3,42 p.p.) dla Modelu B. Wywieść wniosek, że ponad 3,3 p.p. całkowitego błędu testowego (~3880 próbek) wynika z obiektywnej równoważności wizualnej wyizolowanych glifów pozbawionych linii bazowej, a nie z niedoskonałości klasyfikatora.
// Rekomendowana literatura: @cohen2017emnist, @grother2016nist

== Analiza wyników dla wielu uruchomień
// [Wskazówki autorskie – Miejsce na eksperyment Etapu 2]: Przedstawić powtarzalność statystyczną procesu uczenia i charakterystyk odpornościowych dla kilku niezależnych ziaren losowości (wartości średnie +/- odchylenie standardowe dokładności bazowej i kluczowych punktów degradacji), odpowiadając wprost na Pytanie Badawcze 4 (odporność na dobór ziarna, ang. seed-agnosticism). (Uwaga: W przypadku rezygnacji z powtórzeń w Etapie 2, podrozdział należy usunąć, a Pytanie 4 wykreślić z Rozdziału 1).
// Rekomendowana literatura: @hendrycks2019benchmarking

== Ocena modeli na obrazach rzeczywistych
// [Wskazówki autorskie – Miejsce na eksperyment Etapu 2]: Dokonać ewaluacji transferu zerostopniowego (ang. zero-shot domain transfer) Modelu A i Modelu B na zewnętrznych wycinkach znaków rzeczywistych (zdjęcia wykonane smartfonem w zróżnicowanym oświetleniu i ujęciu kątowym lub zbiór Chars74k), aby sprawdzić, w jakim stopniu syntetyczna augmentacja degradacyjna poprawia generalizację na fizyczne zdjęcia z aparatów. (Uwaga: Dostosować treść w zależności od tego, które eksperymenty transferu z Etapu 2 przyniosą najbardziej wartościowe wnioski).
// Rekomendowana literatura: @campos2009chars74k, @chen2021text

== Analiza wydajności obliczeniowej i profilowanie sprzętowe
// [Wskazówki autorskie]: Zaprezentować wyniki profilowania sprzętowego z pliku practicality.json: 634 110 parametrów, rozmiar wag FP32 wynoszący 2,42 MB (pełny checkpoint 7,28 MB), opóźnienie inferencji na CPU na poziomie 1,08 ms/znak dla partii 1 (przepustowość 2122,6 znaków/s dla partii 32) oraz opóźnienie na GPU równe 0,59 ms/znak dla partii 1 (46 171,9 znaków/s dla partii 32). Przedyskutować praktyczną przydatność sieci do wdrożeń brzegowych i systemów wbudowanych Przemysłu 4.0 czasu rzeczywistego bez konieczności stosowania akceleratorów chmurowych.
// Rekomendowana literatura: @paszke2019pytorch, @du2013automatic

== Dyskusja wyników
// [Wskazówki autorskie]: Dokonać syntetycznego podsumowania i dyskusji rezultatów: wyjaśnić, dlaczego pojedynczy potok augmentacji wielorodzajowej zapewnia wysoką odporność w trzech odmiennych matematycznie modalnościach zaburzeń bez spadku dokładności na danych czystych (brak zjawiska kompromisu między odpornością a dokładnością, ang. robustness-accuracy trade-off). Skonfrontować odporność na rozmycie poza zakresem treningowym z teoretycznym sufitem dokładności narzuconym przez pary homoglificzne, odnosząc uzyskane wyniki do publikacji benchmarkowych w literaturze.
// Rekomendowana literatura: @hendrycks2019benchmarking, @dodge2016understanding, @vasiljevic2016examining, @cohen2017emnist, @shorten2019survey
