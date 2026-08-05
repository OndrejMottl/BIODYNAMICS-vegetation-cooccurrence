#' @title Load Decomposition Model-Fitting Configuration
#' @description
#' Internal loader that prefers the shared configuration target and falls
#' back to the taxonomic-resolution-specific target.
#' @param store_path
#' Targets store path.
#' @param resolution_id
#' Taxonomic resolution suffix.
#' @param tar_read_fn
#' Function used to read targets.
#' @return
#' The model-fitting configuration value.
#' @keywords internal
.load_decomposition_model_fitting_config <- function(
    store_path,
    resolution_id,
    tar_read_fn) {
  config_model_fitting <-
    tryCatch(
      expr = .load_decomposition_target(
        target_name = "config_model_fitting",
        store_path = store_path,
        tar_read_fn = tar_read_fn
      ),
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
    .load_decomposition_target(
      target_name = stringr::str_glue(
        "config_model_fitting_{resolution_id}"
      ),
      store_path = store_path,
      tar_read_fn = tar_read_fn
    )

  return(res)
}
