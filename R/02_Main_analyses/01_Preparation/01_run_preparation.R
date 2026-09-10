#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#                 Run stage 01: preparation
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Workflow contract:
#   This is the first main-analysis entry point. It prepares every spatial and
#   temporal CV fold without tuning or fitting models. Reruns reuse targets.
#   Expected data limitations are accepted. Independent components all run;
#   unexplained target failures are reported together when the stage finishes.
#   On success, continue with stage 02 model calibration.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)
source(here::here("R/___setup_project___.R"))

vec_runner_arguments <-
  base::commandArgs(trailingOnly = TRUE)
assertthat::assert_that(
  base::length(vec_runner_arguments) <= 2L,
  msg = paste(
    "Preparation accepts at most two arguments:",
    "resource profile and optional worker override."
  )
)
resource_profile <-
  if (
    base::length(vec_runner_arguments) >= 1L
  ) {
    vec_runner_arguments[[1L]]
  } else {
    "shared"
  }
assertthat::assert_that(
  resource_profile %in% base::c("shared", "dedicated", "configured"),
  msg = paste(
    "The preparation resource profile must be shared,",
    "dedicated, or configured."
  )
)
workers_override <-
  if (
    base::length(vec_runner_arguments) == 2L
  ) {
    base::suppressWarnings(
      base::as.numeric(vec_runner_arguments[[2L]])
    )
  } else {
    NULL
  }
assertthat::assert_that(
  base::is.null(workers_override) ||
    (
      base::is.finite(workers_override) &&
        workers_override >= 1L &&
        workers_override == base::as.integer(workers_override)
    ),
  msg = "The optional worker override must be a positive integer."
)
vec_component_arguments <-
  base::c(
    resource_profile,
    if (
      base::is.null(workers_override)
    ) {
      base::character()
    } else {
      base::as.character(base::as.integer(workers_override))
    }
  )
cli::cli_inform(
  base::c(
    "i" = "Preparation resource profile: {.field {resource_profile}}.",
    "i" = paste(
      "Shared caps interpolation at 4 workers; dedicated caps it at 8.",
      "Available memory may lower either count."
    ),
    "i" = if (
      base::is.null(workers_override)
    ) {
      "No explicit worker override was requested."
    } else {
      stringr::str_glue(
        "Requested worker override: {workers_override}."
      )
    }
  )
)


#----------------------------------------------------------#
# 1. Run preparation components -----
#----------------------------------------------------------#

path_component_root <-
  "R/02_Main_analyses/01_Preparation/_components"
vec_component_files <-
  base::c(
    "01_prepare_paleo_spatial_continental.R",
    "02_prepare_paleo_spatial_regional.R",
    "03_prepare_paleo_spatial_local.R",
    "04_prepare_modern_spatial_continental.R",
    "05_prepare_modern_spatial_regional.R",
    "06_prepare_modern_spatial_local.R",
    "07_prepare_paleo_temporal_europe.R",
    "08_prepare_paleo_temporal_america.R",
    "09_prepare_paleo_temporal_asia.R"
  )
data_components <-
  tibble::tibble(
    component_id = stringr::str_remove(vec_component_files, "[.]R$"),
    script_path = fs::path(path_component_root, vec_component_files),
    arguments = base::rep(
      base::list(vec_component_arguments),
      base::length(vec_component_files)
    )
  )
run_id <-
  base::format(base::Sys.time(), "%Y%m%d_%H%M%S")

data_stage_status <-
  run_main_analysis_stage(
    stage_id = "01_preparation",
    data_components = data_components,
    run_id = run_id,
    continue_on_error = TRUE,
    next_stage_script = paste(
      "R/02_Main_analyses/02_Model_calibration/",
      "01_run_model_calibration.R",
      sep = ""
    )
  )
