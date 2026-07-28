# Dual-publishing CV. The single authored source is data/*.yml + personal.bib;
# we render that to:
#   - build/cv.md     — canonical Markdown (drop into the Jekyll site)
#   - build/cv.html   — standalone HTML preview (kramdown + minimal CSS)
#   - latex/{main,public,one-page-resume}.pdf — LaTeX → PDF via lualatex
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
# Handcrafted moderncv sources all live under latex/ (see latex/README.md).
# latexmk runs *inside* that directory so the \input{1-education} style
# relative paths in main.tex resolve; the PDFs therefore land in latex/ too.
TEX_DIR    := latex
TEX_FILES  := main.tex public.tex one-page-resume.tex
PDFS       := $(addprefix $(TEX_DIR)/,$(TEX_FILES:.tex=.pdf))
# main.tex/public.tex \input{} every section file, so a PDF is stale whenever
# *any* source under latex/ changed — not just its own root document.
TEX_SOURCES := $(wildcard $(TEX_DIR)/*.tex) $(wildcard $(TEX_DIR)/6-publications/*.tex)
DEPLOY_DIR := $(BUILD_DIR)/deploy

.PHONY: all install gems check-latex md md-embed embed preview sidebar pdf tex cv-pdf pubs-tex deploy-out test dblp clean help

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
	@if [ -f $(TEX_DIR)/public.pdf ]; then cp -f $(TEX_DIR)/public.pdf $(BUILD_DIR)/cv.pdf; \
	elif [ -f $(TEX_DIR)/main.pdf ]; then cp -f $(TEX_DIR)/main.pdf $(BUILD_DIR)/cv.pdf; fi
	@if [ -f $(TEX_DIR)/one-page-resume.pdf ]; then cp -f $(TEX_DIR)/one-page-resume.pdf $(BUILD_DIR)/resume.pdf; fi
	@echo "Serving $(BUILD_DIR)/cv.html at http://localhost:$(PORT)"
	@cd $(BUILD_DIR) && $(RUBY) -run -e httpd . -p $(PORT)

# ---------------- LaTeX → PDF ----------------
# Builds latex/{main,public,one-page-resume}.pdf — the same three documents CI
# builds. `cd $(TEX_DIR)` matters: main.tex \input{}s its siblings by bare
# name, so latexmk has to run with latex/ as the working directory.
pdf: $(PDFS)
$(TEX_DIR)/%.pdf: $(TEX_DIR)/%.tex $(TEX_SOURCES)
	cd $(TEX_DIR) && $(LATEXMK) $(LATEX_OPTS) $(notdir $<)

# Single-file LaTeX CV scaffolded from data/*.yml. The hand-edited
# latex/main.tex + latex/1-education.tex etc. remain the source of truth for
# the printable PDF until you decide to switch over; this is a parallel,
# regenerable target.
tex:
	@$(RUBY) bin/cv tex

cv-pdf: tex
	$(LATEXMK) $(LATEX_OPTS) -output-directory=$(BUILD_DIR) $(BUILD_DIR)/cv.tex

# Just the publications LaTeX fragment — useful if you only want to swap
# the publications section into latex/main.tex.
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
	@if [ -f $(TEX_DIR)/public.pdf ]; then cp $(TEX_DIR)/public.pdf $(DEPLOY_DIR)/cv.pdf; \
	else cp $(TEX_DIR)/main.pdf $(DEPLOY_DIR)/cv.pdf; fi
	@cp $(TEX_DIR)/main.pdf                     $(DEPLOY_DIR)/cv-full.pdf
	@cp $(TEX_DIR)/one-page-resume.pdf          $(DEPLOY_DIR)/resume.pdf
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
	cd $(TEX_DIR) && $(LATEXMK) -C $(TEX_FILES)
	rm -rf $(BUILD_DIR)

help:
	@echo "Targets:"
	@echo "  make install    install Ruby gems + check the LaTeX toolchain"
	@echo "  make            build cv.md, cv.html, embed bundle, and both PDFs"
	@echo "  make md         build $(BUILD_DIR)/cv.md from YAML+bib"
	@echo "  make md-embed   build $(BUILD_DIR)/cv-embed.md (no page header) for Jekyll"
	@echo "  make preview    build cv.html and serve it on http://localhost:$(PORT)"
	@echo "  make sidebar    build $(BUILD_DIR)/cv-sidebar.html (Jekyll include)"
	@echo "  make embed      cv-embed.md + cv-sidebar.html + cv.css + cv-theme.js + cv-nav.js"
	@echo "  make pdf        build $(PDFS) via latexmk (requires lualatex)"
	@echo "                  sources + docs live in $(TEX_DIR)/ (see $(TEX_DIR)/README.md)"
	@echo "  make tex        scaffold $(BUILD_DIR)/cv.tex from YAML+bib"
	@echo "  make cv-pdf     scaffold + compile $(BUILD_DIR)/cv.pdf"
	@echo "  make pubs-tex   regenerate publications.tex from YAML+bib"
	@echo "  make deploy-out stage embed bundle + PDFs for cycomachead.github.io/cv/"
	@echo "  make test       run the minitest suite"
	@echo "  make dblp       refresh dblp.bib from DBLP"
	@echo "  make clean      remove build/ and LaTeX intermediates"
