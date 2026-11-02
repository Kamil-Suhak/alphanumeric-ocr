#import "../metadata.typ": *

= Podstawy teoretyczne i stan wiedzy

== Rozpoznawanie znaków
Rozpoznawanie znaków i~tekstu z~obrazów (ang. _Optical Character Recognition_, OCR) stanowi jeden z~najdłużej badanych obszarów widzenia komputerowego. Historycznie pierwsze metody bazowały na dopasowywaniu szablonów pikselowych oraz ręcznie definiowanych deskryptorach geometrycznych, takich jak gęstość krawędzi, punkty przecięcia czy momenty obrazu. Podejścia te sprawdzały się w~kontrolowanych warunkach maszynopisania, lecz wykazywały wysoką podatność na zakłócenia, zmienność krojów czcionek oraz naturalną nieregularność pisma odręcznego.

Przełom w~dziedzinie OCR wiąże się z~zastosowaniem sztucznych sieci neuronowych, zapoczątkowanym przez LeCuna i~współpracowników @lecun1998lenet. Architektura LeNet-5 dowiodła, że bezpośrednie przetwarzanie surowej macierzy pikseli za pomocą operacji splotu pozwala na automatyczną hierarchiczną ekstrakcję cech, przewyższając metody oparte na ręcznej inżynierii deskryptorów.

Współczesne systemy przetwarzania dokumentów i~odczytu tekstu w~scenach naturalnych (ang. _Scene Text Recognition_, STR) dzielą się zazwyczaj na dwa współpracujące moduły @ye2015text, @chen2021text:
1. *Detekcję tekstu:* Odpowiedzialną za lokalizację obszarów zawierających inskrypcje oraz wycięcie ich w~postaci wyprostowanych ramek ograniczających (np. algorytmy DBNet czy CRAFT).
2. *Rozpoznawanie znaków lub sekwencji:* Realizujące klasyfikację wyizolowanych wycinków znaków lub transkrypcję całych linii tekstu.
W~zadaniach przemysłowych, takich jak inspekcja numerów seryjnych na liniach produkcyjnych czy weryfikacja oznaczeń komponentów, decydującą rolę odgrywa precyzyjna i~szybka klasyfikacja wyizolowanych znaków alfanumerycznych przy minimalnym narzucie obliczeniowym.

== Klasyfikacja obrazów z wykorzystaniem sieci neuronowych
Klasyfikacja obrazów polega na przypisaniu zadanemu obrazowi wejściowemu jednej z~$C$ zdefiniowanych kategorii. Formalnie zadanie to można przedstawić jako aproksymację funkcji:
$ f_theta : cal(X) -> cal(Y) $
gdzie $cal(X) subset.eq RR^(H times W times C_text("in"))$ jest przestrzenią znormalizowanych obrazów cyfrowych o~wysokości $H$, szerokości $W$ oraz liczbie kanałów $C_text("in")$, zbiór $cal(Y) = {0, 1, dots, C - 1}$ oznacza dyskretny zbiór etykiet klas, a~$theta$ reprezentuje zbiór parametrów uczonych modelu.

W~przypadku modeli głębokich obraz wejściowy przekształcany jest sekwencyjnie przez kolejne warstwy reprezentacji:
$ bold(z) = f_theta (bold(x)) = (f_L compose f_(L-1) compose dots compose f_1)(bold(x)) $
gdzie każda warstwa $f_l$ realizuje parametryczną transformację afiniczną połączoną z~nieliniową funkcją aktywacji. Zdolność sieci do generalizacji zależy zarówno od pojemności reprezentacyjnej architektury, jak i~od zbieżności algorytmu optymalizacyjnego poszukującego minimum funkcji straty na zbiorze treningowym.

== Konwolucyjne sieci neuronowe
Konwolucyjne sieci neuronowe stanowią dominujący paradygmat w~analizie danych wizualnych. Ich kluczową zaletą w~porównaniu z~klasycznymi warstwami w~pełni połączonymi jest zachowanie topologii przestrzennej obrazu oraz współdzielenie wag (_weight sharing_), co drastycznie ogranicza liczbę parametrów modelu i~nadaje cechę ekwiwariancji na translacje.

Typowa architektura CNN składa się z~naprzemiennych bloków splotowych, normalizacyjnych, nieliniowych oraz redukcji wymiarowości, zwieńczonych warstwą klasyfikacyjną.

=== Warstwy konwolucyjne
Warstwa konwolucyjna dokonuje dyskretnego splotu tensora wejściowego $bold(X) in RR^(C_text("in") times H times W)$ z~zestawem $C_text("out")$ filtrów $bold(W) in RR^(C_text("out") times C_text("in") times K times K)$. Wartość pojedynczej mapy cech $bold(Y)_(c, i, j)$ na wyjściu splotu wyraża się wzorem:
$ bold(Y)_(c, i, j) = b_c + sum_(k=0)^(C_text("in") - 1) sum_(u=0)^(K - 1) sum_(v=0)^(K - 1) bold(W)_(c, k, u, v) bold(X)_(k, i + u, j + v) $
gdzie $b_c$ oznacza wektor obciążeń (_bias_), a~$K$ wymiar jądra splotowego (najczęściej $K = 3$). Warstwy splotowe zlokalizowane blisko wejścia sieci ekstrahują elementarne cechy niskopoziomowe (krawędzie, narożniki, gradienty jasności), podczas gdy warstwy głębsze syntetyzują złożone motywy strukturalne i~części składowe znaków.

=== Funkcje aktywacji
Operacje splotu są przekształceniami liniowymi. W~celu umożliwienia sieci aproksymacji nieliniowych powierzchni decyzyjnych po każdej warstwie splotowej aplikuje się nieliniową funkcję aktywacji.

Podstawowym standardem we współczesnych architekturach jest jednostka prostownicza ReLU (ang. _Rectified Linear Unit_):
$ text("ReLU")(z) = max(0, z) $
Funkcja ReLU eliminuje problem zanikania gradientu (ang. _vanishing gradient problem_) dla dodatnich wartości aktywacji, a~jej pochodna jest tania obliczeniowo, co znacząco przyspiesza proces zbieżności uczenia.

=== Normalizacja i agregacja cech
W~celu stabilizacji rozkładu aktywacji wewnątrz głębokiej sieci powszechnie stosuje się normalizację wsadową (ang. _Batch Normalization_, BatchNorm) @ioffe2015batchnorm. Dla minipartii próbek $cal(B) = {x_1, dots, x_m}$ transformacja normalizacyjna dana jest zależnością:
$ hat(x)_i = frac(x_i - mu_cal(B), sqrt(sigma_cal(B)^2 + epsilon)), quad y_i = gamma hat(x)_i + beta $
gdzie $mu_cal(B)$ i~$sigma_cal(B)^2$ są średnią i~wariancją partii, natomiast $gamma$ oraz $beta$ stanowią uczone parametry skali i~przesunięcia. BatchNorm wygładza powierzchnię funkcji straty, co pozwala na stosowanie wyższych współczynników uczenia oraz działa jak delikatny regularyzator.

Agregację cech przestrzennych i~redukcję rozdzielczości map (ang. _downsampling_) realizują warstwy próbkowania, najczęściej w~postaci operacji maksymalnego podpróbkowania (ang. _Max Pooling_):
$ bold(Y)_(c, i, j) = max_(u, v in {0, dots, P-1}) bold(X)_(c, s i + u, s j + v) $
gdzie $P$ określa rozmiar okna (standardowo $2 times 2$), a~$s$ krok próbkowania (_stride_). Max Pooling zwiększa pole recepcyjne kolejnych filtrów oraz zapewnia lokalną niezmienniczość na niewielkie przesunięcia i~odkształcenia znaku.

=== Warstwa klasyfikacyjna
Wyjściowe wielokanałowe mapy cech po ostatnim bloku splotowym są spłaszczane do postaci jednowymiarowego wektora deskryptorów i~przekazywane do warstwy w~pełni połączonej (ang. _Fully Connected_, FC). W~celu redukcji ryzyka przeuczenia stosuje się technikę porzucania wag (ang. _Dropout_) @srivastava2014dropout, która w~czasie treningu losowo zeruje wybrane aktywacje z~prawdopodobieństwem $p$.

Ostateczny wektor logitów $bold(z) in RR^C$ przekształcany jest w~wektor prawdopodobieństw a~posteriori za pomocą funkcji unormowanego wykładnika (ang. _Softmax_):
$ p(y = c bar.v bold(x)) = frac(exp(z_c), sum_(j=0)^(C-1) exp(z_j)) $
gdzie $c in {0, dots, C-1}$ oznacza indeks klasy decyzyjnej.

== Uczenie modeli klasyfikacyjnych
Optymalizacja parametrów sieci polega na minimalizacji funkcji straty wieloklasowej entropii krzyżowej (ang. _Categorical Cross-Entropy Loss_) na zbiorze danych treningowych $cal(D)_text("train")$:
$ cal(L)(theta) = - frac(1, N) sum_(i=1)^N sum_(c=0)^(C-1) y_(i, c) log p(y = c bar.v bold(x)_i; theta) $
gdzie $y_(i, c) in {0, 1}$ reprezentuje binarną etykietę w~kodowaniu _one-hot_.

Do modyfikacji parametrów $theta$ wykorzystuje się stochastyczny spadek wzdłuż gradientu z~wykorzystaniem algorytmu wstecznej propagacji błędu. W~nowoczesnych zastosowaniach powszechnie stosuje się optymalizator AdamW @loshchilov2017adamw, który wprowadza jawne odsprzężenie zaniku wag (_weight decay_) od adaptacyjnych estymat momentów gradientu pierwszego i~drugiego rzędu:
$ theta_(t+1) = theta_t - eta_t (frac(hat(m)_t, sqrt(hat(v)_t) + epsilon) + lambda theta_t) $
Mechanizm ten zapewnia stabilną regularyzację przestrzeni wagowej i~zapobiega eksplozji normy wag w~warunkach intensywnego treningu.

== Odporność modeli na degradację obrazu
Mimo znakomitych wyników osiąganych na nieskażonych zbiorach testowych, konwolucyjne sieci neuronowe cechują się dużą wrażliwością na przesunięcia dystrybucji danych (ang. _out-of-distribution shifts_) @hendrycks2019benchmarking, @dodge2016understanding. Standardowo trenowane filtry splotowe polegają w~znacznym stopniu na wysokoczęstotliwościowych składowych tekstury obrazu. Zjawiska degradacji środowiskowej niszczą te składowe lub wprowadzają zakłócenia utrudniające niezawodną ekstrakcję cech @trivedi2026improving:
1. *Rozmycie optyczne i~ruchowe:* Powstające na skutek błędnego ustawienia ostrości aparatu lub ruchu obiektu względem sensora. Matematycznie modelowane jest jako splot sygnału wejściowego $I(x, y)$ z~dwuwymiarowym jądrem Gaussa $G_sigma$:
   $ G_sigma(x, y) = frac(1, 2 pi sigma^2) exp(- frac(x^2 + y^2, 2 sigma^2)), quad I_text("blur") = (I * G_sigma)(x, y) $
2. *Szum matrycy światłoczułej:* Wynikający z~zakłóceń termicznych i~fluktuacji fotonowych w~słabych warunkach oświetleniowych, aproksymowany jako addytywny szum Gaussa:
   $ I_text("noise")(x, y) = text("clip")(I(x, y) + xi, 0, 1), quad xi tilde.op cal(N)(0, s^2) $
3. *Zniekształcenia perspektywiczne:* Będące konsekwencją rejestracji znaku pod kątem nieprostopadłym do płaszczyzny podłoża, reprezentowane przez transformację rzutową w~jednorodnym układzie współrzędnych:
   $ mat(x'; y'; 1) tilde.op bold(H) mat(x; y; 1), quad bold(H) in RR^(3 times 3) $

Brak odporności na powyższe zakłócenia prowadzi do tzw. katastrofalnego załamania dokładności (_catastrophic collapse_), w~którym model zaczyna generować losowe predykcje nawet przy zaburzeniach słabo zauważalnych dla ludzkiego oka.

== Metody zwiększania odporności modeli
W~literaturze naukowej rozwijane są różnorodne podejścia mające na celu zwiększenie odporności sieci neuronowych na degradację sygnału wejściowego:
- *Modyfikacje architektury:* Wprowadzanie połączeń rezydualnych, mechanizmów uwagi przestrzennej i~kanałowej oraz operacji splotów rozszerzonych (_dilated convolutions_).
- *Trening odporny i~wielozadaniowy:* Równoległe uczenie rekonstrukcji czystego obrazu (autoenkodery odszumiające) lub optymalizacja minimaksowa.
- *Augmentacja danych (Data Augmentation):* Włączanie przekształceń geometrycznych i~fotometrycznych bezpośrednio do potoku trenującego @shorten2019survey.

Wśród wymienionych strategii szczególne znaczenie inżynierskie ma dynamiczna augmentacja degradacyjna w~czasie rzeczywistym (_on-the-fly augmentation_). Podejście to nie zwiększa złożoności obliczeniowej samego modelu w~fazie inferencji, co jest warunkiem kluczowym w~urządzeniach brzegowych, a~jednocześnie wymusza na filtrach splotowych naukę reprezentacji cech niezmienniczych względem zniekształceń.
