#----------------------------------------------------------#
#
#                 Vegetation Co-occurrence
#
#           Render trait analysis-readiness report
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#

library(here)

Sys.setenv(
  BIODYNAMICS_PREPROCESSING_WORKER = "false",
  BIODYNAMICS_PREPROCESSING_WORKERS = ""
)

path_report_source <-
  here::here(
    "R/03_Supplementary_analyses/One_time/Trait_corrections/",
    "trait_analysis_readiness_report.qmd"
  )
path_output_directory <-
  here::here(
    "Outputs/Reports/Trait_corrections/analysis_readiness"
  )
path_report <-
  base::file.path(
    path_output_directory,
    "trait_analysis_readiness_report.md"
  )

assertthat::assert_that(
  base::file.exists(path_report_source),
  msg = "The trait analysis-readiness report source is missing."
)
base::dir.create(
  path_output_directory,
  recursive = TRUE,
  showWarnings = FALSE
)

knitr::knit(
  input = path_report_source,
  output = path_report,
  envir = base::new.env(parent = base::globalenv()),
  quiet = FALSE
)

assertthat::assert_that(
  base::file.exists(path_report),
  msg = "The trait analysis-readiness report was not rendered."
)
base::message("Rendered trait analysis-readiness report: ", path_report)
