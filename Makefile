# Dual-publishing CV. YAML drives the web and generated scaffold; handcrafted
# LaTeX drives the production PDFs:
#   - build/cv.md     — canonical Markdown (drop into the Jekyll site)
#   - build/cv.html   — standalone HTML preview (kramdown + minimal CSS)
#   - latex/*.pdf — handcrafted LaTeX → PDF via lualatex
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
TEX_FILES  := main.tex public.tex one-page-resume.tex
LATEX_SOURCES := $(wildcard $(LATEX_DIR)/*.tex)
PDFS       := $(addprefix $(LATEX_DIR)/,$(TEX_FILES:.tex=.pdf))
DEPLOY_DIR := $(BUILD_DIR)/deploy

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
	@if [ -f $(LATEX_DIR)/public.pdf ]; then cp -f $(LATEX_DIR)/public.pdf $(BUILD_DIR)/cv.pdf; \
	elif [ -f $(LATEX_DIR)/main.pdf ]; then cp -f $(LATEX_DIR)/main.pdf $(BUILD_DIR)/cv.pdf; fi
	@if [ -f $(LATEX_DIR)/one-page-resume.pdf ]; then cp -f $(LATEX_DIR)/one-page-resume.pdf $(BUILD_DIR)/resume.pdf; fi
	@echo "Serving $(BUILD_DIR)/cv.html at http://localhost:$(PORT)"
	@cd $(BUILD_DIR) && $(RUBY) -run -e httpd . -p $(PORT)

# ---------------- LaTeX → PDF ----------------
pdf: $(PDFS)
$(LATEX_DIR)/%.pdf: $(LATEX_SOURCES)
	cd $(LATEX_DIR) && $(LATEXMK) $(LATEX_OPTS) $*.tex

# Private build of the full CV that keeps referees' phone numbers. Every
# published PDF redacts them (see \refphone in latex/main.tex);
# latex/unredacted.pdf is gitignored and neither CI workflow builds or deploys
# it. Don't share it.
unredacted: $(LATEX_DIR)/unredacted.pdf

# Single-file LaTeX CV scaffolded from data/*.yml. The hand-edited
# latex/main.tex + its partials remain the source of truth for the printable PDF
# until you decide to switch over; this is a parallel, regenerable target.
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
	@cp $(LATEX_DIR)/public.pdf                  $(DEPLOY_DIR)/cv.pdf
	@cp $(LATEX_DIR)/main.pdf                    $(DEPLOY_DIR)/cv-full.pdf
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
	cd $(LATEX_DIR) && $(LATEXMK) -C
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
	@echo "  make unredacted build latex/unredacted.pdf — full CV incl. referees' phone"
	@echo "                  numbers. Private: gitignored, never deployed."
	@echo "  make tex        scaffold $(BUILD_DIR)/cv.tex from YAML+bib"
	@echo "  make cv-pdf     scaffold + compile $(BUILD_DIR)/cv.pdf"
	@echo "  make pubs-tex   regenerate publications.tex from YAML+bib"
	@echo "  make deploy-out stage embed bundle + PDFs for cycomachead.github.io/cv/"
	@echo "  make test       run the minitest suite"
	@echo "  make dblp       refresh dblp.bib from DBLP"
	@echo "  make clean      remove build/ and LaTeX intermediates"
