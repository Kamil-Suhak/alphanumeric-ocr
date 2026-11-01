// Szablon pracy dyplomowej inżynierskiej AGH (Typst v0.15+)

#let agh_thesis(
  title_pl: "",
  title_en: "",
  author: "",
  album_no: "",
  supervisor: "",
  faculty: "",
  department: "",
  field_of_study: "",
  city: "Kraków",
  year: "2026",
  line_spacing: 1.25,
  font_family: ("Times New Roman", "New Computer Modern"),
  body,
) = {
  // 1. Podstawowe ustawienia dokumentu i strony
  set document(title: title_pl, author: author)
  
  set page(
    paper: "a4",
    margin: (
      inside: 3.0cm, // Margines na oprawę
      outside: 2.0cm,
      top: 2.0cm,
      bottom: 2.0cm,
    ),
    header: context {
      let page_num = counter(page).get().first()
      // Ukryj nagłówek na stronie tytułowej (strona 1)
      if page_num > 1 {
        set text(size: 9pt, fill: rgb("#555555"))
        grid(
          columns: (1fr, auto),
          align(left)[#author --- #title_pl],
          align(right)[#page_num],
        )
        line(length: 100%, stroke: 0.5pt + rgb("#cccccc"))
      }
    },
    footer: none,
  )

  set text(
    font: font_family,
    size: 12pt,
    lang: "pl",
  )

  // Interlinia oraz wcięcie akapitowe
  set par(
    justify: true,
    leading: line_spacing * 0.55em,
    first-line-indent: 0.8cm,
  )

  // 2. Formatowanie podpisów rysunków i tabel (Wytyczne: tabele podpis nad, rysunki pod)
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: image): set figure.caption(position: bottom)
  show figure.caption: c => {
    set text(size: 10.5pt)
    c
  }

  // 3. Hierarchia nagłówków
  set heading(numbering: "1.1.")
  
  show heading: it => {
    set text(weight: "bold")
    if it.level == 1 {
      // Rozdział główny: nowa strona, 14pt bold
      pagebreak(weak: true)
      v(1.5cm)
      text(size: 15pt)[#counter(heading).display() #it.body]
      v(1cm)
    } else if it.level == 2 {
      // Podrozdział: 12.5pt bold
      v(0.8cm)
      text(size: 13pt)[#counter(heading).display() #it.body]
      v(0.4cm)
    } else {
      // Dalsze poziomy
      v(0.5cm)
      text(size: 12pt)[#counter(heading).display() #it.body]
      v(0.3cm)
    }
  }

  // ==========================================
  // STRONA TYTUŁOWA AGH
  // ==========================================
  align(center)[
    #text(size: 14pt, weight: "bold")[AKADEMIA GÓRNICZO-HUTNICZA\ IM. STANISŁAWA STASZICA W KRAKOWIE]
    
    #v(0.4cm)
    #text(size: 12pt, weight: "bold")[#faculty]
    
    #if department != "" [
      #v(0.2cm)
      #text(size: 11pt)[#department]
    ]

    #v(3.0cm)
    #text(size: 12pt)[Kierunek: #field_of_study]

    #v(1.0cm)
    #text(size: 18pt, weight: "bold")[PRACA INŻYNIERSKA]

    #v(1.5cm)
    #text(size: 14pt, weight: "bold")[#title_pl]

    #v(0.4cm)
    #text(size: 12pt, style: "italic")[#title_en]

    #v(2.5cm)
    #align(right)[
      #block(width: 60%)[
        #set align(left)
        #grid(
          columns: (auto, auto),
          gutter: 0.8em,
          [Autor:], [*#author*],
          [Nr albumu:], [#album_no],
          [Promotor:], [*#supervisor*],
        )
      ]
    ]

    #v(1fr)
    #text(size: 11pt)[#city, #year]
  ]

  // Reset licznika stron po stronie tytułowej
  pagebreak()
  counter(page).update(1)

  // Treść właściwa
  body
}
