# Handcrafted LaTeX documents

This directory contains all hand-maintained LaTeX source for the printable CV
and résumé.

## Status

There are currently two LaTeX paths in this repository:

| Path | Status | Output |
|---|---|---|
| `latex/*.tex` | Production source for the PDFs published by CI | `latex/main.pdf`, `latex/public.pdf`, `latex/one-page-resume.pdf` |
| `templates/latex/*.erb` | Experimental, generated from `data/*.yml` and `personal.bib` | `build/cv.tex`, `build/cv.pdf` |

The generated document is useful as a scaffold, but it does not replace this
directory yet. Changes to YAML do not automatically update the handcrafted
documents, so content that must appear in a published PDF may need a matching
edit here.

`personal.bib` remains at the repository root because it is shared by the YAML
renderer and the optional BibTeX helpers in this directory.

## Entry points

- `main.tex` builds the full CV. Referee phone numbers are redacted by default.
- `public.tex` wraps `main.tex` and replaces the references section with
  “References available upon request.” This becomes the primary public
  download.
- `one-page-resume.tex` builds the standalone résumé.
- `unredacted.tex` wraps `main.tex` and includes referee phone numbers. Its PDF
  is private, gitignored, and never built or deployed by CI.
- The numbered files and named section files are fragments included by
  `main.tex`; they are not standalone documents.

## Build

Run builds from the repository root so the Makefile uses the expected engine
and options:

```sh
make pdf          # public CV, full redacted CV, and one-page résumé
make unredacted   # private latex/unredacted.pdf
make check-latex  # check for latexmk and lualatex
```

The build requires `latexmk`, LuaLaTeX, `moderncv`, `fontspec`, and Source Sans
3 (or the older Source Sans Pro name). Generated PDFs and LaTeX intermediates
remain inside this directory and are ignored by Git.

To exercise the generated YAML path instead, use `make tex` or `make cv-pdf`;
those commands write under `build/`.

## Privacy

Do not publish `latex/unredacted.pdf`. It includes third-party contact
information from `references.tex`. Both CV PDFs deployed by CI redact those
phone numbers: `public.pdf` omits the referee list, and `main.pdf` suppresses
the numbers through `\refphone`.
