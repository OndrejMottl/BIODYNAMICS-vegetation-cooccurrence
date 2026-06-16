#' @title Read Spatial-Resolution Prediction Inputs
#' @description
#' Reads the suffixed targets needed to predict from one
#' `pipeline_paleo_spatial_resolution` model resolution.
#' @param store_path
#' Character scalar path to a spatial-resolution targets store.
#' @param resolution_id
#' Character scalar model resolution identifier, such as `"genus"`.
#' @param read_target_fn
#' Function used to read targets. Defaults to
#' [targets::tar_read_raw()].
#' @param meta_fn
#' Function used by [read_targets_store_meta()] to read metadata.
#' @return
#' Named list of model, evaluation, model input, coordinate, and spatial
#' predictor targets.
#' @examples
#' \dontrun{
#' read_spatial_resolution_prediction_inputs(
#'   store_path = "Data/targets/paleo_spatial_continental/europe",
#'   resolution_id = "genus"
#' )
#' }
#' @export
read_spatial_resolution_prediction_inputs <- function(
    store_path,
    resolution_id = "genus",
    read_target_fn = targets::tar_read_raw,
    meta_fn = targets::tar_meta) {
  assertthat::assert_that(
    base::is.character(store_path) &&
      base::length(store_path) == 1L &&
      base::nchar(store_path) > 0L,
    msg = "`store_path` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(resolution_id) &&
      base::length(resolution_id) == 1L &&
      base::nchar(resolution_id) > 0L,
    msg = "`resolution_id` must be a single non-empty string."
  )

  assertthat::assert_that(
    base::is.function(read_target_fn),
    msg = "`read_target_fn` must be a function."
  )

  assertthat::assert_that(
    base::is.function(meta_fn),
    msg = "`meta_fn` must be a function."
  )

  vec_target_names <-
    base::c(
      mod_jsdm = stringr::str_glue(
        "model_jsdm_selected_{resolution_id}"
      ),
      model_evaluation = stringr::str_glue(
        "model_evaluation_{resolution_id}"
      ),
      data_model_input = stringr::str_glue(
        "data_model_input_{resolution_id}"
      ),
      data_coords_projected = "data_coords_projected",
      data_spatial_mev_core = "data_spatial_mev_core",
      data_spatial_mev_samples = stringr::str_glue(
        "data_spatial_mev_samples_{resolution_id}"
      ),
      data_spatial_scaled_list = stringr::str_glue(
        "data_spatial_scaled_list_{resolution_id}"
      )
    )

  data_meta <-
    read_targets_store_meta(
      store_path = store_path,
      meta_fn = meta_fn
    )

  vec_missing_targets <-
    vec_target_names[
      !purrr::map_lgl(
        .x = vec_target_names,
        .f = ~ check_target_succeeded(
          data_meta = data_meta,
          target_name = .x
        )
      )
    ]

  if (
    base::length(vec_missing_targets) > 0L
  ) {
    cli::cli_abort(
      c(
        "Required prediction targets are missing or errored.",
        "i" = stringr::str_glue(
          "Problem targets: ",
          "{stringr::str_c(vec_missing_targets, collapse = ', ')}."
        ),
        "i" = "Check the spatial-resolution pipeline store."
      )
    )
  }

  res_inputs <-
    vec_target_names |>
    purrr::map(
      .f = ~ read_target_fn(
        name = .x,
        store = store_path
      )
    )

  return(res_inputs)
}
