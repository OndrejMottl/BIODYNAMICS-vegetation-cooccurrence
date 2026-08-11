# Spatial-data function tests

This tree mirrors `R/Functions/Data/Spatial/` for reusable spatial-data construction and transformation contracts.

`Grid_generation/` currently covers the tile builder extracted from the guarded spatial-grid catalogue reference workflow. Tests verify clipping, deterministic identifiers, output schema, and invalid input contracts without writing `Data/Input/spatial_grid.csv`.

Run the focused tests from the repository root:

```powershell
Rscript -e "library(here); source(here::here('R/___setup_project___.R')); testthat::test_dir(here::here('R/03_Supplementary_analyses/Testing/testthat/Data/Spatial'))"
```
