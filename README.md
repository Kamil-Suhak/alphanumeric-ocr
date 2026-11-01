# Praca Inżynierska: Badanie odporności kompaktowej sieci CNN na degradacje środowiskowe w zadaniu klasyfikacji znaków alfanumerycznych

**Autor:** Kamil Suhak  
**Uczelnia:** Akademia Górniczo-Hutnicza im. Stanisława Staszica w Krakowie  
**Wydział:** Wydział Elektrotechniki, Automatyki, Informatyki i Inżynierii Biomedycznej (WEAIiIB)  
**Kierunek:** Informatyka  
**Rok:** 2026  

---

## O projekcie

Niniejsze repozytorium integruje w strukturze monorepozytorium:
1. **Pracę inżynierską w formacie Typst (`document/`):** Zgodną z wytycznymi edytorskimi AGH (A4, margines na oprawę 3 cm, interlinia 1.25, automatyczna strona tytułowa, spisy i bibliografia Hayagriva YAML).
2. **Moduł badań uczenia maszynowego (`experiments/`):** Kompaktowy klasyfikator PyTorch (`AlphanumericCNN`), silnik syntetycznych degradacji ciągłych (rozmycie, szum, deformacje perspektywiczne) oraz rygorystyczny zestaw testów odporności na zbiorze EMNIST ByClass (62 klasy).
3. **Sprawozdania dla promotora (`milestones/`):** Niezależne przestrzenie robocze Typst generujące raporty z kolejnych etapów prac.

---

## Architektura katalogów

```text
.
├── document/               # Główny dokument pracy inżynierskiej (Typst)
│   ├── main.typ            # Główny plik kompilacji
│   ├── metadata.typ        # Metadane (autor, promotor, wydział, parametry)
│   ├── template/           # Szablon pracy dyplomowej AGH
│   ├── chapters/           # Rozdziały (01_wstep ... 06_wnioski)
│   └── references/         # Biblioteka Hayagriva YAML (library.yaml)
│
├── experiments/            # Moduł uczenia maszynowego i eksperymentów (PyTorch)
│   ├── configs/            # Pliki konfiguracyjne modeli (baseline.yaml, robust.yaml)
│   ├── manifests/          # Trwałe manifesty podziału zbioru (train/val_indices.csv)
│   ├── src/                # Kod źródłowy (architektura, transformacje, trening, metryki)
│   ├── scripts/            # Skrypty wykonawcze (trening, ewaluacja, profilowanie)
│   └── outputs/            # Wyniki uporządkowane semantycznie i numerowane
│       ├── runs/           # Modele i krzywe (EXP-001_baseline, EXP-002_robust)
│       ├── sweeps/         # Krzywe i dane odporności (blur, noise, perspective)
│       ├── diagnostics/    # Wizualizacje próbek i weryfikacja orientacji
│       └── tables/         # Zestawienia metryk w formacie JSON/CSV
│
├── milestones/             # Sprawozdania cząstkowe dla promotora
│   ├── milestone1/         # Raport z Etapu 1 (PDF, Typst, dokumenty źródłowe)
│   └── milestone2/         # Szablon pod kolejny etap badań
│
├── data/                   # Dane źródłowe (wykluczone z Gita)
│   └── raw/emnist/         # Pliki binarne EMNIST ByClass
│
├── AGENTS.md               # Protokół operacyjny dla asystentów AI
├── WORKFLOW.md             # Przewodnik deweloperski i instrukcja pracy
└── pyproject.toml          # Definicja projektu Python i zależności (uv)
```

---

## Szybki start

### Podgląd pracy w czasie rzeczywistym (Typst)
1. Zainstaluj rozszerzenie **Tinymist Typst** w VS Code.
2. Otwórz `document/main.typ` i naciśnij `Ctrl + K`, a następnie `V`.
3. Kompilacja do pliku PDF:
   ```bash
   typst compile --root . document/main.typ "Praca_Inzynierska_Kamil_Suhak.pdf"
   ```

### Środowisko Python (zarządzane przez `uv`)
```bash
# Synchronizacja środowiska
uv sync

# Przykładowe uruchomienie ewaluacji
uv run python experiments/scripts/evaluate.py
```
