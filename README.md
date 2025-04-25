# BIODYNAMICS -  Vegetation Co-occurrence

This is a project to study the co-occurrence of vegetation across space and time. The repo is of the [BIODYNAMICS](https://bit.ly/BIODYNAMICS) project.

## Work in Progress

![Static Badge](https://img.shields.io/badge/status-WIP-red)

This project is a work in progress. The code is not yet ready!.
  
Currently, the project is coded as {[targets](https://docs.ropensci.org/targets/)} pipeline and can be executed using the following command:

``` r
source(
  here::here("R/02_Main_analyses/01_Run_pipeline.R")
)
```

### Curent Status

This is the visualization, which represent the current status of the project:

![](/Outputs/Figures/project_status_static.png)

## Reproducibility

## {[renv](https://rstudio.github.io/renv/)}

This project uses the {renv} package to manage dependencies. To install the required packages, run the following command in the R console:

``` r
renv::restore()
```

This will install all the packages listed in the `renv.lock` file.

## Documentation

Individial functions are documented using the {[roxygen2](https://roxygen2.r-lib.org/)} package. You can can se ethe function documentsation in the `Documentation/Functions` folder.

## Testing functions

![Static Badge](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/OndrejMottl/BIODYNAMICS-vegetation-cooccurrence/main/Documentation/Functions_test_coverage/covr_report_summary.json&query=$.value&label=codecov&color=orange&style=flat-square&suffix=%25)

This project uses the {[testthat](https://testthat.r-lib.org/)} package to test the functions. As it is not a package, the tests are manually run.

The report of the {[covr](https://covr.r-lib.org/)} package can be found in the `Documentation/Functions_test_coverage` folder.
