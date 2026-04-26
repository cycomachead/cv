# Dual-publishing CV: HTML (Ruby/ERB) + LaTeX/PDF (moderncv).
#
# `make help` lists every target. Most users only need:
#   make            — build everything (HTML site + both PDFs)
#   make preview    — open the HTML site in a local server
#   make test       — run the Ruby test suite

LATEXMK   ?= latexmk
LATEX_OPTS = -lualatex -interaction=nonstopmode -halt-on-error
RUBY      ?= ruby
RAKE      ?= rake
PORT      ?= 8000

SITE_DIR  := build/site
TEX_FILES := main.tex one-page-resume.tex
PDFS      := $(TEX_FILES:.tex=.pdf)

.PHONY: all html pdf preview test test-pubs clean dblp pubs-tex help

all: html pdf

# ---------------- HTML site ----------------
html:
	@$(RUBY) bin/cv site

preview: html
	@echo "Serving $(SITE_DIR) at http://localhost:$(PORT)"
	@cd $(SITE_DIR) && $(RUBY) -run -e httpd . -p $(PORT)

# ---------------- LaTeX → PDF ----------------
pdf: $(PDFS)

%.pdf: %.tex
	$(LATEXMK) $(LATEX_OPTS) $<

# Regenerate the publications LaTeX fragment from YAML + bib. Optional —
# the existing 6-publications/1-conferences.tex remains the source of truth
# until you decide to switch over.
pubs-tex:
	@$(RUBY) bin/cv pubs:tex build/publications.tex

# ---------------- DBLP ----------------
dblp:
	@$(RUBY) bin/cv dblp

# ---------------- Tests ----------------
test:
	@$(RAKE) test

# ---------------- Housekeeping ----------------
clean:
	$(LATEXMK) -C
	rm -rf build

help:
	@echo "Targets:"
	@echo "  make           build HTML site + PDFs"
	@echo "  make html      build HTML site to $(SITE_DIR)"
	@echo "  make pdf       build $(PDFS) via latexmk"
	@echo "  make preview   build site and serve it on http://localhost:$(PORT)"
	@echo "  make pubs-tex  regenerate publications.tex from YAML+bib"
	@echo "  make test      run the minitest suite"
	@echo "  make dblp      refresh dblp.bib from DBLP"
	@echo "  make clean     remove build/ and LaTeX intermediates"
