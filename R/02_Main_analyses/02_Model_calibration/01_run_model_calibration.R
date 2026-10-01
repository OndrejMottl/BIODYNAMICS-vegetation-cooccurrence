#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Run stage 02: model calibration
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Workflow contract:
#   Requires stage 01 preparation. It inventories cached folds, calibrates all
#   representatives sequentially, publishes budgets, and validates config.yml.
#   Accepted representative results are reused after interruption.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)
source(here::here("R/___setup_project___.R"))
run_id <-
  base::format(base::Sys.time(), "%Y%m%d_%H%M%S")
path_component_root <-
  "R/02_Main_analyses/02_Model_calibration/_components"


#----------------------------------------------------------#
# 1. Build preparation inventory -----
#----------------------------------------------------------#

run_main_analysis_stage(
  stage_id = "02_model_calibration",
  data_components = tibble::tibble(
    component_id = "01_build_calibration_inventory",
    script_path = fs::path(
      path_component_root,
      "01_build_sjsdm_cv_calibration_inventory.R"
    )
  ),
  run_id = run_id
)


#----------------------------------------------------------#
# 2. Calibrate every selected representative -----
#----------------------------------------------------------#

file_representatives <-
  here::here(
    "Documentation",
    "Reports",
    "Model_calibration",
    "sjsdm_cv_fit_budget",
    "calibration_representatives.csv"
  )
data_representatives <-
  readr::read_csv(file_representatives, show_col_types = FALSE) |>
  dplyr::mutate(
    profile_id = dplyr::if_else(
      .data[["is_temporal"]],
      stringr::str_c(
        "project_paleo_temporal_",
        .data[["continent_id"]]
      ),
      stringr::str_c(
        "project_",
        .data[["analysis_id"]],
        "_",
        .data[["tier_id"]]
      )
    ),
    component_id = stringr::str_c(
      "02_calibrate_",
      .data[["profile_id"]],
      "_",
      .data[["scale_id"]],
      "_",
      .data[["resolution_id"]]
    )
  ) |>
  dplyr::rowwise() |>
  dplyr::mutate(
    environment = base::list(
      stats::setNames(
        base::c(
          .data[["profile_id"]],
          .data[["scale_id"]],
          .data[["resolution_id"]]
        ),
        base::c(
          "SJSMD_CALIBRATION_PROFILE",
          "SJSMD_CALIBRATION_SCALE_ID",
          "SJSMD_CALIBRATION_RESOLUTION"
        )
      )
    )
  ) |>
  dplyr::ungroup()
data_calibration_components <-
  data_representatives |>
  dplyr::transmute(
    component_id = .data[["component_id"]],
    script_path = fs::path(
      path_component_root,
      "02_run_one_sjsdm_cv_fit_budget_calibration.R"
    ),
    environment = .data[["environment"]]
  )

run_main_analysis_stage(
  stage_id = "02_model_calibration",
  data_components = data_calibration_components,
  run_id = run_id,
  continue_on_error = TRUE
)


#----------------------------------------------------------#
# 3. Publish budgets and validate generated configuration -----
#----------------------------------------------------------#

data_publication_components <-
  tibble::tibble(
    component_id = base::c(
      "03_publish_cv_fit_budgets",
      "04_generate_configuration",
      "05_validate_configuration"
    ),
    script_path = base::c(
      fs::path(
        path_component_root,
        "03_publish_sjsdm_cv_fit_budgets.R"
      ),
      "R/03_Supplementary_analyses/Validation/Configuration/",
      "R/03_Supplementary_analyses/Validation/Configuration/"
    )
  ) |>
  dplyr::mutate(
    script_path = dplyr::case_when(
      .data[["component_id"]] == "04_generate_configuration" ~
        stringr::str_c(.data[["script_path"]],
                       "Generate_configuration.R"),
      .data[["component_id"]] == "05_validate_configuration" ~
        stringr::str_c(.data[["script_path"]],
                       "Check_configuration.R"),
      .default = .data[["script_path"]]
    )
  )

data_stage_status <-
  run_main_analysis_stage(
    stage_id = "02_model_calibration",
    data_components = data_publication_components,
    run_id = run_id,
    next_stage_script = paste(
      "R/02_Main_analyses/03_Model_fitting/",
      "01_run_model_fitting.R",
      sep = ""
    )
  )
