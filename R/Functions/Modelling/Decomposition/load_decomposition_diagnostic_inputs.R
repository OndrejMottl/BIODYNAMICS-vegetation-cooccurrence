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

  read_target <- function(target_name) {
    tar_read_fn(
      name = target_name,
      store = store_path
    )
  }

  read_model_fitting_config <- function() {
    config_model_fitting <-
      tryCatch(
        expr = read_target("config_model_fitting"),
        error = function(error_condition) {
          error_condition
        }
      )

    if (
      !base::inherits(config_model_fitting, "error")
    ) {
      return(config_model_fitting)
    }

    res <-
      read_target(
        stringr::str_glue("config_model_fitting_{resolution_id}")
      )

    return(res)
  }

  res <-
    base::list(
      data_sample_ids = read_target(
        stringr::str_glue("data_sample_ids_checked_{resolution_id}")
      ),
      data_community_matrix = read_target(
        stringr::str_glue("data_community_model_matrix_{resolution_id}")
      ),
      data_abiotic_wide = read_target(
        stringr::str_glue("data_abiotic_wide_{resolution_id}")
      ),
      data_spatial_mev_core = read_target("data_spatial_mev_core"),
      data_coords_projected = read_target("data_coords_projected"),
      config_data_processing = read_target("config_data_processing"),
      config_model_fitting = read_model_fitting_config(),
      config_spatial_predictors = read_target(
        "config_spatial_predictors"
      )
    )

  return(res)
}
