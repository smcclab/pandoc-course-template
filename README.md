# Pandoc Course Template

A template for developing course materials (lectures, workshops, assessments, resources) in Markdown and building them into HTML presentations (reveal.js) and PDFs (Beamer/LaTeX) using pandoc.

Includes VS Code integration for live rebuilds, snippets, and a build task.

## Getting Started

1. Create a new repository from this template (click "Use this template" on GitHub)
2. Edit `_config.toml` with your course title, institution, author, and year
3. Add your content as Markdown files in the `lectures/`, `assessments/`, `workshops/`, and `resources/` directories
4. Add references to `references.bib` in BibTeX format

### Dev Container

A [dev container](https://containers.dev/) is included (`.devcontainer/`), providing a fully configured environment with pandoc, LaTeX, Dart Sass, Python, and Make — identical to the CI build environment. Open the repository in VS Code (or GitHub Codespaces) and choose **Reopen in Container** to get started immediately without any local tool installation.

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

## VS Code Integration

The `.vscode/` directory includes some quality-of-life configurations:

**Auto-rebuild on save** (via the [Run on Save](https://marketplace.visualstudio.com/items?itemName=emeraldwalk.RunOnSave) extension) — `make all` runs automatically whenever a Markdown file is saved. Pair this with the [Live Server](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer) extension (configured to serve from `build/`) to get a live preview in the browser as you edit.

**Build task** — `Cmd+Shift+B` (or `Ctrl+Shift+B`) runs `make all` from the VS Code task runner.

**Markdown snippets** — tab-completable shortcuts for common slide constructs:

| Prefix | Inserts |
|---|---|
| `slide` | New `##` slide |
| `section` | New `#` section title slide |
| `frontmatter` | YAML front matter with title-slide background image |
| `slidebg` | Slide heading with background image attribute |
| `columns` | Two-column layout |
| `notes` | Speaker notes block |
| `cite` / `citep` | Citation, with and without page number |
| `infobox` / `warnbox` / `errorbox` / `successbox` | Callout boxes |
| `think` / `talk` / `push` / `extension` | Activity instruction boxes |
| `activity` | Activity section box |
| `questions` | Questions section box |

## Contributing

Content developers can contribute by editing Markdown files in the content directories. See the example files included in each directory for the expected format and frontmatter.
