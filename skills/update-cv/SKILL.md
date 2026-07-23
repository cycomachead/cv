---
name: update-cv
description: Interview Michael section-by-section to keep the CV data in `data/*.yml` (and `personal.bib`) current. Use when the user says things like "update my CV", "what's new on my CV", "let's review my CV", "interview me about my service", or names a CV section (publications, service, grants, students, teaching, awards, positions, projects, press, basics). Also use whenever the user wants to capture a single new entry (a talk, paper, committee, grant, advisee, award) in the right place.
---

# Keep the CV current

This is Michael Ball's CV repo. Content lives in `data/*.yml` plus `personal.bib`; everything else (Markdown, HTML, two PDFs) is generated. The job of this skill is to **interview Michael, edit the YAML / BibTeX, and never invent facts**.

## Operating principles

1. **Anchor on today's date.** The system reminder gives you `currentDate`. Use it to spot stale entries, anticipate upcoming conference deadlines, and convert relative time references ("this spring", "last week") into absolute dates *before* writing anything to disk.
2. **Never fabricate.** If a date, venue, URL, DOI, co-author list, or grant amount isn't given, ask. Don't paraphrase a placeholder into something that looks authoritative. When unsure, leave a `TODO.md` line instead of guessing.
3. **Section-by-section.** Walk one section at a time and let Michael skip any. Don't dump every section's questions at once.
4. **Mind the schema.** Each YAML file has its own shape — match the existing entries. Read a few lines of the file before adding to it.
5. **Conventions to preserve.**
   - Author names: `"Last, First"` inside `authors:` arrays (the renderer flips them).
   - Snap-bang text: keep the `!` literal — `lib/cv/macros.rb` handles styling.
   - Date ranges: quoted with an en-dash, e.g. `"2024–2025"` (not `-`).
   - Quoted strings: quote any value containing `:`, `!`, `#`, leading/trailing whitespace, or that starts with a digit.
   - `personal.bib` is the source of truth for a real conference paper; `data/publications.yml` references it via `bib: <key>`. For one-off talks, posters, BoFs, etc., inline the entry under the right group.
6. **Never commit.** Michael commits on his own. Build and show what changed; don't `git commit`.

## Workflow

### 1. Orient

Before asking anything:

- Read `TODO.md` — known content gaps to surface during the interview.
- Skim `data/sections.yml` — that's the section order to walk.
- `git log --since="6 months ago" --stat -- data/ personal.bib` — what has *and hasn't* been touched recently. Sections that haven't been edited in a year are prime suspects for staleness.
- Note today's date and the academic year. Berkeley's academic year runs Aug–May; "summer" service items have a distinct cycle.

### 2. Pick a starting point

Ask Michael which sections to cover. Default offer (in priority order, since these change most often):

1. **Publications & Presentations** — new conference work, invited talks, workshops. Pay attention to imminent and recently-passed conference dates (SIGCSE, Snap!Con, TAPIA, Scratch, Dagstuhl, Faberllull).
2. **Service** — both Professional Service (program chairing, reviewing, organizing) and Departmental & Institutional (Berkeley EECS committees, working groups, Summer Instruction).
3. **Grants** — new awards, renewals, or grants ending. Confirm role (PI / co-PI / researcher / staff) and amount.
4. **Students Supervised** — new advisees this term, completed theses, second-reader appearances.
5. **Teaching** — courses taught newly this term; courses retired.
6. **Awards / Press / Projects / Positions / Basics** — confirm only on request or if visibly stale.

Let Michael pick, override the order, or say "all of it".

### 3. Per-section interview

For the chosen section, do this:

1. **Show the top of the current file** so Michael can see what's there. For long files (publications, service), show the most recent 5–10 entries plus any obvious gaps from `TODO.md`.
2. **Date-anchored prompts.** Compare `when:` fields against today's date. Examples:
   - Service item ending `2025–2026`: "This is your current term — anything to add for `2026–2027`?"
   - Last presentation entry is from a SIGCSE that happened 3 months ago: "SIGCSE \<year\> happened — anything to capture?"
   - A grant ends this calendar year: "This grant period ends \<date\> — renewal? Final report? New follow-on?"
3. **Specific question banks** (use the right bank for the section):

   **Publications / Presentations**
   - Any conference papers accepted since last update? (Title, venue, year, DOI/URL, full author list in submission order.)
   - Demos / Workshops / Tutorials / Birds-of-a-Feather / Posters / Lightning Talks / Panels at SIGCSE, Snap!Con, Scratch, TAPIA, etc.?
   - Invited talks, lectures, panels, residencies (Faberllull, Dagstuhl), or guest appearances?
   - Other writing: book chapters, magazine pieces, op-eds, blog series?
   - For each new entry, ask whether it should be added inline to `data/publications.yml` *or* added to `personal.bib` first (use the bib path for full conference papers).

   **Service**
   - Professional: Any new conference roles (program chair, associate chair, publicity, reviewer, organizing committee)? Are existing roles still ongoing or did they end?
   - Departmental & Institutional (Berkeley): EECS committees (Undergraduate Study, Grievances, Networks/Labs, Summer Instruction Co-Director), Unit 18 review committees, faculty advisory committees, Teach-Net moderation, working groups, college- or campus-level service.
   - Any new Snap!Con / Snap!shot organizing roles?

   **Grants**
   - New awards, gifts, micro-grants, or renewals?
   - Status changes on existing entries (extension, renewal, ended, role change)?
   - For each: title, agency, period, amount (formatted like `"$50,000"`), role, brief one-paragraph summary.

   **Students Supervised**
   - New advisees (M.S. or undergraduate honors)?
   - Theses completed (need title + EECS Tech Report URL once published)?
   - Second-reader appearances?

   **Teaching**
   - Any new course numbers taught? Any retired? Any new co-taught versions?
   - Updated course descriptions or unit changes?

   **Awards / Honors**
   - Any teaching awards, fellowships, honors, departmental recognitions?

   **Press / Media**
   - Interviews, podcast appearances, articles, panels covered in media?
   - URLs are required; no entry without one.

   **Projects**
   - New open-source project maintenance, tools spun up, or metrics worth refreshing (user counts, install counts, course adoption)?

   **Positions**
   - Title or appointment changes? New affiliations? Role percentages? Confirm the latest entry's date range still ends in `Present` if applicable.

   **Basics**
   - Bios are usually the last thing to update — only revisit if a major role change happened. If so, update all four (`oneline`, `short`, `medium`, `long`) for consistency.

4. **Cross-check external sources** when relevant (ask Michael first if he wants to):
   - `make dblp` — refreshes `dblp.bib` for new conference papers indexed at DBLP. Diff against `personal.bib` and surface unmatched entries as candidates.
   - `git log -- 6-publications/` and `personal.bib` for items that might already exist in BibTeX but haven't been linked from `data/publications.yml`.
   - `TODO.md` lines tagged with the current section.

### 4. Edit

Once Michael confirms a new entry:

- Match the existing schema for the file. Place new items in the right group (publications has multiple groups; service has two headings).
- For dated lists, insert in **the same chronological direction the existing entries use** (most files are reverse-chronological — newest first).
- Keep YAML clean: use `>-` folded scalars for prose summaries, plain strings for short fields, quote anything ambiguous.
- For new conference papers: add the `@inproceedings` (or appropriate) entry to `personal.bib` first, then reference it in `data/publications.yml` with `bib: <key>`. Keep keys in the existing style: `lastname_shortword_year`.

### 5. Update gaps

- For anything Michael couldn't answer (missing URL, pending DOI, "I'll check the date"), add or update a line in `TODO.md` under the right section. Don't drop the question silently.
- Remove `TODO.md` lines that the interview just resolved.

### 6. Verify

- Run `make test` (fast, ~26 tests) to make sure schema changes didn't break the renderer.
- Run `make` to rebuild `cv.md`, `cv.html`, and the PDFs. Surface any LaTeX warnings.
- Show a concise diff summary: which files changed and which sections gained/lost entries. Do **not** commit — Michael commits on his own.

## What this skill does NOT do

- Style or formatting overhauls (e.g., "make all author names First-Last") — those are tracked separately in `TODO.md`'s style section.
- LaTeX template edits in `templates/latex/` or in the legacy `*.tex` files — out of scope for an interview-based update pass.
- Inventing co-authors, DOIs, dates, amounts, or URLs from memory or web searches without confirmation.

## Quick reference: file → ask about

| File                          | Ask about                                                                 |
|-------------------------------|---------------------------------------------------------------------------|
| `data/basics.yml`             | Title change, new contact, bio refresh                                    |
| `data/positions.yml`          | New role, end date for current role, summary tweaks                       |
| `data/education.yml`          | Rarely changes — only on a new degree                                     |
| `data/research_interests.yml` | Slow-changing — only on major shifts                                      |
| `data/teaching.yml`           | New courses, retired courses, description changes                         |
| `data/awards.yml`             | New honors, teaching awards, departmental recognition                     |
| `data/grants.yml`             | New awards, renewals, role/amount/period changes                          |
| `data/students.yml`           | New advisees, completed theses (with EECS Tech Report URL), 2nd-reader    |
| `data/service.yml`            | Both headings — Professional and Departmental & Institutional             |
| `data/publications.yml`       | Invited Talks, Conference Papers, Conference & Workshop Presentations, Other Writing, Theses |
| `personal.bib`                | New `@inproceedings` / `@article` entries for full publications           |
| `data/press.yml`              | Interviews, podcasts, news mentions (URL required)                        |
| `data/projects.yml`           | New tools, retired tools, refreshed metrics                               |
| `data/skills.yml`             | Only on a real shift in tooling                                           |
| `data/references.yml`         | Only when the actual reference list changes                               |
| `TODO.md`                     | Always — close resolved items, open new gaps surfaced during the interview |
