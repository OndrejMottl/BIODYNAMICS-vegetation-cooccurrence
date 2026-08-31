#----------------------------------------------------------#
#
#                 Vegetation Co-occurrence
#
#       Render programmatic trait-review triage report
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
    "trait_review_programmatic_triage_report.qmd"
  )
path_output_directory <-
  here::here("Outputs/Reports/Trait_corrections/raw")
path_report <-
  base::file.path(
    path_output_directory,
    "trait_review_programmatic_triage_report.md"
  )

assertthat::assert_that(
  base::file.exists(path_report_source),
  msg = "The programmatic trait-review report source is missing."
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
  msg = "The programmatic trait-review report was not rendered."
)
base::message("Rendered programmatic trait-review report: ", path_report)
