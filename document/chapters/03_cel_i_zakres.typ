#import "../metadata.typ": *

= Cel i zakres pracy

== Formalna definicja zadania klasyfikacji
Celem badawczym jest ocena podatności kompaktowego klasyfikatora splotowego na degradacje wizualne oraz zbadanie skuteczności metody dynamicznej augmentacji w przeciwdziałaniu załamaniu dokładności. 

Zadanie formalizuje się jako odwzorowanie:
$ f_theta : cal(X) -> cal(Y) $
gdzie $cal(X) subset.eq RR^(1 times 32 times 32)$ stanowi przestrzeń znormalizowanych obrazów w skali szarości, a $cal(Y) = {0, 1, dots, 61}$ odpowiada 62 dyskretnym klasom alfanumerycznym.

== Przygotowanie danych i dopełnienie zerami (Zero-Padding)
Oryginalne próbki EMNIST ByClass mają format $28 times 28$ pikseli i wymagają korekty orientacji (transpozycji osi ze względu na wewnętrzny format zapisu bazy NIST).

Zamiast powszechnie stosowanego przeskalowywania biliniowego (`Resize((32, 32))`), w projekcie zastosowano symetryczne *dopełnienie zerami o szerokości 2 pikseli* (`Pad(padding=2, fill=0)`):
- Eliminuje to artefakty rozmycia interpolacyjnego i zachowuje 100% ostrości surowych pociągnięć pióra.
- Odtwarza klasyczne kadrowanie LeNet-5, pozostawiając naturalny margines tła wokół znaku.

Współczynniki normalizacji tensora obliczono empirycznie na 90% podzbioru treningowego:
$ mu = 0.1331, quad sigma = 0.2870 $
(Zapobiegając bezkrytycznemu kopiowaniu stałych ze standardowego MNIST: $mu=0.1307, sigma=0.3081$).

== Izolacja zbioru testowego i trwałe manifesty podziału
Aby wykluczyć jakiekolwiek zjawisko wycieku danych (ang. _data leakage_), zbiór EMNIST podzielono rygorystycznie i utrwalono na dysku w plikach CSV:
- *Zbiór testowy:* Oficjalny podzbiór 116 323 próbek EMNIST pozostaje całkowicie nienaruszony i służy wyłącznie do końcowej ewaluacji odporności.
- *Zbiór treningowy (90%):* 628 139 próbek (`experiments/manifests/train_indices.csv`).
- *Zbiór walidacyjny (10%):* 69 794 próbek (`experiments/manifests/val_indices.csv`).

Podział ten jest w 100% deterministyczny i odtwarzalny na dowolnej maszynie obliczeniowej.

== Analiza wewnętrznej niejednoznaczności geometrycznej (Ambiguity Pairs)
W przypadku izolowanych wycinków o rozdzielczości $32 times 32$ piksele, bez kontekstu linii tekstu i wysokości małych liter (ang. _x-height_), część znaków jest geometrycznie tożsama. Zidentyfikowano 15 par wewnętrznie niejednoznacznych:
- Litery homomorficzne: $(C, c)$, $(J, j)$, $(K, k)$, $(O, o)$, $(P, p)$, $(S, s)$, $(U, u)$, $(V, v)$, $(W, w)$, $(X, x)$, $(Y, y)$, $(Z, z)$.
- Pary cyfra--litera: $(0, O)$, $(1, l)$, $(1, I)$.

Nawet optymalny klasyfikator Bayesa ponosi na tych parach błąd rzędu 3--4%. Z tego powodu w metrykach wprowadzono *dokładność bez rozróżniania wielkości liter* (ang. _case-insensitive accuracy_), weryfikującą faktyczną jakość rozpoznawania kształtu znaku.

#block(fill: rgb("#f5f5f7"), inset: 1em, radius: 4pt)[
  #text(weight: "bold")[Wytyczne redakcyjne do rozwinięcia rozdziału:]
  - [ ] Wstawić tabelę z pełną listą 15 par niejednoznacznych wraz z ich częstościami występowania w ByClass.
  - [ ] Dodać diagram potoku wczytywania danych: Transpose -> Pad(2) -> ToTensor -> Normalize.
]
