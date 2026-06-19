# BIODYNAMICS - Vegetation Co-occurrence

<!-- badges: start -->
![Static Badge](https://img.shields.io/badge/status-WIP-red)
![Static Badge](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/main/Documentation/Functions_test_coverage/covr_report_summary.json&query=$.value&label=codecov&color=orange&style=flat-square&suffix=%25)
<!-- badges: end -->

This repository contains the BIODYNAMICS vegetation co-occurrence analysis.
The project asks how plant co-occurrence patterns can be partitioned into shared climate responses, spatial or spatiotemporal structure, and residual association signals.

Project website: <https://ondrejmottl.github.io/BIODYNAMICS-vegetation-cooccurrence/>

## Status

This project is work in progress.
Methods, code, function documentation, pipeline progress views, and conference materials are public, but results are still preliminary until the manuscript is finalised.

## Repository Map

| Path | Purpose |
|---|---|
| `R/Functions/` | Custom R functions used by the pipelines |
| `R/Pipelines/` | Active `{targets}` pipeline entry points |
| `R/Pipelines/_pipes/` | Reusable pipeline construction segments |
| `Data/Input/` | Input tables such as spatial grids and manual correction tables |
| `Documentation/Website/` | Quarto website source pages |
| `Documentation/Manuscript/` | Manuscript source |
| `Documentation/Presentations/` | Presentation sources and rendered presentation material |
| `Documentation/Progress/` | Generated pipeline progress visualisations |
| `docs/` | Rendered website for GitHub Pages |

## Reproducibility Quick Start

Restore the R environment:

```r
renv::restore()
```

Set up and verify the `{sjSDM}` backend:

```r
sjSDM::install_sjSDM()

source("R/___setup_project___.R")
verify_sjsdm_setup()
```

Run a small paleo development pipeline:

```r
library(here)

source(here::here("R/___setup_project___.R"))

Sys.setenv(R_CONFIG_ACTIVE = "project_cz_paleo")

run_pipeline(
  sel_script = "R/Pipelines/pipeline_paleo_core.R",
  fresh_run = FALSE,
  plot_progress = TRUE
)
```

Spatial pipelines use a `store_suffix` for each geographic unit:

```r
Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_spatial_continental")

run_pipeline(
  sel_script = "R/Pipelines/pipeline_paleo_spatial_resolution.R",
  store_suffix = "europe"
)
```

## Active Pipelines

| Pipeline | Main use |
|---|---|
| `pipeline_paleo_core.R` | Compact paleo test workflow |
| `pipeline_paleo_temporal.R` | Paleo temporal models by time slice |
| `pipeline_paleo_spatial_resolution.R` | Paleo spatial models by unit and resolution |
| `pipeline_paleo_resolution_test.R` | Development checks for paleo resolution routing |
| `pipeline_modern_spatial_resolution.R` | Modern spatial models by unit and resolution |
| `pipeline_modern_spatial_resolution_test.R` | Development checks for modern spatial routing |
| `pipeline_traits_reference.R` | Trait processing and functional-type reference generation |

## Active Configurations

| Configuration | Purpose |
|---|---|
| `project_cz_paleo` | Small paleo development runs |
| `project_cz_modern` | Small modern development runs |
| `project_traits_reference` | Trait reference and functional-type workflow |
| `project_paleo_temporal_europe` | Paleo temporal Europe |
| `project_paleo_temporal_america` | Paleo temporal North America |
| `project_paleo_temporal_asia` | Paleo temporal northern Asia |
| `project_paleo_spatial_continental` | Paleo spatial continental units |
| `project_paleo_spatial_regional` | Paleo spatial regional units |
| `project_paleo_spatial_local` | Paleo spatial local units |
| `project_modern_spatial_continental` | Modern spatial continental units |
| `project_modern_spatial_regional` | Modern spatial regional units |
| `project_modern_spatial_local` | Modern spatial local units |

## Data Requirements

Most analyses require a local VegVault SQLite database plus configuration values that point to the relevant data paths.
The repository contains code, documentation, configuration, and public derived materials, but large local target stores and database files may not be fully reproducible from GitHub alone.

See the [Reproducibility](https://ondrejmottl.github.io/BIODYNAMICS-vegetation-cooccurrence/Documentation/Website/installation.html) page for current setup and execution details.
