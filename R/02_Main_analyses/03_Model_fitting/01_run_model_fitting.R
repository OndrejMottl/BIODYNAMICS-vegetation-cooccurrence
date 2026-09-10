#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#                Run stage 03: model fitting
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Workflow contract:
#   Requires prepared folds from stage 01 and published CV budgets from stage
#   02. It runs tuning and final models sequentially and reuses cached targets.
#   On success, continue with stage 04 synthesis.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)
source(here::here("R/___setup_project___.R"))


#----------------------------------------------------------#
# 1. Run fitting components -----
#----------------------------------------------------------#

file_preparation_inventory <-
  here::here(
    "Documentation",
    "Reports",
    "Model_calibration",
    "sjsdm_cv_fit_budget",
    "calibration_unit_inventory.csv"
  )
file_budget_provenance <-
  here::here(
    "Documentation",
    "Reports",
    "Model_calibration",
    "sjsdm_cv_fit_budget",
    "budget_publication_provenance.csv"
  )
if (
  !base::file.exists(file_preparation_inventory)
) {
  cli::cli_abort(
    base::c(
      "Stage 03 cannot find validated preparation evidence.",
      "i" = stringr::str_c(
        "Run R/02_Main_analyses/01_Preparation/",
        "01_run_preparation.R, then stage 02 calibration."
      )
    )
  )
}
if (
  !base::file.exists(file_budget_provenance)
) {
  cli::cli_abort(
    base::c(
      "Stage 03 cannot find published CV-budget provenance.",
      "i" = stringr::str_c(
        "Run R/02_Main_analyses/02_Model_calibration/",
        "01_run_model_calibration.R first."
      )
    )
  )
}
data_preparation_inventory <-
  readr::read_csv(
    file_preparation_inventory,
    show_col_types = FALSE
  )
if (
  base::any(
    data_preparation_inventory[["preparation_status"]] %in%
      base::c("missing", "pipeline_error")
  )
) {
  cli::cli_abort(
    base::c(
      "Stage 03 is blocked by incomplete preparation evidence.",
      "i" = stringr::str_c(
        "Rerun R/02_Main_analyses/01_Preparation/",
        "01_run_preparation.R and stage 02 calibration."
      )
    )
  )
}

path_component_root <-
  "R/02_Main_analyses/03_Model_fitting/_components"
vec_component_files <-
  base::c(
    "01_fit_paleo_spatial_continental.R",
    "02_fit_paleo_spatial_regional.R",
    "03_fit_paleo_spatial_local.R",
    "04_fit_modern_spatial_continental.R",
    "05_fit_modern_spatial_regional.R",
    "06_fit_modern_spatial_local.R",
    "07_fit_paleo_temporal_europe.R",
    "08_fit_paleo_temporal_america.R",
    "09_fit_paleo_temporal_asia.R"
  )
data_components <-
  tibble::tibble(
    component_id = stringr::str_remove(vec_component_files, "[.]R$"),
    script_path = fs::path(path_component_root, vec_component_files)
  )
run_id <-
  base::format(base::Sys.time(), "%Y%m%d_%H%M%S")

data_stage_status <-
  run_main_analysis_stage(
    stage_id = "03_model_fitting",
    data_components = data_components,
    run_id = run_id,
    next_stage_script = paste(
      "R/02_Main_analyses/04_Synthesis/01_run_synthesis.R"
    )
  )
