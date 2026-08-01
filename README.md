# cv

Source for Michael Ball's CV. **`data/*.yml` + `personal.bib` are the single
source of truth** — every output below is generated from them:

- **Markdown** (`build/cv.md`) — drops into the Jekyll site at
  [cycomachead.github.io/cv](https://cycomachead.github.io/cv/)
- **HTML preview** (`build/cv.html`) — kramdown-rendered standalone for local
  review; mirrors what the deployed Jekyll site will produce
- **LaTeX → PDF** (`build/cv-full.pdf`, `build/cv-public.pdf`) — moderncv
  documents rendered from `templates/latex/cv.tex.erb`

The one exception is `latex/one-page-resume.tex`, a genuinely different
document with no YAML source, which stays hand-written. Everything else under
[`latex/`](latex/README.md) is **retired** — those files are kept for
reference only and no longer feed any published PDF. Editing them changes
nothing; edit `data/*.yml` instead.

## Quick start

```sh
make            # cv.md, cv.html, and the published PDFs
make preview    # build cv.html and serve on http://localhost:8000
make test       # run minitest
make help       # list every target
```

Ruby ≥ 3.0 is required. Run `bundle install` once for the two non-stdlib
gems we depend on:

- [`bibtex-ruby`](https://github.com/inukshuk/bibtex-ruby) — parses
  `personal.bib` (handles `@string`, brace nesting, name parsing).
- [`kramdown`](https://kramdown.gettalong.org/) — same Markdown engine
  Jekyll uses, so the local preview matches the deployed site.

PDF builds need `lualatex` (`latexmk -lualatex`) and the
`moderncv` / `fontspec` packages with Source Sans Pro available.

## Authoring

All content lives in `data/*.yml`. Each file is loaded by name (`data.basics`,
`data.education`, `data.publications`, …) and consumed by both
`templates/markdown/cv.md.erb` (web) and `templates/latex/cv.tex.erb` (PDF).
One edit updates every output.

- **`basics.yml`** — name, title, contact, profile links (faculty page,
  GitHub, DBLP, ORCID, LinkedIn, Snap!), plus four reusable bios under
  `bio:` in Markdown. Two fields are output-specific by design: `phone` is
  rendered on the PDF only (the web CV never prints a number), and `pdf_title`
  sets the PDF masthead independently of the web CV's subtitle. Of the
  profile links, only GitHub and ORCID reach the PDF — moderncv has no
  `\social` type for the faculty page, DBLP, or Snap!, and LinkedIn is
  web-only by choice. The bios are:
  - `oneline` — one sentence, no links (Twitter / signatures)
  - `short`   — 2–3 sentences with a couple of links (top of the web CV)
  - `medium`  — paragraph (talk intros, grant applications)
  - `long`    — multi-paragraph narrative

- **Add a publication**: edit `data/publications.yml`. Items are one of:
  - `{ bib: <key>, kind?: ..., venue_override?: ..., url?: ... }` — pulls
    authors/title/venue/year from `personal.bib`
  - `{ authors: [...], title, kind?, venue, url?, date?, year? }` — fully inline
  - `{ text: "..." }` — free-form Markdown for entries that don't fit a schema

  `date:` is the precise, display-ready string (`"May 6–13, 2026"`,
  `"March 2024"`) and wins over `year:` when both are set. Use `year:` alone
  when only the year is known. `venue:` should carry the full proceedings
  title (`"SIGCSE 2026: Proceedings of the 57th ACM Technical Symposium on
  Computer Science Education V. 2"`), not the short conference name.

  ACM's DL export tags non-archival items `(Abstract Only)` inside the
  `title` field. `lib/cv/bib.rb` strips that automatically — leave it in
  `personal.bib` (it keeps the record faithful) and don't repeat it as a
  `kind:`.
- **Reorder publications**: just reorder the array in `data/publications.yml`.
  Set `reverse: true` on a group to render it as a reverse-numbered list
  (matches the LaTeX `etaremune` style).
- **Add a section**: drop a YAML file under `data/`, add a heading + ERB
  block in `templates/markdown/cv.md.erb` *and* `templates/latex/cv.tex.erb`.
  (For repeated patterns, factor a partial into `templates/markdown/_*.md.erb`.)
- **Long-form alternates**: several awards, grants, and the thesis carry a
  fuller description commented out beneath the live `summary:`. Those are the
  original wordings from the retired handcrafted LaTeX; swap one in by
  uncommenting it and deleting the short version.

### Inline conventions

The macros engine (`lib/cv/macros.rb`) translates a few markers consistently
across Markdown, HTML, and LaTeX:

- `Snap!`, `Snap!Con`, `Snap!shot` — italicize the `!` (`<em>!</em>` in HTML;
  `\snap{}` etc. in LaTeX)
- `[label](url)` — link
- `**bold**`, `*italic*` — emphasis (use `_underscore_` italics in YAML when
  the text might contain `Snap!`, to avoid asterisk collisions)

### Visual styling

- **Reversed publication numbering**: set `reverse: true` on a group in
  `data/publications.yml`. The renderer emits `<ol reversed start="N">`,
  so the latest item gets the highest number. (Matches the LaTeX
  `etaremune` look.)
- **Entry headings**: role / award / grant / project lines are emitted with
  the kramdown `{:.entry}` IAL. `preview.css` (and the deployed Jekyll
  layout) target `.entry` to make those titles a touch larger and
  Berkeley-blue, which scans much more easily than plain bold.
- **Sidebar TOC**: the local preview (`make preview`) auto-generates a
  left-sidebar nav from the rendered `<h2>`/`<h3>` headings. The
  deployed Jekyll site can replicate this in its own layout — the
  generated `cv.md` has stable `id` anchors thanks to kramdown's
  `auto_ids`. `cv-nav.js` is a scroll spy over those anchors: it adds
  `.is-active` + `aria-current` to the TOC link for whichever section is
  under the top of the viewport, and keeps that link scrolled into view in
  the sidebar.
- **Heading font**: `preview.css` `@import`s Source Serif 4 from Google
  Fonts and applies it to `.cv-content h1`–`h6` via `--cv-heading-font`.
  Body copy stays on the system sans stack.
- **References**: `data/references.yml` is the only copy of the referee list.
  Three different renderings come out of it, by design:
  - the Markdown / web CV shows only "References available upon request"
  - `build/cv-public.pdf` (the site-root download) does the same, via
    `\publicversion`
  - `build/cv-full.pdf` lists names, titles, and emails, but suppresses phone
    numbers via `\refphone` — only `build/cv-unredacted.pdf` includes those,
    and it is gitignored and never deployed

## Refreshing publications from DBLP

```sh
make dblp                      # curl -fsSL https://dblp.org/pid/175/6457.bib -o dblp.bib
make dblp DBLP_URL=<other>     # override the profile URL
```

Manually merge interesting entries into `personal.bib`. We don't pull
`dblp.bib` directly into the build because DBLP keys are unstable.

## The LaTeX / PDF path

```sh
make pdf            # every published PDF
make tex            # just the LaTeX: build/cv.tex + the variant wrappers
make unredacted     # build/cv-unredacted.pdf — private, includes referee phones
make pubs-tex       # build/publications.tex — just the publications subsection
```

`templates/latex/cv.tex.erb` emits `\cventry`, `\cvline`, etc. for every
section in `data/*.yml`. `bin/cv tex` writes the document body to
`build/cv.tex` plus three one-line wrappers that `\input` it, each selecting a
variant:

| Wrapper                  | Defines           | Output                    | Published as |
|--------------------------|-------------------|---------------------------|--------------|
| `build/cv-full.tex`      | —                 | `build/cv-full.pdf`       | `cv/cv-full.pdf` |
| `build/cv-public.tex`    | `\publicversion`  | `build/cv-public.pdf`     | root `michael-ball-cv.pdf` |
| `build/cv-unredacted.tex`| `\unredacted`     | `build/cv-unredacted.pdf` | never — private |

latexmk runs from inside `build/` so each wrapper's `\input{cv}` resolves.
See [`latex/README.md`](latex/README.md) for build requirements and privacy
notes.

Special-character escaping (`&`, `%`, `$`, `#`, `_`) happens automatically
in `lib/cv/macros.rb#to_latex`, so a grant amount like `$50,000` or a
title containing `&` renders correctly.

## Project layout

```
data/                        # YAML content — the single source of truth
personal.bib                 # citation database (manual + future DBLP imports)
lib/cv/                      # Ruby: macros, bib (bibtex-ruby shim), data, renderer, markdown, latex, preview
templates/markdown/          # cv.md.erb + 1 partial + preview shell + preview.css
                             #   + sidebar.html.erb, cv-theme.js, cv-nav.js
templates/latex/             # cv.tex.erb (drives the PDFs) + publications.tex.erb (fragment)
test/                        # minitest suite (`make test`)
latex/                       # one-page-resume.tex (live) + retired handcrafted sources
site/                        # static landing page (legacy; not part of the deploy)
.github/workflows/           # CI (build-cv.yml) and deploy (deploy.yml)
```

## CI / Deploy

Two workflows:

- **`build-cv.yml`** runs on every push and PR. Builds the three PDFs, runs the
  Ruby test suite, renders `cv.md` + the HTML preview, and uploads each as a
  workflow artifact. No deploy.
- **`deploy.yml`** runs on pushes to `main`. Builds the PDFs, renders
  `cv.md`, and pushes them into the
  [cycomachead/cycomachead.github.io](https://github.com/cycomachead/cycomachead.github.io)
  repo. The rendered CV page lands at `cv/` (served at
  [mball.co/cv](https://mball.co/cv)) and the public PDF lands at the site
  root (served at
  [mball.co/michael-ball-cv.pdf](https://mball.co/michael-ball-cv.pdf)):

  | Source                  | Destination in cycomachead.github.io       |
  |-------------------------|--------------------------------------------|
  | `build/cv-embed.md`     | `cv/index.md` (consumed by Jekyll)         |
  | `build/cv-sidebar.html` | `cv/cv-sidebar.html` (Jekyll include)      |
  | `build/cv.css`          | `cv/cv.css`                                |
  | `build/cv-theme.js`     | `cv/cv-theme.js`                           |
  | `build/cv-nav.js`       | `cv/cv-nav.js` (TOC scroll spy)            |
  | `build/cv-public.pdf`       | `michael-ball-cv.pdf` (site root — the public download; references withheld) |
  | `build/cv-full.pdf`         | `cv/cv-full.pdf`                           |
  | `latex/one-page-resume.pdf` | `cv/resume.pdf`                            |

  The `cv-sidebar.html` "Download CV (PDF)" button links to the root
  `/michael-ball-cv.pdf`; the résumé button links to the sibling
  `resume.pdf`. The deploy clones the site repo and rewrites **only** `cv/`
  (via `rsync --delete` scoped to that directory) and the root
  `michael-ball-cv.pdf`, then commits and pushes to `main` in a single
  commit. It deliberately does **not** use `actions-gh-pages`: that action is
  meant to publish built output to a `gh-pages` branch, and against the
  Jekyll *source* branch it dropped a `.nojekyll` file and removed the site's
  `jekyll.yml` build workflow — which stopped GitHub Pages from building and
  404'd `mball.co/cv`. The surgical push touches nothing outside the CV
  bundle, so it can't clobber the site's Jekyll source or its workflows.

  ### One-time setup

  The deploy job needs a Personal Access Token to push to the external repo.

  1. Create a fine-grained PAT scoped to `cycomachead/cycomachead.github.io`
     with **Contents: Read and write** permission. (No `Workflows`
     permission is needed — the deploy never writes under `.github/`.)
  2. In `cycomachead/cv` → Settings → Secrets and variables → Actions →
     New repository secret, name it `CYCOMACHEAD_GH_PAGES_TOKEN`.
  3. The deploy commits `cv/` into the target repo; the Jekyll site there
     has a `_layouts/cv.html` layout matching the `layout: cv` front matter
     emitted by the Markdown (it includes `cv-sidebar.html` and loads
     `cv.css` + `cv-theme.js` + `cv-nav.js`).

  Want to skip a deploy? Push to `main` with `[skip ci]` in the commit
  message, or trigger via `workflow_dispatch`.

## Testing

```sh
make test                   # minitest suite — bib parser, macros, data,
                            # renderer, markdown build + preview
```

CI runs the same suite on every PR.
