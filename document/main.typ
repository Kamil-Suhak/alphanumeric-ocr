#import "metadata.typ": *
#import "template/agh_thesis.typ": agh_thesis

#show: agh_thesis.with(
  title_pl: title_pl,
  title_en: title_en,
  author: author,
  album_no: album_no,
  supervisor: supervisor,
  faculty: faculty,
  department: department,
  field_of_study: field_of_study,
  city: city,
  year: year,
  line_spacing: line_spacing,
  font_family: font_family,
)

// ==========================================
// SPISY TREŚCI, RYSUNKÓW I TABEL
// ==========================================
#outline(
  title: [Spis treści],
  depth: 3,
  indent: auto,
)

#v(1cm)
#outline(
  title: [Spis rysunków],
  target: figure.where(kind: image),
)

#v(1cm)
#outline(
  title: [Spis tabel],
  target: figure.where(kind: table),
)

// ==========================================
// ROZDZIAŁY PRACY
// ==========================================
#include "chapters/01_wstep.typ"
#include "chapters/02_teoria_i_literatura.typ"
#include "chapters/03_cel_i_zakres.typ"
#include "chapters/04_metodyka_i_architektura.typ"
#include "chapters/05_wyniki_eksperymentow.typ"
#include "chapters/06_wnioski_i_rozwoj.typ"

// ==========================================
// BIBLIOGRAFIA (Hayagriva YAML)
// ==========================================
#pagebreak()
#bibliography(
  "references/library.yaml",
  style: "ieee",
  title: "Bibliografia",
)
