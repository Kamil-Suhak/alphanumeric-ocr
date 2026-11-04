#import "../metadata.typ": *

= Wstęp

== Wprowadzenie
// [Section Guide]: Introduce the domain of text and character recognition in computer vision, its industrial and consumer applications (e.g., ALPR, Industry 4.0 automation), and why degraded environmental conditions (low resolution, blur, sensor noise, perspective skew) remain challenging despite clean-image OCR being largely solved. Motivate compact Convolutional Neural Networks (CNNs) combined with degradation-aware training augmentation. (Already drafted).
// Citations used: @ye2015text, @du2013automatic, @chen2021text, @trivedi2026improving, @lecun1998lenet, @dodge2016understanding, @shorten2019survey
Rozpoznawanie tekstu to dziedzina wizji komputerowej, której głównym celem jest ekstrakcja i~konwersja informacji tekstowej z~obrazów wejściowych do postaci cyfrowej @ye2015text. Metody te od lat znajdują zastosowanie m.in. w~automatyzacji przemysłu oraz w~inteligentnych systemach transportowych (np. w~kontroli ruchu drogowego @du2013automatic), a~obecnie coraz powszechniej trafiają do urządzeń konsumenckich i~aplikacji codziennego użytku. O~ile rozpoznawanie znaków na obrazach o~wysokiej jakości i~jednolitym kontraście można dziś uznać za zagadnienie w~dużej mierze rozwiązane, o~tyle proces ten staje się znacznie bardziej skomplikowany w~trudnych warunkach środowiskowych, tzn. przy niskiej rozdzielczości, perspektywicznych zniekształceniach znaków, niekorzystnym oświetleniu czy wysokim poziomie szumu cyfrowego @chen2021text, @trivedi2026improving.

Współcześnie wiodącym podejściem do rozpoznawania tekstu, radzącym sobie z~tego typu zakłóceniami, jest wykorzystanie głębokich sieci neuronowych. Wśród nich szczególną rolę w~zadaniach związanych z~analizą danych wizualnych odgrywają konwolucyjne sieci neuronowe (ang. _Convolutional Neural Networks_, CNN) @lecun1998lenet. Dzięki zdolności do samodzielnej ekstrakcji cech przestrzennych architektury te wykazują dobrą odporność na lokalne zniekształcenia. Niemniej jednak osiągnięcie zadowalającej skuteczności w~warunkach skrajnej lub wielopoziomowej degradacji środowiskowej wymaga zarówno odpowiedniego doboru architektury modelu, jak i~zastosowania zaawansowanych technik augmentacji danych oraz wstępnego przetwarzania obrazu @dodge2016understanding, @shorten2019survey.

== Cel i zakres pracy
// [Section Guide]: Define the primary engineering and research objective—evaluating the robustness of a compact CNN on 62-class alphanumeric classification under parametric environmental degradations—and enumerate the 5 concrete engineering tasks from dataset preparation and model design to degradation sweeps and hardware profiling. (Already drafted).
// Citations used: @cohen2017emnist
Głównym celem niniejszej pracy inżynierskiej jest zbadanie skuteczności konwolucyjnych sieci neuronowych w~zadaniu klasyfikacji znaków alfanumerycznych poddanych degradacji środowiskowej o~różnej intensywności. W~ramach przeprowadzonych badań opracowano proces syntetycznej degradacji danych, symulujący zróżnicowane zakłócenia dobrane na podstawie zjawisk rzeczywiście występujących na fotografiach wykonanych w~niekorzystnych warunkach, a~następnie przeprowadzono analizę porównawczą modeli trenowanych na obrazach wzorcowych oraz obrazach zniekształconych. Pozwoliło to ocenić odporność sieci na poszczególne rodzaje zakłóceń oraz określić wpływ doboru danych treningowych na ogólną zdolność generalizacji modelu.

Szczegółowy zakres pracy obejmuje następujące zagadnienia inżynierskie i~badawcze:
1. *Pozyskanie i~deterministyczne przygotowanie danych:* Wykorzystanie benchmarku EMNIST ByClass (814~255 próbek, 62 klasy) @cohen2017emnist oraz opracowanie deterministycznego potoku przetwarzania wstępnego z~wykorzystaniem dopełnienia zerami (_zero-padding_), eliminującego artefakty interpolacyjne.
2. *Zaprojektowanie kompaktowej architektury splotowej:* Opracowanie modelu AlphanumericCNN o~niskim budżecie pamięciowym (poniżej 3~MB) i~niskiej latencji wnioskowania, przeznaczonego do wdrożeń na urządzeniach brzegowych.
3. *Implementacja parametrycznego symulatora degradacji:* Opracowanie modułu generującego w~czasie rzeczywistym trzy modalności zaburzeń: rozmycie optyczne, addytywny szum sensora CMOS oraz deformacje rzutowe (perspektywiczne).
4. *Przeprowadzenie ustrukturyzowanych eksperymentów:* Wytrenowanie modelu bazowego oraz modelu z~dynamiczną augmentacją degradacyjną przy stałym reżimie optymalizacyjnym.
5. *Ewaluacja empiryczna i~analiza odporności:* Wyznaczenie pełnych charakterystyk odpornościowych (_degradation sweeps_), badanie zjawiska niejednoznaczności par homoglificznych, profilowanie sprzętowe (CPU/GPU) oraz weryfikacja stabilności wyników dla wielu różnych ziaren generatora liczb pseudolosowych.

== Problem badawczy i pytania badawcze
// [Section Guide]: State the central research problem in a highlighted callout block and decompose it into 4 falsifiable research questions covering: (1) baseline collapse dynamics, (2) robustness vs. clean-accuracy retention under multi-degradation augmentation, (3) morphological homoglyph ambiguity on isolated crops, and (4) statistical repeatability across random seeds. (Already drafted).
// Citations used: @hendrycks2019benchmarking, @dodge2016understanding
W~praktycznych zastosowaniach systemów wizyjnych jakość rejestrowanego sygnału podlega nieustannym fluktuacjom wynikającym z~warunków otoczenia. Tradycyjne modele uczone na idealnych obrazach laboratoryjnych wykazują zjawisko gwałtownego załamania jakości działania pod wpływem zaburzeń rozkładu danych wejściowych @hendrycks2019benchmarking, @dodge2016understanding. Główny problem badawczy podjęty w~niniejszej pracy sformułowano w~postaci następującego pytania:

#align(center)[
  #block(width: 90%, inset: 1.2em, stroke: 0.5pt + rgb("#cccccc"), radius: 4pt, fill: rgb("#fafafa"))[
    #set text(style: "italic")
    W~jaki sposób wprowadzenie parametrycznych, losowych degradacji środowiskowych do procesu uczenia kompaktowej sieci konwolucyjnej wpływa na jej odporność, dynamikę załamania dokładności oraz zdolność zachowania wysokiej skuteczności na danych nieskażonych w~zadaniu klasyfikacji 62 klas alfanumerycznych?
  ]
]

W~celu szczegółowego rozstrzygnięcia tak postawionego problemu sformułowano cztery precyzyjne pytania badawcze:
- *Pytanie 1:* Jaka jest dynamika spadku dokładności modelu bazowego pod wpływem narastającego rozmycia, szumu matrycy oraz zaburzeń perspektywicznych i~w~których punktach następuje załamanie zdolności klasyfikacyjnych?
- *Pytanie 2:* Czy zastosowanie potoku wielorodzajowej augmentacji degradacyjnej pozwala uodpornić sieć na badane zakłócenia bez istotnego obniżenia dokładności klasyfikacji na czystych obrazach wzorcowych?
- *Pytanie 3:* Jaki odsetek błędów klasyfikacji na wyizolowanych wycinkach znaków, pozbawionych kontekstu linii tekstu, wynika z~obiektywnej niejednoznaczności morfologicznej par homoglificznych (takich jak „C”/„c”, „O”/„o” czy „0”/„O”)?
- *Pytanie 4:* Czy obserwowane zmiany odporności modelu są powtarzalne i~niezależne od losowej inicjalizacji wag oraz kolejności prezentacji danych (odporność na dobór ziarna, ang. _seed-agnosticism_)?

== Struktura pracy
// [Section Guide]: Provide a concise roadmap of Chapters 1–6 and the back-matter so the reader understands the logical progression from theory and methodology to software implementation and empirical verification. (Already drafted).
Układ niniejszej pracy inżynierskiej obejmuje sześć spójnych rozdziałów:
- *Rozdział 1 (Wstęp)* wprowadza w tematykę rozpoznawania znaków alfanumerycznych, definiuje cel, zakres oraz pytania badawcze realizowanego projektu.
- *Rozdział 2 (Podstawy teoretyczne i~stan wiedzy)* omawia zagadnienia rozpoznawania tekstu, teorię splotowych sieci neuronowych, matematyczne modele degradacji sygnału wizualnego oraz literaturowe metody zwiększania odporności modeli głębokich.
- *Rozdział 3 (Metodyka badań)* precyzuje charakterystykę zbioru danych, potok przygotowania próbek, architekturę sieci AlphanumericCNN, scenariusze symulowanych zakłóceń, strategie treningowe oraz zdefiniowane metryki ewaluacyjne.
- *Rozdział 4 (Implementacja systemu)* dokumentuje architekturę techniczną stworzonego oprogramowania, wykorzystane biblioteki, implementację generatora degradacji, pętli treningowej oraz procedur ewaluacyjnych.
- *Rozdział 5 (Wyniki badań i~analiza)* przedstawia empiryczne rezultaty przeprowadzonych eksperymentów, krzywe odporności, analizę macierzy pomyłek, ocenę par niejednoznacznych, profilowanie sprzętowe oraz dyskusję wyników.
- *Rozdział 6 (Podsumowanie i~wnioski)* zawiera syntetyczne podsumowanie pracy, bezpośrednie odpowiedzi na postawione pytania badawcze, analizę ograniczeń projektu oraz kierunki dalszych badań.
Pracę zamykają wykaz literatury, spisy rysunków i~tabel oraz załączniki dokumentujące konfiguracje eksperymentów.
