#----------------------------------------------------------#
#                 Vegetation Co-occurrence
#     Verify the October 2026 operational-memory migration
#                       O. Mottl
#                         2026
#----------------------------------------------------------#
# One-time evidence-only recovery for modern Europe functional types.
#   Reconstructs all original folds, proves exact analytical equivalence,
#   archives original evidence, and migrates its signature without refitting.
# Run with Rscript in a fresh process. Does not publish production budgets.

#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#
library(here)
library(magrittr)
source(here::here(
  "R/Functions/Pipeline/Definitions/load_project_functions.R"
))
base::invisible(load_project_functions(
  path_function_root = here::here("R/Functions"),
  environment_target = base::globalenv(),
  vec_excluded_directory_names = "_legacy"))

profile_id <- "project_modern_spatial_continental"
scale_id <- "europe"
resolution_id <- "functional_type"
target_suffix <- "_ft_modern"
base::Sys.setenv(R_CONFIG_ACTIVE = profile_id)
path_store <-
  here::here("Data/targets/modern_spatial_continental/europe/",
    "pipeline_modern_spatial_resolution")
path_evidence <-
  here::here("Data/Temp/Sjsdm_cv_calibration", profile_id,
    scale_id, resolution_id)
file_result <-
  fs::path(path_evidence, "calibration_result.qs")
list_result <-
  qs2::qs_read(file = file_result)
list_folds <-
  targets::tar_read_raw(name = stringr::str_c(
    "list_sjsdm_prepared_tuning_folds", target_suffix), store = path_store)
config_model <-
  targets::tar_read_raw(name = stringr::str_c(
    "config_model_fitting", target_suffix), store = path_store)
list_current_check <-
  validate_sjsdm_cv_calibration_evidence(list_result, list_folds, config_model)

#----------------------------------------------------------#
# 1. Verify current preparation without rewriting stores -----
#----------------------------------------------------------#
validate_sjsdm_cv_preparation_freshness(
  pipeline_script = here::here(
    "R/Pipelines/pipeline_modern_spatial_resolution.R"),
  store_path = path_store,
  target_names = stringr::str_c(
    "list_sjsdm_prepared_tuning_folds", target_suffix)
)
if (
  list_current_check[["status"]] == "accepted"
) {
  cli::cli_inform("Operational evidence is already migrated and current.")
  base::quit(save = "no", status = 0L)
}

#----------------------------------------------------------#
# 2. Reconstruct original tracked preparation code -----
#----------------------------------------------------------#
environment_historical <-
  base::new.env(parent = base::globalenv())
base::invisible(load_project_functions(
  path_function_root = here::here("R/Functions"),
  environment_target = environment_historical,
  vec_excluded_directory_names = "_legacy"))
vec_historical_source <-
  base::system2(command = "git", args = base::c("show", base::shQuote(
    stringr::str_c("01741718^:R/Functions/Modelling/Spatial_effects/Basis/",
      "compute_spatial_mev_basis.R"))), stdout = TRUE)
base::stopifnot(base::length(vec_historical_source) > 0L)
base::eval(base::parse(text = vec_historical_source),
  envir = environment_historical)
list_inputs <-
  base::list(
    data_community_matrix = targets::tar_read_raw(
      "data_community_model_matrix_ft_modern", store = path_store),
    data_abiotic_wide = targets::tar_read_raw(
      "data_abiotic_wide_ft_modern", store = path_store),
    data_coords_projected = targets::tar_read_raw(
      "data_coords_projected", store = path_store),
    data_sample_ids = targets::tar_read_raw(
      "data_sample_ids_checked_ft_modern", store = path_store),
    config_model_fitting = config_model,
    config_data_processing = targets::tar_read_raw(
      "config_data_processing", store = path_store)
  )
list_historical_folds <-
  purrr::map(list_folds, .f = function(list_record) {
    list_partition <-
      list_record[["list_fold_context"]][base::c(
        "train_indices", "test_indices", "repeat_id", "fold_id")]
    list_historical <- list_record
    list_historical[["list_prepared_fold"]] <-
      base::do.call(
        environment_historical[["prepare_sjsdm_cross_validation_fold"]],
        base::c(list_inputs, list_partition))
    return(list_historical)
  })
list_check <-
  validate_sjsdm_cv_calibration_evidence(list_result, list_folds,
    config_model, list_legacy_prepared_folds = list_historical_folds)
assertthat::assert_that(
  list_check[["migration_status"]] ==
    "reused_verified_v4_operational_evidence",
  msg = "Original signature and complete analytical equivalence are required."
)
list_migrated <-
  prepare_sjsdm_cv_calibration_result_migration(list_result, list_folds,
    config_model, list_legacy_prepared_folds = list_historical_folds)
vec_fitting_fields <-
  base::c("data_accepted_budget", "data_benchmark", "data_fit_attempts")
base::stopifnot(base::identical(list_result[vec_fitting_fields],
  list_migrated[vec_fitting_fields]))

#----------------------------------------------------------#
# 3. Verify every fold before archiving or saving evidence -----
#----------------------------------------------------------#
data_fold_proof <-
  tibble::tibble(
    fold_key = base::names(list_folds),
    original_v4_hash = list_result[["calibration_input_fingerprints"]][[
      "fold_content_hashes"]],
    reconstructed_v4_hash = purrr::map_chr(
      prepare_sjsdm_cv_calibration_hash_folds(list_historical_folds,
        contract_version = "v4"), digest::digest),
    current_v5_hash = list_migrated[["calibration_input_fingerprints"]][[
      "fold_content_hashes"]],
    reconstructed_v5_hash = purrr::map_chr(
      prepare_sjsdm_cv_calibration_hash_folds(list_historical_folds),
      digest::digest)
  )
base::stopifnot(base::all(data_fold_proof[["original_v4_hash"]] ==
  data_fold_proof[["reconstructed_v4_hash"]]),
  base::all(data_fold_proof[["current_v5_hash"]] ==
    data_fold_proof[["reconstructed_v5_hash"]]))

#----------------------------------------------------------#
# 4. Archive complete original evidence and save migration -----
#----------------------------------------------------------#
path_archive <-
  here::here("Data/Temp/Sjsdm_cv_calibration/_archive/",
    "20261013_operational_memory_migration", profile_id, scale_id,
    resolution_id)
if (
  !fs::dir_exists(path_archive)
) {
  fs::dir_create(fs::path_dir(path_archive))
  fs::dir_copy(path_evidence, path_archive)
}
base::stopifnot(base::identical(digest::digest(file = file_result),
  digest::digest(file = fs::path(path_archive, "calibration_result.qs"))))
qs2::qs_save(list_migrated, file = file_result)
qs2::qs_save(list_migrated[["calibration_input_fingerprints"]],
  file = fs::path(path_evidence, "calibration_input_fingerprints.qs"))
path_report <-
  here::here("Documentation/Reports/Model_calibration/",
    "calibration_safeguards_2026-10-13")
fs::dir_create(path_report)
readr::write_csv(data_fold_proof,
  fs::path(path_report, "modern_operational_migration_fold_proof.csv"))
readr::write_csv(list_migrated[["run_provenance"]],
  fs::path(path_report, "modern_operational_migration.csv"))
cli::cli_inform(base::c(
  "v" = "Modern FT calibration migrated without changing fit evidence.",
  "i" = "Original archive: {path_archive}",
  "i" = "No production budgets or models were changed."
))
