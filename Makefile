# Makefile for generating lecture presentations

# =============================================================================
# Directories
# =============================================================================

LECTURES_DIR    = lectures
ASSESSMENTS_DIR = assessments
WORKSHOPS_DIR   = workshops
RESOURCES_DIR   = resources
TEMPLATES_DIR   = templates
OUTPUT_DIR      = build
IMAGE_DIR       = img

LECTURES_OUT    = $(OUTPUT_DIR)/lectures
ASSESSMENTS_OUT = $(OUTPUT_DIR)/assessments
WORKSHOPS_OUT   = $(OUTPUT_DIR)/workshops
RESOURCES_OUT   = $(OUTPUT_DIR)/resources

# =============================================================================
# Course metadata
# =============================================================================

REFERENCES = references.bib
CONFIG     = _config.toml
CONFIG_AUTHOR := $(shell python3 -c "import tomllib; f=open('$(CONFIG)','rb'); d=tomllib.load(f); print(d['author'])")
CONFIG_YEAR   := $(shell python3 -c "import tomllib; f=open('$(CONFIG)','rb'); d=tomllib.load(f); print(d['year'])")

INDEX_HTML      = $(OUTPUT_DIR)/index.html
INDEX_GENERATOR = generate_index.py

# =============================================================================
# Pandoc configuration
# =============================================================================

PANDOC = pandoc

# -V revealjs-url=https://unpkg.com/reveal.js@4.5.0
PANDOC_COMMON_OPTS = --standalone \
                     --slide-level 2 \
                     --citeproc \
                     --bibliography=$(REFERENCES) \
                     --csl=apa.csl \
                     -M link-citations=true \
                     --resource-path=.:$(LECTURES_DIR):$(ASSESSMENTS_DIR):$(RESOURCES_DIR):$(WORKSHOPS_DIR)

REVEAL_OPTS = -t revealjs \
              -V controls=true \
              -V progress=true \
              -V center=false \
              -V width=1920 \
              -V height=1080 \
              -V margin=0.1 \
              -V transition=fade \
              -V backgroundTransition=fade \
              -V hash=true \
              -V history=false \
              -V slideNumber=true \
              --css reveal_dark.css

BEAMER_OPTS = -t beamer \
              -V aspectratio=169 \
              -V theme=metropolis \
              -V colortheme=owl \
              --pdf-engine=lualatex \
              -V mainfont="Noto Sans" \
              -V mainfontfallback="NotoColorEmoji:mode=harf" \
              --lua-filter=filters/beamer-background.lua

# --pdf-engine=xelatex

PDF_OPTS = --metadata date="$(shell date '+%Y-%m-%d')" \
           --number-sections=true \
           -V 'geometry: left=2.5cm,right=2.5cm,top=2.5cm,bottom=2.5cm' \
           -V 'papersize: a4' \
           -V 'fontsize:11pt' \
           -V 'pagestyle:headings' \
           --pdf-engine=lualatex \
           -V mainfont="Linux Libertine O" \
           -V sansfont="Noto Sans" \
           -V mainfontfallback="NotoColorEmoji:mode=harf"

# -V 'fontfamily:libertine,sourcecodepro'

HTML_OPTS = -V mainfont="system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif"

# =============================================================================
# Top-level targets
# =============================================================================

.PHONY: all
all: reveal beamer assessments resources workshops images index

.PHONY: public
public: reveal beamer assessments workshops images index

.PHONY: html
html: reveal assessments resources workshops images index

.PHONY: clean
clean:
	rm -rf $(OUTPUT_DIR)

# =============================================================================
# Lectures — Reveal.js HTML + Beamer PDF
# =============================================================================

LECTURE_MDS  = $(wildcard $(LECTURES_DIR)/*.md)
REVEAL_HTMLS = $(patsubst $(LECTURES_DIR)/%.md,$(LECTURES_OUT)/%.html,$(LECTURE_MDS))
BEAMER_PDFS  = $(patsubst $(LECTURES_DIR)/%.md,$(LECTURES_OUT)/%.pdf,$(LECTURE_MDS))

.PHONY: reveal
reveal: $(LECTURES_OUT) $(REVEAL_HTMLS) images $(LECTURES_OUT)/reveal_dark.css

$(LECTURES_OUT)/%.html: $(LECTURES_DIR)/%.md
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(REVEAL_OPTS) $< -o $@

.PHONY: beamer
beamer: $(LECTURES_OUT) $(BEAMER_PDFS)

$(LECTURES_OUT)/%.pdf: $(LECTURES_DIR)/%.md
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(BEAMER_OPTS) $< -o $@

# =============================================================================
# Assessments — HTML + PDF
# =============================================================================

ASSESSMENTS_MDS  = $(wildcard $(ASSESSMENTS_DIR)/*.md)
ASSESSMENTS_HTMLS = $(patsubst $(ASSESSMENTS_DIR)/%.md,$(ASSESSMENTS_OUT)/%.html,$(ASSESSMENTS_MDS))
ASSESSMENTS_PDFS  = $(patsubst $(ASSESSMENTS_DIR)/%.md,$(ASSESSMENTS_OUT)/%.pdf,$(ASSESSMENTS_MDS))

.PHONY: assessments
assessments: $(ASSESSMENTS_OUT) $(ASSESSMENTS_HTMLS) $(ASSESSMENTS_PDFS)

$(ASSESSMENTS_OUT)/%.html: $(ASSESSMENTS_DIR)/%.md
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(HTML_OPTS) $< -o $@

$(ASSESSMENTS_OUT)/%.pdf: $(ASSESSMENTS_DIR)/%.md
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(PDF_OPTS) $< -o $@

# =============================================================================
# Workshops — HTML only
# =============================================================================

WORKSHOPS_MDS  = $(wildcard $(WORKSHOPS_DIR)/*.md)
WORKSHOPS_HTMLS = $(patsubst $(WORKSHOPS_DIR)/%.md,$(WORKSHOPS_OUT)/%.html,$(WORKSHOPS_MDS))

.PHONY: workshops
workshops: $(WORKSHOPS_OUT) $(WORKSHOPS_HTMLS)

$(WORKSHOPS_OUT)/%.html: $(WORKSHOPS_DIR)/%.md $(REFERENCES)
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(HTML_OPTS) $< -o $@

# =============================================================================
# Resources — HTML only
# =============================================================================

RESOURCES_MDS  = $(wildcard $(RESOURCES_DIR)/*.md)
RESOURCES_HTMLS = $(patsubst $(RESOURCES_DIR)/%.md,$(RESOURCES_OUT)/%.html,$(RESOURCES_MDS))

.PHONY: resources
resources: $(RESOURCES_OUT) $(RESOURCES_HTMLS)

$(RESOURCES_OUT)/%.html: $(RESOURCES_DIR)/%.md
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(HTML_OPTS) $< -o $@

# =============================================================================
# Images — copy from source to build
# =============================================================================

LECTURES_IMG     := $(wildcard lectures/img/*.png lectures/img/*.jpg lectures/img/*.jpeg lectures/img/*.svg lectures/img/*.gif lectures/img/*.webp)
ASSESSMENTS_IMG  := $(wildcard assessments/img/*.png assessments/img/*.jpg assessments/img/*.jpeg assessments/img/*.svg assessments/img/*.gif assessments/img/*.webp)
WORKSHOPS_IMG    := $(wildcard workshops/img/*.png workshops/img/*.jpg workshops/img/*.jpeg workshops/img/*.svg workshops/img/*.gif workshops/img/*.webp)
RESOURCES_IMG    := $(wildcard resources/img/*.png resources/img/*.jpg resources/img/*.jpeg resources/img/*.svg resources/img/*.gif resources/img/*.webp)

LECTURES_BUILD_IMG    := $(patsubst lectures/img/%,build/lectures/img/%,$(LECTURES_IMG))
ASSESSMENTS_BUILD_IMG := $(patsubst assessments/img/%,build/assessments/img/%,$(ASSESSMENTS_IMG))
WORKSHOPS_BUILD_IMG   := $(patsubst workshops/img/%,build/workshops/img/%,$(WORKSHOPS_IMG))
RESOURCES_BUILD_IMG   := $(patsubst resources/img/%,build/resources/img/%,$(RESOURCES_IMG))
ALL_BUILD_IMGS        := $(LECTURES_BUILD_IMG) $(ASSESSMENTS_BUILD_IMG) $(WORKSHOPS_BUILD_IMG) $(RESOURCES_BUILD_IMG)

.PHONY: images
images: $(ALL_BUILD_IMGS)

$(OUTPUT_DIR)/$(LECTURES_DIR)/$(IMAGE_DIR)/%: $(LECTURES_DIR)/$(IMAGE_DIR)/%
	@mkdir -p $(dir $@)
	cp $< $@

$(OUTPUT_DIR)/$(ASSESSMENTS_DIR)/$(IMAGE_DIR)/%: $(ASSESSMENTS_DIR)/$(IMAGE_DIR)/%
	@mkdir -p $(dir $@)
	cp $< $@

$(OUTPUT_DIR)/$(WORKSHOPS_DIR)/$(IMAGE_DIR)/%: $(WORKSHOPS_DIR)/$(IMAGE_DIR)/%
	@mkdir -p $(dir $@)
	cp $< $@

$(OUTPUT_DIR)/$(RESOURCES_DIR)/$(IMAGE_DIR)/%: $(RESOURCES_DIR)/$(IMAGE_DIR)/%
	@mkdir -p $(dir $@)
	cp $< $@

# =============================================================================
# CSS / Styles
# =============================================================================

%/reveal_dark.css: css/reveal_dark.scss
	sass --style=compressed css/reveal_dark.scss $@

# =============================================================================
# Output directories
# =============================================================================

.PHONY: directories
directories: $(LECTURES_OUT) $(WORKSHOPS_OUT) $(ASSESSMENTS_OUT) $(RESOURCES_OUT)

$(LECTURES_OUT) $(WORKSHOPS_OUT) $(ASSESSMENTS_OUT) $(RESOURCES_OUT):
	mkdir -p $@

# =============================================================================
# Index
# =============================================================================

.PHONY: index
index: $(INDEX_HTML)

$(INDEX_HTML): $(LECTURE_MDS) $(ASSESSMENTS_MDS) $(WORKSHOPS_MDS) $(RESOURCES_MDS) $(INDEX_GENERATOR)
	python3 $(INDEX_GENERATOR) $@ $(OUTPUT_DIR)

# =============================================================================
# Concatenated mega-files (all lectures / assessments / workshops in one file)
# =============================================================================

ALL_LECTURES    = $(OUTPUT_DIR)/all_lectures.pdf
ALL_ASSESSMENTS = $(OUTPUT_DIR)/all_assessments.pdf
ALL_WORKSHOPS   = $(OUTPUT_DIR)/all_workshops.pdf

.PHONY: bigfiles
bigfiles: $(ALL_LECTURES) $(ALL_ASSESSMENTS) $(ALL_WORKSHOPS)

$(ALL_LECTURES): $(LECTURE_MDS)
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(PDF_OPTS) --metadata title="All Lectures" --metadata author="$(CONFIG_AUTHOR)" --metadata date="$(CONFIG_YEAR)" --toc=true -o $@ $^

$(ALL_ASSESSMENTS): $(ASSESSMENTS_MDS)
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(PDF_OPTS) --metadata title="All Assessments" --metadata author="$(CONFIG_AUTHOR)" --metadata date="$(CONFIG_YEAR)" --toc=true -o $@ $^

$(ALL_WORKSHOPS): $(WORKSHOPS_MDS)
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(PDF_OPTS) --metadata title="All Workshops" --metadata author="$(CONFIG_AUTHOR)" --metadata date="$(CONFIG_YEAR)" --toc=true -o $@ $^

ALL_LECTURES_MD    = $(OUTPUT_DIR)/all_lectures.md
ALL_ASSESSMENTS_MD = $(OUTPUT_DIR)/all_assessments.md
ALL_WORKSHOPS_MD   = $(OUTPUT_DIR)/all_workshops.md

.PHONY: bigmd
bigmd: $(OUTPUT_DIR) $(ALL_LECTURES_MD) $(ALL_ASSESSMENTS_MD) $(ALL_WORKSHOPS_MD)

$(ALL_LECTURES_MD): $(LECTURE_MDS)
	cat $^ > $@

$(ALL_ASSESSMENTS_MD): $(ASSESSMENTS_MDS)
	cat $^ > $@

$(ALL_WORKSHOPS_MD): $(WORKSHOPS_MDS)
	cat $^ > $@
