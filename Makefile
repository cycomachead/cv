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
PORT      ?= 8000

BUILD_DIR  := build
TEX_FILES  := main.tex one-page-resume.tex
PDFS       := $(TEX_FILES:.tex=.pdf)
DEPLOY_DIR := $(BUILD_DIR)/deploy

.PHONY: all md preview pdf tex cv-pdf pubs-tex deploy-out test dblp clean help

all: md preview pdf

# ---------------- Markdown (canonical output) ----------------
md:
	@$(RUBY) bin/cv md

# ---------------- HTML preview ----------------
preview: md
	@$(RUBY) bin/cv preview
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
# Stage cv.md + the two PDFs in build/deploy/, ready to copy into the
# cycomachead/cycomachead.github.io repo's cv/ folder. The CI workflow does
# this directly to the external repo; this target is for local dry-runs.
deploy-out: md pdf
	@mkdir -p $(DEPLOY_DIR)
	@cp $(BUILD_DIR)/cv.md  $(DEPLOY_DIR)/index.md
	@cp main.pdf            $(DEPLOY_DIR)/cv.pdf
	@cp one-page-resume.pdf $(DEPLOY_DIR)/resume.pdf
	@echo "staged $(DEPLOY_DIR)/{index.md, cv.pdf, resume.pdf}"

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
	@echo "  make            build cv.md, cv.html, and both PDFs"
	@echo "  make md         build $(BUILD_DIR)/cv.md from YAML+bib"
	@echo "  make preview    build cv.html and serve it on http://localhost:$(PORT)"
	@echo "  make pdf        build $(PDFS) via latexmk (requires lualatex)"
	@echo "  make tex        scaffold $(BUILD_DIR)/cv.tex from YAML+bib"
	@echo "  make cv-pdf     scaffold + compile $(BUILD_DIR)/cv.pdf"
	@echo "  make pubs-tex   regenerate publications.tex from YAML+bib"
	@echo "  make deploy-out stage cv.md + PDFs for cycomachead.github.io/cv/"
	@echo "  make test       run the minitest suite"
	@echo "  make dblp       refresh dblp.bib from DBLP"
	@echo "  make clean      remove build/ and LaTeX intermediates"
