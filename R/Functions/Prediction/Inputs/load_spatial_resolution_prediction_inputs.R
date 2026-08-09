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
#' Function used by [load_targets_store_metadata()] to read metadata.
#' @param include_spatial_basis
#' Logical scalar. When `TRUE`, append the additive reusable 2-D basis target.
#' Default is `FALSE` to preserve the existing public return schema.
#' @return
#' Named list of model, model input, coordinate, and spatial predictor targets.
#' @examples
#' \dontrun{
#' load_spatial_resolution_prediction_inputs(
#'   store_path = "Data/targets/paleo_spatial_continental/europe",
#'   resolution_id = "genus"
#' )
#' }
#' @export
load_spatial_resolution_prediction_inputs <- function(
    store_path,
    resolution_id = "genus",
    read_target_fn = targets::tar_read_raw,
    meta_fn = targets::tar_meta,
    include_spatial_basis = FALSE) {
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

  assertthat::assert_that(
    base::is.logical(include_spatial_basis),
    base::length(include_spatial_basis) == 1L,
    !base::is.na(include_spatial_basis),
    msg = "`include_spatial_basis` must be TRUE or FALSE."
  )

  vec_target_names <-
    base::c(
      mod_jsdm = stringr::str_glue(
        "mod_jsdm_selected_{resolution_id}"
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
    load_targets_store_metadata(
      store_path = store_path,
      meta_fn = meta_fn
    )

  vec_missing_targets <-
    vec_target_names[
      !purrr::map_lgl(
        .x = vec_target_names,
        .f = ~ has_target_succeeded(
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

  res_inputs <-
    if (
      include_spatial_basis
    ) {
      spatial_basis_target <- "list_spatial_mev_core_basis"

      list_spatial_basis <-
        if (
          has_target_succeeded(
            data_meta = data_meta,
            target_name = spatial_basis_target
          )
        ) {
          read_target_fn(
            name = spatial_basis_target,
            store = store_path
          )
        } else {
          NULL
        }

      base::c(
        res_inputs,
        base::list(
          list_spatial_mev_core_basis = list_spatial_basis
        )
      )
    } else {
      res_inputs
    }

  return(res_inputs)
}
