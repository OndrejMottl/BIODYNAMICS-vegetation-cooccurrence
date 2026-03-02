---
applyTo: "**/*.qmd"
description: >
  Conventions for building and maintaining the Quarto website for this
  project. Applies when creating, editing, or extending any .qmd page,
  updating _quarto.yml, adding function documentation pages, or working
  with the website/ folder.
---

# Quarto Website Conventions

## Overview

This project hosts a Quarto website rendered to the `docs/` directory and
published via GitHub Pages. The site serves as the project's public-facing
documentation, combining narrative pages, embedded visualisations, and
auto-generated function reference pages.

---

## Project Configuration (`_quarto.yml`)

The root `_quarto.yml` file controls the entire site. Key settings:

```yaml
project:
  type: website
  output-dir: docs

website:
  title: "<project-title>"
  page-footer:
    right: "This page is built with ❤️ and [Quarto](https://quarto.org/)."
  site-url: https://ondrejmottl.github.io/<repo-name>/
  repo-url: https://github.com/OndrejMottl/<repo-name>
  issue-url: https://github.com/OndrejMottl/<repo-name>/issues
  repo-actions: [source, issue]
  back-to-top-navigation: true

  sidebar:
    pinned: true
    align: center
    style: "docked"
    collapse-level: 1
    contents:
      - text: "About the project"
        href: website/about.qmd
      - text: "Reproducibility"
        href: website/installation.qmd
      - section: "Documentation"
        contents:
          - text: "Project overview"
            href: website/Documentation/documentation.qmd
          - section: "Functions"
            contents: "website/Documentation/Functions/*.qmd"

format:
  html:
    theme:
      - superhero
    toc: true
    toc-location: right
    toc-depth: 2
```

- **Theme**: `superhero` (Bootstrap-based Quarto theme).
- **Navigation**: Docked sidebar, pinned, centered, `collapse-level: 1`.
- **TOC**: right-side, depth 2.
- Function `.qmd` files are auto-discovered via glob pattern in the sidebar.

---

## Page File Locations

| Purpose | Path |
|---|---|
| Homepage | `index.qmd` |
| Project overview | `website/about.qmd` |
| Reproducibility | `website/installation.qmd` |
| Documentation landing page | `website/Documentation/documentation.qmd` |
| Individual function pages | `website/Documentation/Functions/<function_name>.qmd` |

---

## Standard YAML Front Matter

All narrative pages (`about.qmd`, `installation.qmd`, `documentation.qmd`,
`index.qmd`) use this front matter:

```yaml
---
date: YYYY/MM/DD
date-format: long
date-modified: last-modified
---
```

Auto-generated function documentation pages use:

```yaml
---
format: html
title: function_name()
---
```

---

## Code Chunk Conventions

All R code in `.qmd` files must follow the project's R coding conventions
defined in `.github/instructions/r-coding.instructions.md`.

All code chunks in website pages should use these options unless there is a
specific reason to deviate:

```r
#| label: descriptive-label
#| echo: false
#| output: true      # or false if the chunk only computes side-effects
#| message: false
#| warning: false
#| error: false
```

Always wrap library calls in `suppressMessages(suppressWarnings({...}))` when
loading packages silently inside a rendered `.qmd`.

---

## Reading `{targets}` Outputs in Pages

The target store path is composed of **two parts**: the project-level store
directory (from `config.yml` via `get_active_config()`) and the
**pipeline type** subdirectory (e.g. `"pipeline_basic"`, `"pipeline_time"`).

Build the store path first, then pass it to `tar_read()`:

```r
library(targets)
library(here)
here::i_am("website/about.qmd")   # adjust path to current file

# Pipeline type — must match the pipeline script name in
# R/02_Main_analyses/
vec_pipelines <- "pipeline_basic"

# Construct the store path:
#   {target_store from config}/{pipeline_name}/
set_store <-
  paste0(
    get_active_config("target_store"), "/", vec_pipelines, "/"
  ) |>
  here::here()

targets::tar_read(
  name = "target_name",
  store = set_store
)
```

The active configuration (project) is controlled via:

```r
Sys.setenv(R_CONFIG_ACTIVE = "project_cz")
# or
Sys.setenv(R_CONFIG_ACTIVE = "project_europe")
```

This determines which `target_store` path is returned by
`get_active_config("target_store")`. Combined with the pipeline subdirectory,
each project × pipeline combination has its own isolated store.

---

## Embedding Interactive Reports (iframes)

Use plain HTML iframes to embed interactive HTML reports stored in `docs/`:

```html
<iframe
  src="/Documentation/Progress/project_status.html"
  width="100%"
  height="500px"
  style="border:none;">
</iframe>
```

Paths inside `src` are relative to the site root (`docs/`).

---

## Status Badges

Use [shields.io](https://shields.io/) for dynamic and static badges:

```markdown
![](https://img.shields.io/badge/status-WIP-red)

![](https://img.shields.io/badge/dynamic/json?url=<url>&query=<jsonpath>&label=<label>&color=orange&style=flat-square&suffix=%25)
```

---

## Documentation Landing Page (`documentation.qmd`)

The documentation overview page uses a Quarto listing to display all function
pages as a grid:

```yaml
---
listing:
  - id: functions
    max-description-length: 100
    fields: [title]
    contents: "Functions"
    type: grid
    grid-item-border: true
---
```

Render the listing inside the page body with:

```markdown
::: {#functions}
:::
```

---

## Function Documentation Workflow

Function documentation pages are **auto-generated** — do not edit them
manually.

### Process

1. Every function in `R/Functions/` must have `roxygen2` documentation (see
   `.github/instructions/make_roxygen2_documentation.instructions.md`).
2. Run `R/03_Supplementary_analyses/Document_functions.R` to:
   a. Generate `.html` and `.txt` files from `roxygen2` comments into
      `Documentation/Functions/`.
   b. Convert each `.html` file into a `.qmd` file inside
      `website/Documentation/Functions/`.
3. Each generated `.qmd` has a YAML header followed by the raw HTML from the
   `{document}` package output:

   ```yaml
   ---
   format: html
   title: function_name()
   ---
   ```

   The rest of the file is the HTML documentation rendered by `{document}`.

### Re-generating documentation

After adding or editing a function's `roxygen2` comments, re-run:

```r
source("R/___setup_project___.R")
source("R/03_Supplementary_analyses/Document_functions.R")
```

Then re-render the Quarto site.

---

## Rendering the Website

Render the whole site from the project root:

```r
quarto::quarto_render()
```

Or from the terminal:

```bash
quarto render
```

Output lands in `docs/`. Do **not** manually edit files under `docs/`.

---

## Safe Paths in `.qmd` Files

Always anchor file paths with `here::here()` and declare the current file
with `here::i_am()` at the top of any code chunk that uses paths:

```r
here::i_am("website/Documentation/documentation.qmd")
source(here::here("R/___setup_project___.R"))
```

---

## Adding a New Page

1. Create a `.qmd` file in the appropriate `website/` subdirectory.
2. Use the standard YAML front matter (see above).
3. Add the page's `href` to the `sidebar > contents` section in `_quarto.yml`.
4. Re-render with `quarto render`.
