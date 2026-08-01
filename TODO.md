# Content Gaps (need user input)

- [ ] Add Snap!Con 2025 session details (placeholder comment in the retired
      `latex/6-publications-conferences.tex`)
- [ ] Add UC Open 2026 entry (placeholder comment, same file)
- [ ] Add UC Berkeley Teaching and Learning Conf. poster: Vargas-Navarro, Edwin et al. on Flextensions
- [ ] Add Student-Organized AI Event talk (April 25, 2025; UC Berkeley) — title/URL needed
- [ ] Add Daily Cal interviews and additional CSEdPodcast appearances
      (candidate URLs are in the retired `latex/6-publications-press.tex`)
- [ ] Verify SIGCSE 2024 SIGCSE Online Posters & Lightning Talks Program Chair role
- [ ] Add PCF (Presidential Chair Fellows) grant description text
- [ ] Add Snap!Con descriptions
- [ ] Rewrite the BJC entry in `data/projects.yml`
- [ ] Identify additional software projects for `data/projects.yml`
      (notes mention seating-tool, berkeley-class-site)
- [ ] Thesis title for Edwin Vargas-Navarro (May 2025) is still missing in
      `data/students.yml`. (Rebecca Dang's is filled in.)
- [ ] Decide whether Google Scholar should join `data/basics.yml` profiles —
      it's in the site's `_config.yml` but not on the CV. moderncv supports a
      `googlescholar` \social, so it would reach the PDF too.

# Decisions, for future reference

- **Single source of truth.** `data/*.yml` + `personal.bib` generate the web
  CV *and* every published PDF. The section files under `latex/` are retired
  (each carries a `% RETIRED` header); only `latex/one-page-resume.tex` is
  still hand-written. Editing a retired file changes no output.
- **Contact details.** Michael's own mobile number is `basics.yml: phone` and
  renders on the PDFs only — `templates/markdown/cv.md.erb` deliberately never
  emits it. Referees' phone numbers are redacted everywhere we publish:
  `\refphone` suppresses them in `build/cv-full.pdf` (deployed as
  `cv/cv-full.pdf`); `build/cv-public.pdf` omits the References section
  entirely; the Jekyll embed keeps referee names, titles, and emails but not
  phones. `make unredacted` builds a private complete copy;
  `build/cv-unredacted.pdf` is gitignored and neither CI workflow touches it.
- **Masthead.** `basics.pdf_title` ("Curriculum Vitae") sets the PDF masthead;
  `basics.title` (the job title) is the web CV's subtitle. They're separate on
  purpose — set them equal if you'd rather they match.
- **Summer instruction role.** Uniformly "Faculty Co-Director", except Summer
  2023 which is "Faculty Director" — the old wording there ("Coordinator" /
  "Organizer") had no "Co-". The one-page résumé bullet reads "Faculty
  Director/Co-Director" to cover both.
- **`\href` labels.** `Renderer::Context#link` escapes LaTeX specials in the
  label and leaves the URL argument verbatim. Build both sides through that
  helper rather than hand-writing `\href{...}{...}` in a template — raw `#` or
  `_` in a label is a fatal build error.
- **`(Abstract Only)`.** ACM's DL export appends this to the `title` field of
  non-archival items. `lib/cv/bib.rb` strips it at render time, so
  `personal.bib` stays faithful to the published record. Don't re-add it as a
  `kind:`; a test guards against it leaking back in.
- **Long-form alternates.** Several entries in `data/awards.yml`,
  `data/grants.yml`, and the thesis in `data/publications.yml` carry the
  original, fuller handcrafted wording commented out beneath the live
  `summary:`. Uncomment to swap.

# Style / Formatting TODOs (carry-overs from earlier audit)

- Author names now render uniformly as "Last, First" (the old mixed
  "First Last" entries lived in the handcrafted LaTeX, now retired). Switching
  everything to "First Last" is a one-line change in
  `Renderer::Context#authors` if that's still wanted.
- `\cvline` should indent subsequent lines of text
- Students section bullets are not centered correctly
- Better spacing **before** a subsection
- URL style — distinguish from body text?
- Add URLs for each Snap!Con item (2019 items still have none)
- Include Teaching eval scores?
- Reconsider line height / font mix
- Should presentations be numbered?

# Known build caveats

- The `\DocumentMetadata{... tagging=on ...}` block needs TeX Live 2024 or
  newer. On TL 2023 the build aborts with
  "The key 'document/metadata/tagging' is unknown". CI is on a current image;
  older local toolchains will need an upgrade.
- `make` (the default target) still chains `preview`, which starts a blocking
  HTTP server — so `make` never reaches `pdf`. Run `make pdf` directly.
