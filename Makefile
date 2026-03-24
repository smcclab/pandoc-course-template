# Makefile for generating lecture presentations

# Directories
LECTURES_DIR = lectures
RESOURCES_DIR = resources
ASSESSMENTS_DIR = assessments
WORKSHOPS_DIR = workshops
TEMPLATES_DIR = templates
OUTPUT_DIR = build
IMAGE_DIR = img
LECTURES_OUT = $(OUTPUT_DIR)/lectures
ASSESSMENTS_OUT = $(OUTPUT_DIR)/assessments
WORKSHOPS_OUT = $(OUTPUT_DIR)/workshops
RESOURCES_OUT = $(OUTPUT_DIR)/resources
REFERENCES = references.bib

# Images
LECTURES_IMG := $(wildcard lectures/img/*.png lectures/img/*.jpg)
RESOURCES_IMG := $(wildcard resources/img/*.png resources/img/*.jpg)
WORKSHOPS_IMG := $(wildcard workshops/img/*.png workshops/img/*.jpg)
ASSESSMENTS_IMG := $(wildcard assessments/img/*.png assessments/img/*.jpg)
ALL_SRC_IMGS := $(LECTURES_IMG) $(RESOURCES_IMG) $(WORKSHOPS_IMG) $(ASSESSMENTS_IMG)

# build targets
LECTURES_BUILD_IMG := $(patsubst lectures/img/%,build/lectures/img/%,$(LECTURES_IMG))
RESOURCES_BUILD_IMG := $(patsubst resources/img/%,build/resources/img/%,$(RESOURCES_IMG))
WORKSHOPS_BUILD_IMG := $(patsubst workshops/img/%,build/workshops/img/%,$(WORKSHOPS_IMG))
ASSESSMENTS_BUILD_IMG := $(patsubst assessments/img/%,build/assessments/img/%,$(ASSESSMENTS_IMG))
ALL_BUILD_IMGS := $(LECTURES_BUILD_IMG) $(RESOURCES_BUILD_IMG) $(WORKSHOPS_BUILD_IMG) $(ASSESSMENTS_BUILD_IMG)

# Index generation
INDEX_HTML = $(OUTPUT_DIR)/index.html
INDEX_GENERATOR = generate_index.py

# phony targets
.PHONY: all
all: reveal beamer assessments resources workshops images index

.PHONY: public
public: reveal beamer assessments workshops images index

.PHONY: html
html: reveal assessments resources workshops images index

.PHONY: clean
clean:
	rm -rf $(OUTPUT_DIR)

# images

.PHONY: images
images: $(ALL_BUILD_IMGS)

# $(ALL_BUILD_IMGS): build/%/img/%: %/img/%
# 	@mkdir -p $(dir $@)
# 	cp $< $@

$(OUTPUT_DIR)/$(LECTURES_DIR)/$(IMAGE_DIR)/%: $(LECTURES_DIR)/$(IMAGE_DIR)/%
	@mkdir -p $(dir $@)
	cp $< $@

$(OUTPUT_DIR)/$(ASSESSMENTS_DIR)/$(IMAGE_DIR)/%: $(ASSESSMENTS_DIR)/$(IMAGE_DIR)/%
	@mkdir -p $(dir $@)
	cp $< $@

$(OUTPUT_DIR)/$(RESOURCES_DIR)/$(IMAGE_DIR)/%: $(RESOURCES_DIR)/$(IMAGE_DIR)/%
	@mkdir -p $(dir $@)
	cp $< $@

$(OUTPUT_DIR)/$(WORKSHOPS_DIR)/$(IMAGE_DIR)/%: $(WORKSHOPS_DIR)/$(IMAGE_DIR)/%
	@mkdir -p $(dir $@)
	cp $< $@

# Pandoc settings
# -V revealjs-url=https://unpkg.com/reveal.js@4.5.0
PANDOC = pandoc
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

PDF_OPTS = --metadata date="$(date '+%Y-%m-%d')" \
					 --number-sections=true \
					 -V 'geometry: left=2.5cm,right=2.5cm,top=2.5cm,bottom=2.5cm' \
		       -V 'papersize: a4' \
					 -V 'fontsize:11pt' \
					 -V 'pagestyle:headings' \
					 --pdf-engine=lualatex \
					 -V mainfont="Linux Libertine O" \
					 -V sansfont="Noto Sans" \
					 -V mainfontfallback="NotoColorEmoji:mode=harf" \

# 					 -V 'fontfamily:libertine,sourcecodepro' \


# --include-in-header css/slides.css \
# -V theme=night

BEAMER_OPTS = -t beamer \
              -V aspectratio=169 \
							-V theme=metropolis \
							-V colortheme=owl \
							--pdf-engine=lualatex \
							-V mainfont="Noto Sans" \
							-V mainfontfallback="NotoColorEmoji:mode=harf" \

# --pdf-engine=xelatex
# options for the pandoc HTML writer
HTML_OPTS = -V mainfont="system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif"

# Find all markdown lecture files
LECTURE_MDS = $(wildcard $(LECTURES_DIR)/*.md)
REVEAL_HTMLS = $(patsubst $(LECTURES_DIR)/%.md,$(LECTURES_OUT)/%.html,$(LECTURE_MDS))
BEAMER_PDFS = $(patsubst $(LECTURES_DIR)/%.md,$(LECTURES_OUT)/%.pdf,$(LECTURE_MDS))

# Find all markdown resources
RESOURCES_MDS = $(wildcard $(RESOURCES_DIR)/*.md)
RESOURCES_HTMLS = $(patsubst $(RESOURCES_DIR)/%.md,$(RESOURCES_OUT)/%.html,$(RESOURCES_MDS))

$(RESOURCES_OUT)/%.html: $(RESOURCES_DIR)/%.md
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(HTML_OPTS) $< -o $@

# Generate resources
.PHONY: resources
resources: $(RESOURCES_OUT) $(RESOURCES_HTMLS)

# Find all markdown assessments
ASSESSMENTS_MDS = $(wildcard $(ASSESSMENTS_DIR)/*.md)
ASSESSMENTS_HTMLS = $(patsubst $(ASSESSMENTS_DIR)/%.md,$(ASSESSMENTS_OUT)/%.html,$(ASSESSMENTS_MDS))
ASSESSMENTS_PDFS = $(patsubst $(ASSESSMENTS_DIR)/%.md,$(ASSESSMENTS_OUT)/%.pdf,$(ASSESSMENTS_MDS))


$(ASSESSMENTS_OUT)/%.html: $(ASSESSMENTS_DIR)/%.md
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(HTML_OPTS) $< -o $@

$(ASSESSMENTS_OUT)/%.pdf: $(ASSESSMENTS_DIR)/%.md
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(PDF_OPTS) $< -o $@

# Generate assessments
.PHONY: assessments
assessments: $(ASSESSMENTS_OUT) $(ASSESSMENTS_HTMLS) $(ASSESSMENTS_PDFS)

# Find all markdown workshops
WORKSHOPS_MDS = $(wildcard $(WORKSHOPS_DIR)/*.md)
WORKSHOPS_HTMLS = $(patsubst $(WORKSHOPS_DIR)/%.md,$(WORKSHOPS_OUT)/%.html,$(WORKSHOPS_MDS))

$(WORKSHOPS_OUT)/%.html: $(WORKSHOPS_DIR)/%.md $(REFERENCES)
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(HTML_OPTS) $< -o $@

# Generate workshops
.PHONY: workshops
workshops: $(WORKSHOPS_OUT) $(WORKSHOPS_HTMLS)

.PHONY: directories
directories: $(LECTURES_OUT) $(WORKSHOPS_OUT) $(ASSESSMENTS_OUT) $(RESOURCES_OUT)

# Create output directories
$(LECTURES_OUT) $(WORKSHOPS_OUT) $(ASSESSMENTS_OUT) $(RESOURCES_OUT):
	mkdir -p $@

# Generate Reveal.js presentations
.PHONY: reveal
reveal: $(LECTURES_OUT) $(REVEAL_HTMLS) images $(LECTURES_OUT)/reveal_dark.css

$(LECTURES_OUT)/%.html: $(LECTURES_DIR)/%.md
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(REVEAL_OPTS) $< -o $@

# Styles
%/reveal_dark.css: css/reveal_dark.scss
	sass --style=compressed css/reveal_dark.scss $@

# Generate Beamer Lecture PDFs

.PHONY: beamer
beamer: $(LECTURES_OUT) $(BEAMER_PDFS)

$(LECTURES_OUT)/%.pdf: $(LECTURES_DIR)/%.md
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(BEAMER_OPTS) $< -o $@

# Index

$(INDEX_HTML): $(LECTURE_MDS) $(ASSESSMENTS_MDS) $(WORKSHOPS_MDS) $(RESOURCES_MDS) $(INDEX_GENERATOR)
	python3 $(INDEX_GENERATOR) $@ $(OUTPUT_DIR)

.PHONY: index
index: $(INDEX_HTML)

# Mega PDFs for lectures and tutorials.

ALL_LECTURES = $(OUTPUT_DIR)/all_lectures.pdf
ALL_ASSESSMENTS = $(OUTPUT_DIR)/all_assessments.pdf
ALL_WORKSHOPS = $(OUTPUT_DIR)/all_workshops.pdf

$(ALL_LECTURES): $(LECTURE_MDS)
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(PDF_OPTS) --metadata title="All Lectures" --metadata author="Course Author" --metadata date="2025" --toc=true -o $@ $^

$(ALL_ASSESSMENTS): $(ASSESSMENTS_MDS)
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(PDF_OPTS) --metadata title="All Assessments" --metadata author="Course Author" --metadata date="2025" --toc=true -o $@ $^

$(ALL_WORKSHOPS): $(WORKSHOPS_MDS)
	$(PANDOC) $(PANDOC_COMMON_OPTS) $(PDF_OPTS) --metadata title="All Workshops" --metadata author="Course Author" --metadata date="2025" --toc=true -o $@ $^

.PHONY: bigfiles
bigfiles: $(ALL_LECTURES) $(ALL_ASSESSMENTS) $(ALL_WORKSHOPS)

# Mega Markdown files for lectures, assessments, and workshops.

ALL_LECTURES_MD = $(OUTPUT_DIR)/all_lectures.md
ALL_ASSESSMENTS_MD = $(OUTPUT_DIR)/all_assessments.md
ALL_WORKSHOPS_MD = $(OUTPUT_DIR)/all_workshops.md

$(ALL_LECTURES_MD): $(LECTURE_MDS)
	cat $^ > $@

$(ALL_ASSESSMENTS_MD): $(ASSESSMENTS_MDS)
	cat $^ > $@

$(ALL_WORKSHOPS_MD): $(WORKSHOPS_MDS)
	cat $^ > $@

.PHONY: bigmd
bigmd: $(OUTPUT_DIR) $(ALL_LECTURES_MD) $(ALL_ASSESSMENTS_MD) $(ALL_WORKSHOPS_MD)
