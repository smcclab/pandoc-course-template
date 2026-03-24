# Pandoc Course Template

A template for developing course materials (lectures, workshops, assessments, resources) in Markdown and building them into HTML presentations (reveal.js) and PDFs (Beamer/LaTeX) using pandoc.

## Getting Started

1. Create a new repository from this template (click "Use this template" on GitHub)
2. Edit `_config.toml` with your course title, institution, author, and year
3. Add your content as Markdown files in the `lectures/`, `assessments/`, `workshops/`, and `resources/` directories
4. Add references to `references.bib` in BibTeX format

## Content Structure

- `lectures/` — Slide decks (`.md`), built to reveal.js HTML + Beamer PDF
- `assessments/` — Assessment specs (`.md`), built to HTML + PDF
- `workshops/` — Workshop/tutorial activities (`.md`), built to HTML only
- `resources/` — Supplementary resources (`.md`), built to HTML only

Each content directory has its own `img/` subdirectory. Images cannot be shared across directories.

Citations use pandoc format: `[@bibtex-key]`, `[@bibtex-key, p26]`. Referencing style is APA (`apa.csl`).

## Building

Requires: `pandoc`, a TeX environment (e.g., MacTeX or TeX Live), `sass`, `python3`, and `make`.

```
make all      # Build everything
make html     # HTML only (faster, skips Beamer PDFs)
make public   # Like 'all' but excludes resources (used by CI)
make clean    # Remove the build/ output directory
```

See the Makefile for additional targets (`reveal`, `beamer`, `assessments`, `workshops`, `resources`, `bigfiles`).

## Deploying

The included GitHub Actions workflow (`.github/workflows/deploy.yml`) runs `make public` on push to `main` and deploys the `build/` directory to GitHub Pages. The `public` target excludes `resources/`, making them suitable for internal or staff-only materials.

## Contributing

Content developers can contribute by editing Markdown files in the content directories. See the example files included in each directory for the expected format and frontmatter.
