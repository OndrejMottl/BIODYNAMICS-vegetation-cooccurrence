#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Smoke-test sjSDM CV calibration
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Run one candidate on one cached fold at the first calibration rung.
#   This validates the GPU backend and cannot publish production budgets.

#----------------------------------------------------------#
# 0. Read invocation -----
#----------------------------------------------------------#

profile_id <-
  base::Sys.getenv(
    "SJSMD_CALIBRATION_PROFILE",
    unset = "project_paleo_spatial_continental"
  )
scale_id <-
  base::Sys.getenv("SJSMD_CALIBRATION_SCALE_ID", unset = "europe")
resolution_id <-
  base::Sys.getenv("SJSMD_CALIBRATION_RESOLUTION", unset = "genus")

base::Sys.setenv(R_CONFIG_ACTIVE = profile_id)
library(here)
source(here::here("R/___setup_project___.R"))

#----------------------------------------------------------#
# 1. Resolve the cached target suffix -----
#----------------------------------------------------------#

flag_spatial <-
  stringr::str_detect(profile_id, "_spatial_")
if (
  !flag_spatial
) {
  cli::cli_abort(
    "Temporal smoke tests require a registered calibration representative."
  )
}
pipeline_id <-
  stringr::str_c(
    "pipeline_",
    stringr::str_extract(profile_id, "(paleo|modern)_spatial"),
    "_resolution"
  )
path_store <-
  here::here(load_active_config_value("target_store"), scale_id, pipeline_id)
target_suffix <-
  stringr::str_c(
    "_",
    dplyr::case_when(
      stringr::str_detect(profile_id, "modern_spatial") &
        resolution_id == "functional_type" ~ "ft_modern",
      .default = resolution_id
    )
  )

#----------------------------------------------------------#
# 2. Load one cached fold and candidate -----
#----------------------------------------------------------#

list_prepared_folds <-
  targets::tar_read_raw(
    name = stringr::str_c(
      "list_sjsdm_prepared_tuning_folds",
      target_suffix
    ),
    store = path_store
  )
data_candidates <-
  targets::tar_read_raw(
    name = stringr::str_c(
      "data_sjsdm_regularization_candidates",
      target_suffix
    ),
    store = path_store
  )
formula_jsdm_environment <-
  targets::tar_read_raw(
    name = stringr::str_c("formula_jsdm_environment", target_suffix),
    store = path_store
  )
config_model_fitting <-
  targets::tar_read_raw(
    name = stringr::str_c("config_model_fitting", target_suffix),
    store = path_store
  )
config_fit_budget <-
  base::list(
    n_iter_initial = 500L,
    n_iter_max = 500L,
    n_sampling = 200L,
    n_step_size = NULL,
    n_early_stopping = NULL
  )
config_sjsdm_cv_fitting <-
  build_sjsdm_cross_validation_fitting_config(
    config_model_fitting = config_model_fitting,
    config_fit_budget = config_fit_budget
  )

first_fold_name <-
  base::names(list_prepared_folds)[[1L]]
list_one_fold <-
  list_prepared_folds[first_fold_name]
data_one_candidate <-
  data_candidates[1L, , drop = FALSE]

#----------------------------------------------------------#
# 3. Run and record the bounded GPU smoke fit -----
#----------------------------------------------------------#

list_result <-
  run_sjsdm_cv_calibration_rung(
    data_candidates = data_one_candidate,
    list_prepared_folds = list_one_fold,
    data_budget = build_sjsdm_cv_calibration_ladder()[1L, ],
    sel_abiotic_formula = formula_jsdm_environment,
    config_sjsdm_cv_fitting = config_sjsdm_cv_fitting,
    repeat_ids = 1L,
    device = purrr::chuck(
      config_sjsdm_cv_fitting,
      "cross_validation",
      "fit_device"
    )
  )

path_report <-
  here::here(
    "Documentation",
    "Reports",
    "Model_calibration",
    "sjsdm_cv_fit_budget",
    "smoke"
  )
fs::dir_create(path_report)
file_stem <-
  stringr::str_c(profile_id, scale_id, resolution_id, sep = "__")
readr::write_csv(
  list_result[["data_benchmark"]],
  fs::path(path_report, stringr::str_c(file_stem, "__benchmark.csv")),
  na = "NA"
)
readr::write_csv(
  list_result[["data_fit_attempts"]],
  fs::path(path_report, stringr::str_c(file_stem, "__attempts.csv")),
  na = "NA"
)
