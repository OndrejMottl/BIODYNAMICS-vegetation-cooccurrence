#----------------------------------------------------------#
#                 Vegetation Co-occurrence
#           Bounded October 2026 calibration timing
#                       O. Mottl
#                         2026
#----------------------------------------------------------#
# Diagnostic only: paleo eu_r005 functional types, first two ladder rungs.
# At most 48 screening and 20 confirmation fits, without automatic escalation
#   beyond rung two. Evidence is isolated; production budgets are not changed.
# A no-accepted-budget result at this boundary is incomplete, not publishable.

#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#
library(here)
source(here::here("R/___setup_project___.R"))
base::Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_spatial_regional")
maximum_budget_order <- 2L
path_store <-
  here::here("Data/targets/paleo_spatial_regional/eu_r005/",
    "pipeline_paleo_spatial_resolution")
path_output <-
  here::here("Data/Temp/Sjsdm_cv_calibration_bounded/20261013/",
    "project_paleo_spatial_regional/eu_r005/functional_type")
fs::dir_create(path_output)
validate_sjsdm_cv_preparation_freshness(
  pipeline_script = here::here(
    "R/Pipelines/pipeline_paleo_spatial_resolution.R"),
  store_path = path_store,
  target_names = "list_sjsdm_prepared_tuning_folds_functional_type"
)

#----------------------------------------------------------#
# 1. Build the unchanged calibration inputs -----
#----------------------------------------------------------#
list_folds <-
  targets::tar_read_raw("list_sjsdm_prepared_tuning_folds_functional_type",
    store = path_store)
config_model <-
  targets::tar_read_raw("config_model_fitting_functional_type",
    store = path_store)
data_candidates <-
  base::do.call(build_sjsdm_regularization_candidates,
    config_model[["cross_validation"]][["regularization"]])
formula_environment <-
  build_jsdm_environment_formula(
    data = list_folds[[1L]][["list_prepared_fold"]][[
      "data_train_input"]][["data_abiotic_to_fit"]],
    use_age = config_model[["use_age_in_formula"]])
config_cv <-
  build_sjsdm_cross_validation_fitting_config(config_model,
    base::list(n_iter_initial = 500L, n_iter_max = 500L, n_sampling = 100L,
      n_step_size = NULL, n_early_stopping = NULL))
list_hashes <-
  compute_sjsdm_cv_calibration_hashes(data_candidates, list_folds,
    formula_environment, config_cv)
qs2::qs_save(list_hashes,
  fs::path(path_output, "calibration_input_fingerprints.qs"))

#----------------------------------------------------------#
# 2. Run only the approved bounded benchmark -----
#----------------------------------------------------------#
started_at <-
  base::Sys.time()
list_result <-
  run_sjsdm_cv_calibration_benchmark(
    data_candidates = data_candidates,
    list_prepared_folds = list_folds,
    sel_abiotic_formula = formula_environment,
    config_sjsdm_cv_fitting = config_cv,
    maximum_budget_order = maximum_budget_order,
    checkpoint_file = fs::path(path_output, "calibration_checkpoint.qs"),
    device = "gpu"
  )
list_result[["calibration_input_fingerprints"]] <- list_hashes
list_result[["calibration_contract_version"]] <-
  list_hashes[["calibration_contract_version"]]
list_result[["calibration_input_hash"]] <-
  list_hashes[["calibration_input_hash"]]
list_result[["run_provenance"]] <-
  tibble::tibble(profile_id = "project_paleo_spatial_regional",
    scale_id = "eu_r005", resolution_id = "functional_type",
    started_at = started_at, finished_at = base::Sys.time(),
    maximum_budget_order = maximum_budget_order,
    publication_authorized = FALSE,
    calibration_status = list_result[["calibration_status"]])
qs2::qs_save(list_result, fs::path(path_output, "calibration_result.qs"))

#----------------------------------------------------------#
# 3. Save timing and convergence evidence for human review -----
#----------------------------------------------------------#
path_report <-
  here::here("Documentation/Reports/Model_calibration/",
    "calibration_safeguards_2026-10-13")
fs::dir_create(path_report)
readr::write_csv(list_result[["data_benchmark"]],
  fs::path(path_report, "bounded_benchmark_evidence.csv"))
readr::write_csv(list_result[["data_fit_attempts"]],
  fs::path(path_report, "bounded_fit_attempts.csv"))
readr::write_csv(list_result[["run_provenance"]],
  fs::path(path_report, "bounded_run_provenance.csv"))
calibration_status <-
  list_result[["calibration_status"]]
cli::cli_inform(base::c(
  "v" = "Bounded calibration finished: {calibration_status}.",
  "i" = "Review timing and convergence evidence at {path_report}.",
  "i" = "No production budgets were published; modern remains stopped."
))
