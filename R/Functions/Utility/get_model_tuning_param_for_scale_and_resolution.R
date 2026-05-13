#' @title Get One Model Tuning Parameter For Scale And Resolution
#' @description
#' Returns one active model-fitting tuning parameter. Spatial stores read
#' per-scale tuning from the model tuning CSV files; non-spatial stores
#' fall back to scalar values from `config.yml`.
#' @param param_id
#' A single model tuning parameter name. Must be one of `n_iter`,
#' `n_step_size`, `n_sampling`, `n_samples_anova`, or
#' `n_early_stopping`.
#' @param scale_id
#' Optional spatial unit identifier. Defaults to
#' `get_scale_id_from_store()`. When `NULL`, values are read from
#' `config.yml`.
#' @param resolution_id
#' Optional model resolution. Defaults to the active
#' `data_processing$taxonomic_resolution` config value. Spatial stores
#' pass this to `get_model_tuning_params()`.
#' @param config_file
#' Path to the YAML configuration file.
#' Default: `here::here("config.yml")`.
#' @param dir
#' Directory containing model tuning CSV files.
#' Default: `here::here("Data/Input/Model_tuning")`.
#' @return
#' The requested parameter value. Optional tuning parameters may return
#' `NULL`.
#' @seealso get_model_tuning_params
#' @export
get_model_tuning_param_for_scale_and_resolution <- function(
    param_id,
    scale_id = get_scale_id_from_store(),
    resolution_id = NULL,
    config_file = here::here("config.yml"),
    dir = here::here("Data/Input/Model_tuning")) {
  vec_param_id <-
    c(
      "n_iter",
      "n_step_size",
      "n_sampling",
      "n_samples_anova",
      "n_early_stopping"
    )

  assertthat::assert_that(
    base::is.character(param_id) &&
      base::length(param_id) == 1L &&
      param_id %in% vec_param_id,
    msg = stringr::str_glue(
      "`param_id` must be one of: ",
      "{stringr::str_c(vec_param_id, collapse = ', ')}."
    )
  )

  if (
    base::is.null(resolution_id)
  ) {
    resolution_id <-
      get_active_config(
        value = c("data_processing", "taxonomic_resolution"),
        file = config_file
      )
  }

  if (
    !base::is.null(scale_id)
  ) {
    params <-
      get_model_tuning_params(
        analysis_id = get_active_config(
          value = c("model_fitting", "model_tuning_id"),
          file = config_file
        ),
        scale_id = scale_id,
        resolution_id = resolution_id,
        dir = dir
      )

    return(params[[param_id]])
  }

  return(
    get_active_config(
      value = c("model_fitting", param_id),
      file = config_file
    )
  )
}
