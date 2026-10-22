#' @title Test Prepared Fold Content Against Current Preparation Code
#' @description
#' Reconstructs folds in memory and requires exact analytical equality. This
#' permits error-only code changes without rewriting operational runtimes in
#' cached folds or invalidating successful fitting descendants.
#' @param store_path,target_name
#' Existing store and one prepared-fold endpoint.
#' @param read_target_function,prepare_fold_function
#' Injectable cached target reader and current fold-preparation adapter.
#' @param load_metadata_function
#' Injectable target metadata reader for current input-name resolution.
#' @return A logical scalar; unreadable inputs and reconstruction errors fail.
#' @details
#' Call only after every upstream input and configuration has been verified.
#' This function does not execute targets, fit models, or write to stores.
#' @examples
#' \dontrun{
#' is_sjsdm_cv_prepared_folds_current(store, "list_sjsdm_prepared_tuning_folds")
#' }
#' @export
is_sjsdm_cv_prepared_folds_current <- function(
    store_path,
    target_name,
    read_target_function = targets::tar_read_raw,
    prepare_fold_function = prepare_sjsdm_cross_validation_fold,
    load_metadata_function = targets::tar_meta) {
  suffix <-
    stringr::str_remove(target_name, "^list_sjsdm_prepared_tuning_folds")
  flag_current <-
    base::tryCatch(
      expr = {
        list_folds <-
          read_target_function(name = target_name, store = store_path)
        vec_cached_names <-
          load_metadata_function(store = store_path, fields = "name")[["name"]]
        target_coordinates <-
          if (
            "data_coords_projected" %in% vec_cached_names
          ) {
            "data_coords_projected"
          } else {
            stringr::str_c("data_coords_projected", suffix)
          }
        target_config <-
          if (
            stringr::str_c("config_model_fitting", suffix) %in%
              vec_cached_names
          ) {
            stringr::str_c("config_model_fitting", suffix)
          } else {
            "config_model_fitting"
          }
        list_input_names <-
          base::list(
            data_community_matrix = stringr::str_c(
              "data_community_model_matrix", suffix),
            data_abiotic_wide = stringr::str_c("data_abiotic_wide", suffix),
            data_coords_projected = target_coordinates,
            data_sample_ids = stringr::str_c("data_sample_ids_checked", suffix),
            config_model_fitting = target_config,
            config_data_processing = "config_data_processing"
          )
        list_inputs <-
          purrr::map(list_input_names,
            ~ read_target_function(name = .x, store = store_path))
        list_rebuilt <-
          purrr::map(list_folds, .f = function(list_record) {
            list_context <-
              list_record[["list_fold_context"]]
            list_partition <-
              list_context[base::c(
                "train_indices", "test_indices", "repeat_id", "fold_id"
              )]
            list_current <- list_record
            list_current[["list_prepared_fold"]] <-
              base::do.call(prepare_fold_function,
                base::c(list_inputs, list_partition))
            return(list_current)
          })
        base::length(list_folds) > 0L && base::identical(
          prepare_sjsdm_cv_calibration_hash_folds(list_folds),
          prepare_sjsdm_cv_calibration_hash_folds(list_rebuilt)
        )
      },
      error = function(error_condition) FALSE
    )
  return(base::isTRUE(flag_current))
}
