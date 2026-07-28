# Content Gaps (need user input)

- [ ] Add Snap!Con 2025 session details (placeholder exists)
- [ ] Add UC Open 2026 entry (placeholder exists)
- [ ] Add UC Berkeley Teaching and Learning Conf. poster: Vargas-Navarro, Edwin et al. on Flextensions
- [ ] Add Student-Organized AI Event talk (April 25, 2025; UC Berkeley) — title/URL needed
- [ ] Add Daily Cal interviews and additional CSEdPodcast appearances (URLs in `6-publications/3-press.tex`)
- [ ] Verify SIGCSE 2024 SIGCSE Online Posters & Lightning Talks Program Chair role
- [ ] Add PCF (Presidential Chair Fellows) grant description text
- [ ] Add Snap!Con descriptions
- [ ] Rewrite BJC project section in `3-projects.tex`
- [ ] Identify additional software projects to list in `3-projects.tex` (notes mention seating-tool, berkeley-class-site)

# Still open from the 2026-07 audit

- [ ] Thesis title for Edwin Vargas-Navarro (May 2025) is still missing in
      `data/students.yml` / `students.tex`. (Rebecca Dang's is filled in.)

## Decisions from that audit, for future reference

- **Contact details.** Michael's own mobile number appears on both PDFs and not
  on the website (`data/basics.yml` has no `phone`, so the HTML CV never renders
  one). Referees' phone numbers are redacted everywhere we publish: `\refphone`
  in `main.tex` drops them from main.pdf/cv-full.pdf, public.pdf omits the
  References section entirely, and the Jekyll embed keeps referee names, titles,
  and emails but not phones. `make unredacted` builds a private complete copy;
  `unredacted.pdf` is gitignored and neither CI workflow touches it.
- **Summer instruction role.** Uniformly "Faculty Co-Director", except Summer
  2023 which is "Faculty Director" — the old wording there ("Coordinator" /
  "Organizer") had no "Co-". The one-page résumé bullet reads "Faculty
  Director/Co-Director" to cover both.
- **`\href` labels.** `Renderer::Context#link` escapes LaTeX specials in the
  label and leaves the URL argument verbatim. Build both sides through that
  helper rather than hand-writing `\href{...}{...}` in a template — raw `#` or
  `_` in a label is a fatal build error.

# Style / Formatting TODOs (carry-overs from earlier audit)

- Make author names "First Last" on *all* items (currently mixed "Last, First" and "First Last")
- `\cvline` should indent subsequent lines of text
- Students section bullets are not centered correctly
- Better spacing **before** a subsection
- URL style — distinguish from body text?
- Add URLs for each Snap!Con item (2019 items still have none)
- Include Teaching eval scores?
- Reconsider line height / font mix
- Should presentations be numbered?
