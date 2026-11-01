#import "../metadata.typ": *

= Wstęp

== Motywacja i kontekst badawczy
Rozpoznawanie tekstu i pojedynczych znaków alfanumerycznych (ang. _Optical Character Recognition_, OCR) stanowi jeden z fundamentalnych problemów widzenia komputerowego o szerokim spektrum zastosowań przemysłowych --- od automatyzacji procesów logistycznych, przez digitalizację dokumentacji archiwalnej, aż po odczyt numerów seryjnych komponentów w warunkach polowych. 

Współczesne systemy OCR, oparte na głębokich sieciach splotowych (CNN), osiągają znakomitą dokładność na danych laboratoryjnych i zdigitalizowanych w wysokiej rozdzielczości. W praktycznych zastosowaniach mobilnych oraz wbudowanych (ang. _edge AI_) jakość rejestrowanych obrazów ulega jednak drastycznej degradacji w wyniku:
- niestabilności ręki operatora lub wibracji podłoża (rozmycie ruchowe i optyczne),
- ograniczonej dynamiki matrycy aparatu w słabym oświetleniu (szum matrycy CMOS),
- rejestracji etykiet pod ostrym kątem (zniekształcenia perspektywiczne i rzuty ukośne).

Modele uczone wyłącznie na idealnych, syntetycznych lub laboratoryjnych danych wykazują drastyczny spadek skuteczności pod wpływem nawet subtelnych zaburzeń sygnału wejściowego @hendrycks2019benchmarking.

== Pytanie badawcze i hipotezy
Niniejsza praca podejmuje problem klasyfikacji izolowanych 62 klas znaków alfanumerycznych (cyfry 0--9, wielkie litery A--Z oraz małe litery a--z) w rozdzielczości $32 times 32$ piksele.

Główne pytanie badawcze sformułowano następująco:
#align(center)[
  #block(width: 85%, inset: 1em, stroke: 0.5pt + rgb("#bbbbbb"), radius: 4pt)[
    #set text(style: "italic")
    W jaki sposób wprowadzenie losowych, syntetycznych degradacji środowiskowych do procesu uczenia kompaktowej sieci konwolucyjnej wpływa na jej odporność i dynamikę załamania dokładności w zadaniu klasyfikacji znaków alfanumerycznych?
  ]
]

Na tej podstawie postawiono następujące hipotezy badawcze:
1. *Wrażliwość modelu bazowego (Model A - Czysty):* Model uczony wyłącznie na czystych danych wejściowych osiąga wysoką dokładność na nieskażonym zbiorze testowym, lecz ulega gwałtownemu załamaniu (ang. _catastrophic collapse_) przy wzroście parametrów rozmycia, szumu i deformacji perspektywicznych.
2. *Wzrost odporności poprzez augmentację degradacyjną (Model B - Odporny):* Włączenie syntetycznych zniekształceń w potok trenujący przesuwa próg odporności sieci, znacząco podnosząc dokładność klasyfikacji w warunkach zakłóceń, przy marginalnym koszcie dokładności na danych nieskażonych.
3. *Agnostycyzm względem ziarna losowości:* Obserwowany wzrost odporności jest właściwością regularną i powtarzalną w poprzek wielu losowych inicjalizacji (ang. _seed-agnostic_), a nie artefaktem pojedynczego punktu w przestrzeni wag.
4. *Bariera niejednoznaczności wewnętrznej:* Ze względu na brak linii bazowej i kontekstu wysokości pisma, około 3--4% pomyłek klasyfikacji na izolowanych wycinkach wynika z nieodróżnialności geometrycznej 15 par wielkich i małych znaków (np. $C/c$, $O/o$, $S/s$, $0/O$).

== Struktura pracy
Układ niniejszej pracy przedstawia się następująco:
- *Rozdział 2* stanowi przegląd literatury naukowej, omawiając ewolucję architektur CNN, zbiory danych EMNIST i Chars74k oraz formalne modele degradacji obrazu.
- *Rozdział 3* formalizuje cel, zakres pracy oraz rygorystyczny podział danych wraz z izolacją zbioru testowego.
- *Rozdział 4* opisuje architekturę sieci AlphanumericCNN, generator syntetycznych degradacji oraz protokół trenowania.
- *Rozdział 5* prezentuje empiryczne wyniki eksperymentów, krzywe załamania odporności, profilowanie sprzętowe oraz analizę macierzy pomyłek.
- *Rozdział 6* zawiera podsumowanie wniosków, analizę ograniczeń oraz plan dalszych badań.
