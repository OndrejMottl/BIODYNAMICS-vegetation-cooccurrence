# Paleo community age-uncertainty tests

## Backstory

Paleo community interpolation has two age paths. Datasets without age-model iterations use their consensus ages, while fossil pollen archives expand each sample across bounded batches of age-model iterations and retain the median interpolated proportion.

These tests were moved from the former top-level `test-interpolate_community_data_with_uncertainty.R` during issue #153. They protect the public paleo workflow, batch-size invariance, validation, and agreement between consensus-age interpolation and the generic grouped time-series core.

## Running the tests

After sourcing `R/___setup_project___.R`, run:

```r
testthat::test_dir(
  here::here(
    "R/03_Supplementary_analyses/Testing/testthat/Data/Time/Interpolation",
    "Community/Age_uncertainty"
  )
)
```
