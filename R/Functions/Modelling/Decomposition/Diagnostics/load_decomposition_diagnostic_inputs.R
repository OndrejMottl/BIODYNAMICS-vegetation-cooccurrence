#' @title Load Decomposition Diagnostic Inputs
#' @description
#' Loads upstream targets needed by the decomposition diagnostic framework.
#' @param store_path
#' Targets store path.
#' @param resolution_id
#' Taxonomic resolution suffix. Default is `"genus"`.
#' @param tar_read_fn
#' Function used to read targets. Defaults to `targets::tar_read_raw()`.
#' @return
#' Named list with upstream data and configuration objects.
#' @export
load_decomposition_diagnostic_inputs <- function(
    store_path,
    resolution_id = "genus",
    tar_read_fn = targets::tar_read_raw) {
  assertthat::assert_that(
    base::is.character(store_path),
    base::length(store_path) == 1L,
    msg = "`store_path` must be a single character string."
  )

  assertthat::assert_that(
    base::is.character(resolution_id),
    base::length(resolution_id) == 1L,
    base::nchar(resolution_id) > 0L,
    msg = "`resolution_id` must be a single non-empty string."
  )

  assertthat::assert_that(
    base::is.function(tar_read_fn),
    msg = "`tar_read_fn` must be a function."
  )

  res <-
    base::list(
      data_sample_ids = .load_decomposition_target(
        target_name = stringr::str_glue(
          "data_sample_ids_checked_{resolution_id}"
        ),
        store_path = store_path,
        tar_read_fn = tar_read_fn
      ),
      data_community_matrix = .load_decomposition_target(
        target_name = stringr::str_glue(
          "data_community_model_matrix_{resolution_id}"
        ),
        store_path = store_path,
        tar_read_fn = tar_read_fn
      ),
      data_abiotic_wide = .load_decomposition_target(
        target_name = stringr::str_glue(
          "data_abiotic_wide_{resolution_id}"
        ),
        store_path = store_path,
        tar_read_fn = tar_read_fn
      ),
      data_spatial_mev_core = .load_decomposition_target(
        target_name = "data_spatial_mev_core",
        store_path = store_path,
        tar_read_fn = tar_read_fn
      ),
      data_coords_projected = .load_decomposition_target(
        target_name = "data_coords_projected",
        store_path = store_path,
        tar_read_fn = tar_read_fn
      ),
      config_data_processing = .load_decomposition_target(
        target_name = "config_data_processing",
        store_path = store_path,
        tar_read_fn = tar_read_fn
      ),
      config_model_fitting = .load_decomposition_model_fitting_config(
        store_path = store_path,
        resolution_id = resolution_id,
        tar_read_fn = tar_read_fn
      ),
      config_spatial_predictors = .load_decomposition_target(
        target_name = "config_spatial_predictors",
        store_path = store_path,
        tar_read_fn = tar_read_fn
      )
    )

  return(res)
}
