# Dual-publishing CV. The single authored source is data/*.yml + personal.bib;
# we render that to:
#   - build/cv.md     — canonical Markdown (drop into the Jekyll site)
#   - build/cv.html   — standalone HTML preview (kramdown + minimal CSS)
#   - main.pdf, one-page-resume.pdf — LaTeX → PDF via lualatex
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
TEX_FILES  := main.tex one-page-resume.tex
PDFS       := $(TEX_FILES:.tex=.pdf)
DEPLOY_DIR := $(BUILD_DIR)/deploy

.PHONY: all install md md-embed embed preview sidebar pdf tex cv-pdf pubs-tex deploy-out test dblp clean help

all: md preview embed pdf

# ---------------- Setup ----------------
# Install the Ruby gem dependencies (bibtex-ruby, kramdown, and the dev/test
# gems) via Bundler. Run this once after cloning. PDF builds additionally
# need lualatex + the moderncv/fontspec packages, installed outside Bundler.
install:
	@$(BUNDLE) install

# ---------------- Markdown (canonical output) ----------------
md:
	@$(RUBY) bin/cv md

# Header-stripped Markdown for the Jekyll embed (no name/title/contact block).
md-embed:
	@$(RUBY) bin/cv md:embed

# Sidebar fragment (download buttons + TOC + theme toggle) for the Jekyll site.
sidebar: md
	@$(RUBY) bin/cv sidebar

# Full embed bundle: cv-embed.md + cv-sidebar.html + cv.css + cv-theme.js.
embed:
	@$(RUBY) bin/cv embed

# ---------------- HTML preview ----------------
# Copies the built PDFs into $(BUILD_DIR)/ as cv.pdf / resume.pdf so the
# sidebar download buttons resolve when the preview is served from build/.
preview: md
	@$(RUBY) bin/cv preview
	@if [ -f public.pdf ]; then cp -f public.pdf $(BUILD_DIR)/cv.pdf; \
	elif [ -f main.pdf ]; then cp -f main.pdf $(BUILD_DIR)/cv.pdf; fi
	@if [ -f one-page-resume.pdf ]; then cp -f one-page-resume.pdf $(BUILD_DIR)/resume.pdf; fi
	@echo "Serving $(BUILD_DIR)/cv.html at http://localhost:$(PORT)"
	@cd $(BUILD_DIR) && $(RUBY) -run -e httpd . -p $(PORT)

# ---------------- LaTeX → PDF ----------------
pdf: $(PDFS)
%.pdf: %.tex
	$(LATEXMK) $(LATEX_OPTS) $<

# Single-file LaTeX CV scaffolded from data/*.yml. The hand-edited main.tex
# + 1-education.tex etc. remain the source of truth for the printable PDF
# until you decide to switch over; this is a parallel, regenerable target.
tex:
	@$(RUBY) bin/cv tex

cv-pdf: tex
	$(LATEXMK) $(LATEX_OPTS) -output-directory=$(BUILD_DIR) $(BUILD_DIR)/cv.tex

# Just the publications LaTeX fragment — useful if you only want to swap
# the publications section into main.tex.
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
	@cp main.pdf                                $(DEPLOY_DIR)/cv.pdf
	@cp one-page-resume.pdf                     $(DEPLOY_DIR)/resume.pdf
	@echo "staged $(DEPLOY_DIR)/{index.md, cv-sidebar.html, cv.css, cv-theme.js, cv.pdf, resume.pdf}"

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
	$(LATEXMK) -C
	rm -rf $(BUILD_DIR)

help:
	@echo "Targets:"
	@echo "  make install    install Ruby gem dependencies via Bundler"
	@echo "  make            build cv.md, cv.html, embed bundle, and both PDFs"
	@echo "  make md         build $(BUILD_DIR)/cv.md from YAML+bib"
	@echo "  make md-embed   build $(BUILD_DIR)/cv-embed.md (no page header) for Jekyll"
	@echo "  make preview    build cv.html and serve it on http://localhost:$(PORT)"
	@echo "  make sidebar    build $(BUILD_DIR)/cv-sidebar.html (Jekyll include)"
	@echo "  make embed      cv-embed.md + cv-sidebar.html + cv.css + cv-theme.js"
	@echo "  make pdf        build $(PDFS) via latexmk (requires lualatex)"
	@echo "  make tex        scaffold $(BUILD_DIR)/cv.tex from YAML+bib"
	@echo "  make cv-pdf     scaffold + compile $(BUILD_DIR)/cv.pdf"
	@echo "  make pubs-tex   regenerate publications.tex from YAML+bib"
	@echo "  make deploy-out stage embed bundle + PDFs for cycomachead.github.io/cv/"
	@echo "  make test       run the minitest suite"
	@echo "  make dblp       refresh dblp.bib from DBLP"
	@echo "  make clean      remove build/ and LaTeX intermediates"
