# Single-source CV. data/*.yml + personal.bib drive every output:
#   - build/cv.md         — canonical Markdown (drop into the Jekyll site)
#   - build/cv.html       — standalone HTML preview (kramdown + minimal CSS)
#   - build/cv-full.pdf   — full CV (referee phones redacted)
#   - build/cv-public.pdf — public CV (no references) — the site-root download
#   - latex/one-page-resume.pdf — the standalone résumé, still hand-written
#
# The section files under latex/ are retired; see latex/README.md.
#
# `make help` lists every target. Common flows:
#   make            — build cv.md + cv.html + PDFs
#   make preview    — build cv.html and serve it on localhost
#   make test       — run the Ruby test suite
#   make deploy-out — stage cv.md + PDFs for the cycomachead.github.io repo

LATEXMK   ?= latexmk
LATEX_OPTS = -lualatex -interaction=nonstopmode -halt-on-error
RUBY      ?= ruby
RAKE      ?= rake
BUNDLE    ?= bundle
PORT      ?= 8000

BUILD_DIR  := build
LATEX_DIR  := latex
DEPLOY_DIR := $(BUILD_DIR)/deploy

# Everything the generated LaTeX is derived from.
TEX_INPUTS := $(wildcard data/*.yml) personal.bib $(wildcard templates/latex/*.erb) \
              $(wildcard lib/cv/*.rb)
# Generated document body + the variant wrappers that \input it.
GEN_TEX    := $(BUILD_DIR)/cv.tex $(BUILD_DIR)/cv-full.tex \
              $(BUILD_DIR)/cv-public.tex $(BUILD_DIR)/cv-unredacted.tex
# The published set: full CV, public CV, and the hand-written one-page résumé.
PDFS       := $(BUILD_DIR)/cv-full.pdf $(BUILD_DIR)/cv-public.pdf \
              $(LATEX_DIR)/one-page-resume.pdf

.PHONY: all install gems check-latex md md-embed embed preview sidebar pdf unredacted tex cv-pdf pubs-tex deploy-out test dblp clean help

all: md preview embed pdf

# ---------------- Setup ----------------
# One-shot setup after cloning: install the Ruby gems and verify the LaTeX
# toolchain the PDF targets need. LaTeX isn't a Bundler dependency, so we
# can't install it here (it's a multi-GB, platform-specific, sudo-requiring
# TeX distribution) — instead we check for it and print install guidance.
install: gems check-latex

# Ruby gem dependencies (bibtex-ruby, kramdown, and the dev/test gems).
gems:
	@$(BUNDLE) install

# Verify lualatex + latexmk are on PATH for the PDF targets. Non-fatal: the
# Markdown/HTML workflow works without LaTeX, so we warn rather than fail.
check-latex:
	@if command -v $(LATEXMK) >/dev/null 2>&1 && command -v lualatex >/dev/null 2>&1; then \
		echo "✓ LaTeX toolchain found ($(LATEXMK) + lualatex) — PDF targets ready."; \
	else \
		echo "⚠ LaTeX toolchain missing — 'make pdf' won't work until you install it."; \
		echo "  Need: lualatex + latexmk, with the moderncv/fontspec packages"; \
		echo "        and Source Sans Pro. Install a TeX distribution, e.g.:"; \
		echo "    macOS:  brew install --cask mactex"; \
		echo "    Debian: sudo apt-get install latexmk texlive-luatex \\"; \
		echo "            texlive-latex-extra texlive-fonts-extra"; \
	fi

# ---------------- Markdown (canonical output) ----------------
md:
	@$(RUBY) bin/cv md

# Header-stripped Markdown for the Jekyll embed (no name/title/contact block).
md-embed:
	@$(RUBY) bin/cv md:embed

# Sidebar fragment (download buttons + TOC + theme toggle) for the Jekyll site.
sidebar: md
	@$(RUBY) bin/cv sidebar

# Full embed bundle: cv-embed.md + cv-sidebar.html + cv.css + the scripts.
embed:
	@$(RUBY) bin/cv embed

# ---------------- HTML preview ----------------
# Copies the built PDFs into $(BUILD_DIR)/ as cv.pdf / resume.pdf so the
# sidebar download buttons resolve when the preview is served from build/.
preview: md
	@$(RUBY) bin/cv preview
	@if [ -f $(BUILD_DIR)/cv-public.pdf ]; then cp -f $(BUILD_DIR)/cv-public.pdf $(BUILD_DIR)/cv.pdf; \
	elif [ -f $(BUILD_DIR)/cv-full.pdf ]; then cp -f $(BUILD_DIR)/cv-full.pdf $(BUILD_DIR)/cv.pdf; fi
	@if [ -f $(LATEX_DIR)/one-page-resume.pdf ]; then cp -f $(LATEX_DIR)/one-page-resume.pdf $(BUILD_DIR)/resume.pdf; fi
	@echo "Serving $(BUILD_DIR)/cv.html at http://localhost:$(PORT)"
	@cd $(BUILD_DIR) && $(RUBY) -run -e httpd . -p $(PORT)

# ---------------- LaTeX → PDF ----------------
# All PDFs are generated from data/*.yml. `bin/cv tex` writes the document body
# (cv.tex) plus the cv-full / cv-public / cv-unredacted wrappers; latexmk runs
# from inside build/ so each wrapper's \input{cv} resolves.
pdf: $(PDFS)

tex: $(GEN_TEX)
$(GEN_TEX) &: $(TEX_INPUTS)
	@$(RUBY) bin/cv tex

$(BUILD_DIR)/%.pdf: $(BUILD_DIR)/%.tex $(BUILD_DIR)/cv.tex
	cd $(BUILD_DIR) && $(LATEXMK) $(LATEX_OPTS) $*.tex

# The one-page résumé is a genuinely different document with no YAML source,
# so it stays hand-written.
$(LATEX_DIR)/one-page-resume.pdf: $(LATEX_DIR)/one-page-resume.tex
	cd $(LATEX_DIR) && $(LATEXMK) $(LATEX_OPTS) one-page-resume.tex

# Private build of the full CV that keeps referees' phone numbers. Every
# published PDF redacts them (see \refphone in templates/latex/cv.tex.erb);
# build/cv-unredacted.pdf is gitignored and neither CI workflow builds or
# deploys it. Don't share it.
unredacted: $(BUILD_DIR)/cv-unredacted.pdf

# Back-compat alias — cv-full.pdf is the full CV.
cv-pdf: $(BUILD_DIR)/cv-full.pdf

# Just the publications LaTeX fragment — useful for pasting the publication
# list into a separate document (a grant bio-sketch, a departmental form).
pubs-tex:
	@$(RUBY) bin/cv pubs:tex $(BUILD_DIR)/publications.tex

# ---------------- Deploy bundle ----------------
# Stage cv-embed.md + sidebar fragment + assets + PDFs in build/deploy/, ready
# to copy into the cycomachead/cycomachead.github.io repo's cv/ folder. The
# CI workflow does this directly to the external repo; this target is for
# local dry-runs.
deploy-out: md-embed sidebar pdf
	@mkdir -p $(DEPLOY_DIR)
	@cp $(BUILD_DIR)/cv-embed.md                $(DEPLOY_DIR)/index.md
	@cp $(BUILD_DIR)/cv-sidebar.html            $(DEPLOY_DIR)/cv-sidebar.html
	@cp templates/markdown/preview.css          $(DEPLOY_DIR)/cv.css
	@cp templates/markdown/cv-theme.js          $(DEPLOY_DIR)/cv-theme.js
	@cp templates/markdown/cv-nav.js            $(DEPLOY_DIR)/cv-nav.js
	@cp $(BUILD_DIR)/cv-public.pdf               $(DEPLOY_DIR)/cv.pdf
	@cp $(BUILD_DIR)/cv-full.pdf                 $(DEPLOY_DIR)/cv-full.pdf
	@cp $(LATEX_DIR)/one-page-resume.pdf         $(DEPLOY_DIR)/resume.pdf
	@echo "staged $(DEPLOY_DIR)/{index.md, cv-sidebar.html, cv.css, cv-theme.js, cv-nav.js, cv.pdf, cv-full.pdf, resume.pdf}"

# ---------------- DBLP refresh ----------------
# Pull the latest BibTeX export for the DBLP author profile. Manually merge
# anything interesting into personal.bib — DBLP keys are unstable so we
# don't pull dblp.bib straight into the build.
DBLP_URL ?= https://dblp.org/pid/175/6457.bib

dblp:
	@curl -fsSL "$(DBLP_URL)" -o dblp.bib && echo "wrote dblp.bib"

# ---------------- Tests ----------------
test:
	@$(RAKE) test

# ---------------- Housekeeping ----------------
clean:
	cd $(LATEX_DIR) && $(LATEXMK) -C one-page-resume.tex
	rm -rf $(BUILD_DIR)

help:
	@echo "Targets:"
	@echo "  make install    install Ruby gems + check the LaTeX toolchain"
	@echo "  make            build cv.md, cv.html, embed bundle, and published PDFs"
	@echo "  make md         build $(BUILD_DIR)/cv.md from YAML+bib"
	@echo "  make md-embed   build $(BUILD_DIR)/cv-embed.md (no page header) for Jekyll"
	@echo "  make preview    build cv.html and serve it on http://localhost:$(PORT)"
	@echo "  make sidebar    build $(BUILD_DIR)/cv-sidebar.html (Jekyll include)"
	@echo "  make embed      cv-embed.md + cv-sidebar.html + cv.css + cv-theme.js + cv-nav.js"
	@echo "  make pdf        build $(PDFS) via latexmk (requires lualatex)"
	@echo "  make unredacted build $(BUILD_DIR)/cv-unredacted.pdf — full CV incl. referees'"
	@echo "                  phone numbers. Private: gitignored, never deployed."
	@echo "  make tex        render $(BUILD_DIR)/cv.tex (+ variant wrappers) from YAML+bib"
	@echo "  make cv-pdf     alias for $(BUILD_DIR)/cv-full.pdf"
	@echo "  make pubs-tex   regenerate publications.tex from YAML+bib"
	@echo "  make deploy-out stage embed bundle + PDFs for cycomachead.github.io/cv/"
	@echo "  make test       run the minitest suite"
	@echo "  make dblp       refresh dblp.bib from DBLP"
	@echo "  make clean      remove build/ and LaTeX intermediates"
