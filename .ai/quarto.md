# Quarto Guidance

Canonical guidance for Quarto documentation and website work in this repository.

# Quarto Website Conventions

## Overview

This project hosts a Quarto website rendered to the `docs/` directory and published via GitHub Pages. The site serves as the project's public-facing documentation, combining narrative pages, embedded visualisations, and auto-generated function reference pages.

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
    right: "This page is built with [Quarto](https://quarto.org/)."
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
        href: Documentation/Website/about.qmd
      - text: "Reproducibility"
        href: Documentation/Website/installation.qmd
      - section: "Documentation"
        contents:
          - text: "Project overview"
            href: Documentation/Website/Documentation/documentation.qmd
          - section: "Functions"
            contents: "Documentation/Website/Documentation/Functions/*.qmd"

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
| Project overview | `Documentation/Website/about.qmd` |
| Reproducibility | `Documentation/Website/installation.qmd` |
| Documentation landing page | `Documentation/Website/Documentation/documentation.qmd` |
| Individual function pages | `Documentation/Website/Documentation/Functions/<function_name>.qmd` |

---

## Prose Formatting

Write prose with **each sentence on its own line** in the source file.
A blank line separates paragraphs.
This convention makes it easy to track changes, leave comments, and edit individual sentences in manuscript `.qmd` files without disturbing surrounding text.

**Never break a sentence mid-way through to stay within 80 characters (or any other column limit).** The 80-character line-length rule that applies to R scripts does **not** apply to `.qmd` files. A sentence must be kept whole on one line, regardless of its length.

```markdown
<!-- WRONG â€” multiple sentences merged onto one line -->
All records were sourced from VegVault. Data were extracted using {vaultkeepr}.

<!-- WRONG â€” sentence broken mid-way to fit 80 characters -->
All records were sourced from VegVault, a harmonised SQLite database integrating
fossil pollen archives and modern plot data.

<!-- CORRECT â€” one complete sentence per line -->
All records were sourced from VegVault, a harmonised SQLite database integrating fossil pollen archives and modern plot data.
Data were extracted using {vaultkeepr}.
```

Quarto renderers treat a single line break within a paragraph as a space, so the rendered output is identical in both cases.

---

## Standard YAML Front Matter

All narrative pages (`about.qmd`, `installation.qmd`, `documentation.qmd`, `index.qmd`) use this front matter:

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

## Reproducibility

### Random seed

Always set the project seed before any call that uses randomness:

```r
base::set.seed(900723)
```

Place the `set.seed()` call at the start of the chunk that generates random data, or in the setup chunk if randomness is used throughout the file. This ensures outputs are reproducible across renders and collaborators.

---

## No Hardcoded Numbers in Prose

Every number that is derived from data or an analysis result must be an inline R expression  -  never a hardcoded literal. Hardcoded numbers become silently wrong when the underlying data or model changes.

````markdown
<!-- WRONG -->
The model was evaluated on 42 taxa with an average AUC of 0.87.

<!-- CORRECT -->
The model was evaluated on `r nrow(model_evaluation$species)` taxa
with an average AUC of `r round(mean(model_evaluation$species$AUC), 2)`.
````

This applies to:
- counts (number of functions, taxa, datasets, samples)
- model metrics (AUC, RÂ², RMSE)
- summary statistics reported in text
- any value that could change if data or code changes
- **analysis parameters and thresholds stored in `config.yml`** â€” these must be read via `config::get()` in a code chunk and referenced as inline R expressions, even though they are deliberate analysis choices. Hardcoding them in prose means the text silently diverges from the actual values whenever the configuration is updated.

The only acceptable literals in prose are values that are truly external constants â€” e.g. a standard geographic projection code such as `EPSG:3035`, or a published database version number that cannot change.

### Reading `config.yml` values in `.qmd` files

Declare a named setup chunk (e.g. `config-thresholds`) early in the file that reads every parameter you intend to reference:

```r
#| label: config-thresholds
#| echo: false
#| output: false
#| message: false
#| warning: false
#| error: false
here::i_am("Documentation/Manuscript/sections/your_file.qmd")

config_spatial_continental <-
  config::get(
    config = "project_paleo_spatial_continental",
    file = here::here("config.yml")
  )

min_n_taxa_continental <-
  config_spatial_continental$data_processing$min_n_taxa
```

Then reference the variable inline:

```markdown
A unit was excluded if fewer than `r min_n_taxa_continental` taxa remained.
```

---

## Code Chunk Conventions

All R code in `.qmd` files must follow the project's R coding conventions defined in `.ai/r-coding.md`.

All code chunks in website pages should use these options unless there is a specific reason to deviate:

```r
#| label: descriptive-label
#| echo: false
#| output: true      # or false if the chunk only computes side-effects
#| message: false
#| warning: false
#| error: false
```

Always wrap library calls in `suppressMessages(suppressWarnings({...}))` when loading packages silently inside a rendered `.qmd`.

---

## Reading `{targets}` Outputs in Pages

The target store path is composed of **two parts**: the project-level store directory (from `config.yml` via `get_active_config()`) and the **pipeline type** subdirectory (e.g. `"pipeline_paleo_core"`, `"pipeline_paleo_temporal"`).

Build the store path first, then pass it to `tar_read()`:

```r
library(targets)
library(here)
here::i_am("Documentation/Website/about.qmd")   # adjust path to current file

# Pipeline type  -  must match the pipeline script name in
# R/02_Main_analyses/
vec_pipelines <- "pipeline_paleo_core"

# Construct the store path:
#   {target_store from config}/{pipeline_name}/
set_store <-
  here::here(
    get_active_config("target_store"),
    vec_pipelines
  )

targets::tar_read(
  name = "target_name",
  store = set_store
)
```

The active configuration (project) is controlled via:

```r
Sys.setenv(R_CONFIG_ACTIVE = "project_cz_paleo")
# or
Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_temporal_europe")
```

This determines which `target_store` path is returned by `get_active_config("target_store")`. Combined with the pipeline subdirectory, each project x pipeline combination has its own isolated store.

---

## Visualisation Patterns

### Saving and displaying plots

**Plot generation code is always hidden** The visualisation code (ggplot2, gganimate, ggview) runs silently during rendering. 

Never call `print()` or let ggplot2 render directly in a slide. Instead:

1. Build and save the plot in one hidden chunk:

```r
#| label: make a plot
#| echo: false
#| eval: true
figure_x <-
  ggplot2::ggplot(...) +
  ggview::canvas(
    width = 1600,
    height = 800,
    units = "px"
  )

ggview::save_ggplot(
  plot = figure_x,
  file = here::here(path_materials, "figure_name.png")
)
```

2. Display it in a separate chunk using `include_local_figure()`:

```r
#| label: display plot
#| echo: false
include_local_figure("figure_name.png")
```

Rules:
- Always append `ggview::canvas()` to the plot pipeline. This opens an interactive preview at the exact pixel dimensions during authoring, making it easy to adjust layout before committing. It has no effect at render time.
- Standard canvas dimensions: `width = 1600, height = 800` (landscape, full-slide). Adjust to `width = 800, height = 800` for square inset plots.
- Save with `ggview::save_ggplot()`  -  this respects the canvas dimensions and saves at the correct size.
- Always use `ggplot2::theme_minimal()` as the base theme for all plots.
- Use `ggplot2::labs()` for all axis labels and titles.
- Use `ggplot2::labs(title = "Title text")` instead of `ggtitle()`. This ensures the title is included in the saved image and displayed correctly in the slide.
- If a plot has a title, do not add a title in the slide  -  use empty `##` markdown heading syntax instead.

### Defining `include_local_figure()` in the setup chunk

Every `.qmd` file that displays local figures must define the `include_local_figure()` helper once in its setup chunk:

```r
path_to_materials <-
  here::here("Documentation/Materials")

include_local_figure <- function(data_source) {
  knitr::include_graphics(
    path = here::here(path_to_materials, data_source),
    error = TRUE
  )
}
```

Then use it consistently throughout the file:

```r
#| label: display-plot
#| echo: false
include_local_figure("Figures/my_plot.png")
```

### Combining multiple plots

Use `cowplot::plot_grid()` to arrange multiple ggplot objects into one figure before saving:

```r
#| label: make-combined-plot
#| echo: false
#| eval: true
plot_combined <-
  cowplot::plot_grid(
    plot_a,
    plot_b,
    ncol = 2
  ) +
  ggview::canvas(
    width = 1600,
    height = 800,
    units = "px"
  )

ggview::save_ggplot(
  plot = plot_combined,
  file = here::here(path_to_materials, "Figures", "combined_plot.png")
)
```

Rules:
- Build each sub-plot as a separate named object first, then combine.
- Apply `ggview::canvas()` and `ggview::save_ggplot()` to the *combined* object, not to individual sub-plots.
- Use `labels = c("A", "B")` only when the text explicitly references the panels; omit otherwise.

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

The documentation overview page uses a Quarto listing to display all function pages as a grid:

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

Function documentation pages are **auto-generated**  -  do not edit them manually.

### Process

1. Every function in `R/Functions/` must have `roxygen2` documentation (see `.ai/r-functions.md`).
2. Run `R/03_Supplementary_analyses/Documentation/Document_functions.R` to:
  a. Generate `.html` and `.txt` files from `roxygen2` comments into `Documentation/Functions/`.
  b. Convert each `.html` file into a `.qmd` file inside `Documentation/Website/Documentation/Functions/`.
3. Each generated `.qmd` has a YAML header followed by the raw HTML from the `{document}` package output:

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
library(here)

source(
  here::here("R/___setup_project___.R")
)
source("R/03_Supplementary_analyses/Documentation/Document_functions.R")
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

Always anchor file paths with `here::here()`. Never use raw relative paths (e.g. `"../Materials/Figures/plot.png"`)  -  they break when the working directory changes.

Declare the current file with `here::i_am()` once, in the **first (setup) code chunk** at the top of the file:

```r
#| label: setup
#| include: false
here::i_am("website/Documentation/documentation.qmd")
source(here::here("R/___setup_project___.R"))

# All subsequent paths built with here::here()
path_figures <- here::here("Documentation/Materials/Figures")
```

- Good: `here::here("Documentation/Materials/Figures", "plot.png")`
- Avoid: `"../Materials/Figures/plot.png"`  -  raw relative path, do not use

---

## Adding a New Page

1. Create a `.qmd` file in the appropriate `Documentation/Website/` subdirectory.
2. Use the standard YAML front matter (see above).
3. Add the page's `href` to the `sidebar > contents` section in `_quarto.yml`.
4. Re-render with `quarto render`.
