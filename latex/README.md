# LaTeX documents

## Status

**Only `one-page-resume.tex` is live.** Every other `.tex` file here is
**retired** — each one carries a `% RETIRED` header on line 1. They are kept
for reference (the original hand-written wording is often longer than what the
YAML carries), but they no longer feed any published PDF. Editing them changes
nothing.

| Path | Status | Output |
|---|---|---|
| `templates/latex/*.erb` + `data/*.yml` | Source for the published CV PDFs | `build/cv-full.pdf`, `build/cv-public.pdf` |
| `latex/one-page-resume.tex` | Live, hand-written — no YAML source | `latex/one-page-resume.pdf` |
| everything else in `latex/` | Retired; reference only | — |

To change the CV, edit `data/*.yml`. See the repository
[README](../README.md#the-latex--pdf-path).

`personal.bib` lives at the repository root because it is shared by the
Markdown and LaTeX renderers.

## Entry points

The generated document body is `build/cv.tex`, with three wrappers that
`\input` it:

- `build/cv-full.tex` — the full CV. Referee phone numbers are redacted by
  default via `\refphone`.
- `build/cv-public.tex` — defines `\publicversion`, which replaces the
  references section with “References available upon request.” This is the
  primary public download.
- `build/cv-unredacted.tex` — defines `\unredacted` and includes referee phone
  numbers. Its PDF is private, gitignored, and never built or deployed by CI.
- `latex/one-page-resume.tex` builds the standalone résumé.

## Build

Run builds from the repository root so the Makefile uses the expected engine
and options:

```sh
make pdf          # public CV, full redacted CV, and one-page résumé
make unredacted   # private build/cv-unredacted.pdf
make check-latex  # check for latexmk and lualatex
```

The build requires `latexmk`, LuaLaTeX, `moderncv`, `fontspec`, and Source Sans
3 (or the older Source Sans Pro name). Generated PDFs and LaTeX intermediates
remain inside this directory and are ignored by Git.

`make tex` renders the LaTeX without compiling it.

## Privacy

Do not publish `build/cv-unredacted.pdf`. It includes third-party contact
information from `data/references.yml`. Both CV PDFs deployed by CI redact
those phone numbers: `cv-public.pdf` omits the referee list entirely, and
`cv-full.pdf` suppresses the numbers through `\refphone`.
