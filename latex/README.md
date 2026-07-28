# latex/ — the handcrafted moderncv sources

Everything in this folder is **hand-authored LaTeX**. It is the source of
truth for the three PDFs the site publishes, and it is *not* generated from
`data/*.yml`. Editing YAML does not change these PDFs; editing these files
does not change the Markdown/HTML web CV. Keeping both in sync is currently a
manual job — see [Status](#status) below.

## The three documents

| Root file             | Builds        | Published as                                    |
|-----------------------|---------------|-------------------------------------------------|
| `public.tex`          | `public.pdf`  | `michael-ball-cv.pdf` at the site root — the public download linked from mball.co/cv |
| `main.tex`            | `main.pdf`    | `cv/cv-full.pdf` — same document *with* real referee contact details |
| `one-page-resume.tex` | `one-page-resume.pdf` | `cv/resume.pdf` |

`public.tex` is a four-line wrapper: it sets `\def\publicversion{1}` and then
`\input{main}`. `main.tex` branches on that flag to pull in
`references-public.tex` ("References available upon request") instead of
`references.tex` (names, emails, phone numbers). **That branch is the only
thing keeping the referees' contact details off the public web** — if you add
another document root, make sure it goes through the same switch.

`one-page-resume.tex` is fully self-contained: it shares the moderncv preamble
conventions with `main.tex` but has its own inline content and does not
`\input{}` any section file. Content added to a section file will *not* show
up in the résumé.

## Structure

`main.tex` holds the preamble (document class, colors, fonts, personal data,
author-name and `\snap`-style macros) and then `\input{}`s each section in
render order:

```
main.tex
├── 1-education.tex
├── 2-jobs.tex
├── 4-teaching.tex
├── 5-awards.tex            (awards + grants)
├── research-interests.tex
├── students.tex            (students supervised)
├── 6-service.tex
├── 6-publications/1-conferences.tex   (\section{Writing & Publications} + invited talks, papers, presentations)
├── 6-publications/2-other-writing.tex (\subsection continuing the above section)
├── 6-publications/3-press.tex         (\section{Media and News})
├── 3-projects.tex
├── 7-personal.tex
└── references.tex  ⟷  references-public.tex   (chosen by \publicversion)
```

Two things about that list are easy to trip over:

- **The numeric filename prefixes no longer match the render order.** They're
  historical. `main.tex` decides the order; the numbers don't. Sections render
  4-teaching → 5-awards → research-interests → students → 6-service, and
  3-projects lands near the end.
- **`6-publications/` is one `\section` split across three files.**
  `1-conferences.tex` opens `\section{Writing & Publications}`;
  `2-other-writing.tex` starts with a bare `\subsection{}` and only makes
  sense `\input{}` immediately after it. `3-press.tex` opens its own
  `\section{Media and News}`.

Section files are plain moderncv content — `\cventry`, `\cvitem`,
`\cvlistdoubleitem`, `\cvline`, `itemize`/`etaremune` lists, and `\vspace`
tuning. No shared style file: spacing is adjusted inline per section.

### Macros defined in `main.tex`

Section files rely on these, so they can't be compiled standalone:

- `\me`, `\firstme` — bolded self-citation (`\textbf{Ball, Michael}`)
- `\dan`, `\lauren`, `\mary`, `\pamela`, `\tiffany`, `\bh` — frequent coauthors
- `\snap`, `\snapcon`, `\snapshot` — italicize the `!` in *Snap!*
- `\bjc` — "The Beauty and Joy of Computing"

### Preamble notes worth keeping

Both roots carry two workarounds that look removable but aren't:

- A `\@ifundefined{quotation}{\newenvironment{quotation}{}{}}{}` shim. TeX Live
  2024+ made moderncv's `\begin{document}` hook error with "Environment
  'quotation' undefined"; pre-defining the environment lets moderncv's
  `\renewenvironment` succeed.
- `\IfFontExistsTF{Source Sans 3}` with a `Source Sans Pro` fallback — TeX
  Live renamed the font, and older installs still ship the old name.

`one-page-resume.tex` additionally warns against loading `fontawesome5`:
moderncv loads `fontawesome6`, and the two conflict.

## Building

Because `main.tex` `\input{}`s siblings by bare name, **latexmk must run with
this directory as its working directory**. The PDFs are written here too.

```sh
make pdf                  # from the repo root — builds all three PDFs into latex/
cd latex && latexmk -lualatex main.tex     # one document by hand
make clean                # latexmk -C in latex/, plus rm -rf build/
```

`lualatex` is required, not `pdflatex`: the preamble uses `fontspec` (for
Source Sans 3) and `\DocumentMetadata` for PDF/UA-2 + PDF/A-4f tagging.
Needed packages: `moderncv`, `fontspec`, `geometry`, `etaremune`, `nth`,
`import`, `xcolor`, `xspace`, plus the `sourcesanspro` fonts. A recent LaTeX
kernel matters — `\DocumentMetadata` with `tagging=on` needs 2024-or-newer
(TeX Live 2023 will fail on it).

CI builds all three via `xu-cheng/latex-action@v3` with
`working_directory: latex`, in both `.github/workflows/build-cv.yml` (every
PR) and `deploy.yml` (pushes to `main`, which also pushes the PDFs to the site
repo).

## Relationship to the YAML pipeline

The repo has two parallel LaTeX paths, and they don't talk to each other:

1. **This folder** — handcrafted, drives the published PDFs.
2. **`templates/latex/cv.tex.erb`** — a regenerable scaffold rendered from
   `data/*.yml` + `personal.bib` (`make tex` → `build/cv.tex`,
   `make cv-pdf` → `build/cv.pdf`). It mirrors this preamble and emits
   `\cventry`/`\cvline` for every YAML section. It is a *candidate
   replacement*, not part of any build or deploy.
   `make pubs-tex` renders just the publications subsection, intended as a
   drop-in for `6-publications/1-conferences.tex` if you want to migrate one
   section at a time.

So a content change made only in `data/*.yml` reaches mball.co/cv but **not**
the PDFs, and vice versa. Until the scaffold is adopted, new entries need to
be added in both places.

`personal.bib` deliberately stays at the repo root: the Ruby renderer
(`lib/cv/bib.rb`) reads it, and it is not LaTeX-specific. Nothing here
currently `\cite{}`s it.

## Status

Verified 2026-07-28:

- All three documents build under lualatex — `main`/`public` at 18 pages, the
  résumé at 1 — with only cosmetic under/overfull-box warnings. CI builds all
  three on every PR and deploys them from `main`.
- Every `\input{}` in `main.tex` resolves to a file in this folder, and the
  `\publicversion` switch works: `main.pdf` carries the referees' contact
  details, `public.pdf` carries only the placeholder.
- **`bibtex_preamble.tex` and `bibtex_post.tex` are inactive.** Both are
  `\input{}` only from commented-out lines in `main.tex`; they were an
  abandoned attempt to generate the publication list via BibTeX/`multibib`
  instead of typing it out. `bibtex_post.tex` also still says
  `\bibliography{personal}`, which would need to become
  `\bibliography{../personal}` now that the sources live one level down.
  Kept for reference — delete them if you're sure the BibTeX route is dead.
- `profile_pic.png` (repo root) is referenced by nothing. moderncv would use
  it via `\photo{}`, but no document does. It's a 1.8 MB file; consider
  removing it.
- Content drift between these files and `data/*.yml` is *not* checked by
  anything. `TODO.md` tracks the known content and formatting gaps.
