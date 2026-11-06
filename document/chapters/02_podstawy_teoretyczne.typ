#import "../metadata.typ": *

= Podstawy teoretyczne i stan wiedzy

== Optyczne rozpoznawanie znaków alfanumerycznych
// [Wskazówki autorskie]: Wprowadzić w zagadnienie optycznego rozpoznawania znaków (OCR) i przeciwstawić złożone, wieloetapowe potoki przetwarzania tekstu w scenach naturalnych (detekcja tekstu, segmentacja linii, sekwencyjna dekodacja CRNN/CTC) zadaniu klasyfikacji pojedynczych, wyizolowanych znaków na urządzeniach brzegowych. Przedstawić powody, dla których zakłócenia środowiskowe na fotografiach przemysłowych i mobilnych zawodzą klasyczne metody progowania czy dopasowywania wzorców, co uzasadnia konieczność uczenia przestrzennych reprezentacji cech.
// Rekomendowana literatura: @ye2015text, @chen2021text, @du2013automatic, @campos2009chars74k

== Sformułowanie problemu klasyfikacji obrazów
// [Wskazówki autorskie]: Formalnie zdefiniować zagadnienie wieloklasowej klasyfikacji obrazów monochromatycznych jako uczenie parametrycznego odwzorowania $f_theta: RR^(1 times H times W) -> Delta^(K-1)$ z unormowanej siatki pikseli w dyskretny sympleks prawdopodobieństwa dla $K = 62$ klas alfanumerycznych. Zwięźle wykazać, dlaczego spłaszczenie dwuwymiarowego obrazu do wektora jednowymiarowego w klasycznych perceptronach wielowarstwowych (MLP) niszczy lokalną topologię przestrzenną i pozbawia model niezmienniczości translacyjnej.
// Rekomendowana literatura: @goodfellow2016deep, @lecun1998lenet

== Konwolucyjne sieci neuronowe
// [Wskazówki autorskie]: Przedstawić zwięzłe wprowadzenie architektoniczne do hierarchicznej ekstrakcji cech w sieciach splotowych, omawiając, w jaki sposób kolejne poziomy przetwarzania przechodzą od prostych detektorów krawędzi i kresek do złożonych deskryptorów morfologicznych glifów. Zachować zwięzły charakter wprowadzenia (1–2 akapity) przed szczegółowym omówieniem czterech warstw składowych w kolejnych podrozdziałach.
// Rekomendowana literatura: @lecun1998lenet, @goodfellow2016deep

=== Warstwy konwolucyjne
// [Wskazówki autorskie]: Zaprezentować formalizm matematyczny dyskretnej operacji splotu dwuwymiarowego (korelacji wzajemnej), pojęcie lokalnego pola recepcyjnego, współdzielenia wag oraz dopełniania brzegów zerami (ang. zero-padding) w celu zachowania wymiarów przestrzennych. Wyjaśnić, dlaczego zastosowanie małych jąder splotowych $3 times 3$ umożliwia precyzyjną detekcję nachylenia i krzywizny linii przy zachowaniu minimalnej liczby parametrów.
// Rekomendowana literatura: @lecun1998lenet, @goodfellow2016deep

=== Funkcje aktywacji
// [Wskazówki autorskie]: Uzasadnić konieczność wprowadzania nieliniowych funkcji aktywacji zapobiegających degradacji wielowarstwowej sieci do pojedynczej transformacji afinicznej. Zdefiniować funkcję ReLU ($op("ReLU")(z) = max(0, z)$), wskazać jej efektywność obliczeniową i nienasycający się gradient dla wartości dodatnich w porównaniu z funkcjami sigmoidalnymi/tanh oraz wspomnieć o zjawisku obumierania neuronów (ang. dying ReLU).
// Rekomendowana literatura: @he2015delving, @goodfellow2016deep

=== Normalizacja i agregacja cech
// [Wskazówki autorskie]: Szczegółowo omówić normalizację wsadową (ang. Batch Normalization), polegającą na standaryzacji aktywacji kanałów w obrębie miniwsadu (ang. mini-batch) z wykorzystaniem parametrów afinicznych $gamma$ i $beta$, oraz redukcję wymiarowości za pomocą warstwy Max Pooling ($2 times 2$). Wyjaśnić, jak Batch Normalization stabilizuje dynamikę gradientu i pełni rolę regularyzatora, podczas gdy Max Pooling redukuje wymiary map cech i zapewnia lokalną niezmienniczość względem przesunięć.
// Rekomendowana literatura: @ioffe2015batchnorm, @lecun1998lenet, @goodfellow2016deep

=== Warstwa klasyfikacyjna
// [Wskazówki autorskie]: Opisać przejście z trójwymiarowych map cech splotowych do gęstej głowicy klasyfikacyjnej poprzez spłaszczenie tensora (ang. flattening), projekcje w warstwach w pełni połączonych (ang. dense/linear), regularyzację techniką Dropout oraz wyjściową transformację Softmax. Wyjaśnić, jak losowe zerowanie neuronów z prawdopodobieństwem $p$ w trakcie uczenia eliminuje wzajemne współuzależnienia cech (ang. co-adaptation).
// Rekomendowana literatura: @srivastava2014dropout, @goodfellow2016deep

== Uczenie modeli klasyfikacyjnych
// [Wskazówki autorskie]: Sformułować funkcję straty entropii krzyżowej (ang. categorical cross-entropy) oraz opisać procedurę optymalizacji wag za pomocą propagacji wstecznej i stochastycznego spadku wzdłuż gradientu z adaptacyjną estymacją momentów. Zestawić tradycyjną regularyzację $L_2$ z rozprzężonym zanikaniem wag (ang. decoupled weight decay) w optymalizatorze AdamW oraz uzasadnić kryterium wyboru wag punktu kontrolnego na podstawie minimum straty walidacyjnej.
// Rekomendowana literatura: @goodfellow2016deep, @kingma2014adam, @loshchilov2017adamw, @he2015delving

== Odporność modeli na degradację obrazu
// [Wskazówki autorskie]: Zanalizować przyczyny gwałtownego załamania skuteczności standardowych sieci CNN, uczonych wyłącznie na czystych zbiorach referencyjnych, w warunkach przesunięcia dystrybucji danych (rozmycie optyczne, szum sensora CMOS, dystorsje rzutowe). Omówić mechanizmy częstotliwościowe i przestrzenne stojące za tą wrażliwością – w szczególności wpływ wysokoczęstotliwościowego szumu zaburzającego początkowe filtry krawędziowe oraz dolnoprzepustowego rozmycia niszczącego kontury kresek.
// Rekomendowana literatura: @hendrycks2019benchmarking, @dodge2016understanding, @vasiljevic2016examining, @gonzalez2018digital

== Metody zwiększania odporności modeli
// [Wskazówki autorskie]: Dokonać przeglądu metod uodparniania modeli znanych z literatury, porównując wstępne przetwarzanie i odszumianie obrazu podczas inferencji z dynamiczną augmentacją degradacyjną stosowaną na etapie uczenia. Uzasadnić przewagę augmentacji w systemach wbudowanych OCR: przenosi ona cały narzut obliczeniowy na fazę uczenia offline, nie wprowadzając dodatkowego opóźnienia w czasie rzeczywistej inferencji.
// Rekomendowana literatura: @shorten2019survey, @hendrycks2019benchmarking, @vasiljevic2016examining, @trivedi2026improving
