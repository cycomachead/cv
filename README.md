# cv

Source for Michael Ball's CV. One YAML data set drives three outputs:

- **Markdown** (`build/cv.md`) — canonical, drops into the Jekyll site at
  [cycomachead.github.io/cv](https://cycomachead.github.io/cv/)
- **HTML preview** (`build/cv.html`) — kramdown-rendered standalone for local
  review; mirrors what the deployed Jekyll site will produce
- **LaTeX → PDF** (`main.pdf`, `one-page-resume.pdf`) — handcrafted moderncv
  templates (the existing `*.tex` files), kept for the printable CV

The Markdown and LaTeX outputs share publications: `data/publications.yml`
references keys in `personal.bib` so a single source generates both.

## Quick start

```sh
make            # cv.md, cv.html, and both PDFs
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

Content lives in `data/*.yml`. Each file is loaded by name (`data.basics`,
`data.education`, `data.publications`, …) and consumed by `templates/markdown/cv.md.erb`.

- **`basics.yml`** — name, title, contact, profile links (faculty page,
  GitHub, DBLP, ORCID, LinkedIn, Snap!), plus four reusable bios under
  `bio:` in Markdown:
  - `oneline` — one sentence, no links (Twitter / signatures)
  - `short`   — 2–3 sentences with a couple of links (top of the web CV)
  - `medium`  — paragraph (talk intros, grant applications)
  - `long`    — multi-paragraph narrative

- **Add a publication**: edit `data/publications.yml`. Items are one of:
  - `{ bib: <key>, kind?: ..., venue_override?: ..., url?: ... }` — pulls
    authors/title/venue/year from `personal.bib`
  - `{ authors: [...], title, kind?, venue, url?, year? }` — fully inline
  - `{ text: "..." }` — free-form Markdown for entries that don't fit a schema
- **Reorder publications**: just reorder the array in `data/publications.yml`.
  Set `reverse: true` on a group to render it as a reverse-numbered list
  (matches the LaTeX `etaremune` style).
- **Add a section**: drop a YAML file under `data/`, add a heading + ERB
  block in `templates/markdown/cv.md.erb`. (For repeated patterns, factor a
  partial into `templates/markdown/_*.md.erb`.)

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
- **References**: the Markdown output is the *public* web CV, so its
  References section is only ever "References available upon request".
  `data/references.yml` and `references.tex` (the real contact details) feed
  the private `main.pdf` build; `public.pdf` swaps in
  `references-public.tex`, which carries the same placeholder.

## Refreshing publications from DBLP

```sh
make dblp                      # curl -fsSL https://dblp.org/pid/175/6457.bib -o dblp.bib
make dblp DBLP_URL=<other>     # override the profile URL
```

Manually merge interesting entries into `personal.bib`. We don't pull
`dblp.bib` directly into the build because DBLP keys are unstable.

## Regenerating the LaTeX CV from YAML

There are two LaTeX paths:

```sh
make tex            # build/cv.tex — single-file scaffold from data/*.yml + personal.bib
make cv-pdf         # build/cv.pdf — same, then compile via lualatex
make pubs-tex       # build/publications.tex — just the publications subsection
```

The scaffold (`templates/latex/cv.tex.erb`) mirrors the moderncv preamble
in `main.tex` and emits `\cventry`, `\cvline`, etc. for every section
from YAML. Treat it as a starting point — the handcrafted `main.tex` and
`6-publications/1-conferences.tex` remain the source of truth for the
printable PDF until you decide to swap over.

Special-character escaping (`&`, `%`, `$`, `#`, `_`) happens automatically
in `lib/cv/macros.rb#to_latex`, so a grant amount like `$50,000` or a
title containing `&` renders correctly.

## Project layout

```
data/                        # YAML content (the only place to edit prose)
personal.bib                 # citation database (manual + future DBLP imports)
lib/cv/                      # Ruby: macros, bib (bibtex-ruby shim), data, renderer, markdown, latex, preview
templates/markdown/          # cv.md.erb + 1 partial + preview shell + preview.css
                             #   + sidebar.html.erb, cv-theme.js, cv-nav.js
templates/latex/             # cv.tex.erb (full scaffold) + publications.tex.erb (fragment)
test/                        # minitest suite (`make test`)
*.tex, 6-publications/       # existing moderncv documents (drive the PDFs)
site/                        # static landing page (legacy; not part of the deploy)
.github/workflows/           # CI (build-cv.yml) and deploy (deploy.yml)
```

## CI / Deploy

Two workflows:

- **`build-cv.yml`** runs on every push and PR. Builds the two PDFs, runs the
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
  | `public.pdf`            | `michael-ball-cv.pdf` (site root — the public download; references withheld) |
  | `main.pdf`              | `cv/cv-full.pdf`                           |
  | `one-page-resume.pdf`   | `cv/resume.pdf`                            |

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
