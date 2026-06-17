#' @title Predict Spatial-Resolution Grid for One Age
#' @description
#' Builds abiotic and optional spatial predictors for one age slice and
#' returns long-format taxon occurrence probabilities.
#' @param prediction_inputs
#' Named list returned by [read_spatial_resolution_prediction_inputs()].
#' @param data_grid
#' Prediction grid with `grid_id`, `coord_long`, and `coord_lat`.
#' @param data_grid_coords_projected
#' Projected prediction grid coordinates with row names `grid_<id>`.
#' @param age
#' Numeric scalar age in years before present.
#' @param abiotic_variables
#' Character vector of CHELSA variables to extract.
#' @param x_lim
#' Numeric longitude range.
#' @param y_lim
#' Numeric latitude range.
#' @param cache_dir
#' Existing CHELSA cache directory.
#' @param spatial_mode
#' Spatial predictor mode: `"spatial"`, `"spatiotemporal"`, or `"none"`.
#' @param climate_fn
#' Climate extraction function. If `NULL` (default),
#' [extract_prediction_climate()] is used.
#' @param spatial_interpolate_fn
#' Spatial interpolation function. If `NULL` (default),
#' [interpolate_mev_to_grid()] is used.
#' @param spatiotemporal_interpolate_fn
#' Spatiotemporal interpolation function. If `NULL` (default),
#' [interpolate_st_mev_to_grid()] is used.
#' @param predict_fn
#' Prediction function. If `NULL` (default), the function resolves
#' `sjSDM:::predict.sjSDM`.
#' @return
#' Long tibble with predicted probabilities by grid cell, age, and taxon.
#' @examples
#' \dontrun{
#' predict_spatial_resolution_grid_age(
#'   prediction_inputs = prediction_inputs,
#'   data_grid = data_grid,
#'   data_grid_coords_projected = data_grid_coords_projected,
#'   age = 0,
#'   abiotic_variables = c("bio1", "bio12"),
#'   x_lim = c(-10, 40),
#'   y_lim = c(35, 70),
#'   cache_dir = "Data/Temp/chelsa/prediction"
#' )
#' }
#' @export
predict_spatial_resolution_grid_age <- function(
    prediction_inputs,
    data_grid,
    data_grid_coords_projected,
    age,
    abiotic_variables,
    x_lim,
    y_lim,
    cache_dir,
    spatial_mode = "spatiotemporal",
    climate_fn = NULL,
    spatial_interpolate_fn = NULL,
    spatiotemporal_interpolate_fn = NULL,
    predict_fn = NULL) {
  assertthat::assert_that(
    base::is.list(prediction_inputs),
    msg = "`prediction_inputs` must be a list."
  )

  assertthat::assert_that(
    spatial_mode %in% c("spatial", "spatiotemporal", "none"),
    msg = "`spatial_mode` must be spatial, spatiotemporal, or none."
  )

  if (
    base::is.null(climate_fn)
  ) {
    climate_fn <- extract_prediction_climate
  }

  if (
    base::is.null(spatial_interpolate_fn)
  ) {
    spatial_interpolate_fn <- interpolate_mev_to_grid
  }

  if (
    base::is.null(spatiotemporal_interpolate_fn)
  ) {
    spatiotemporal_interpolate_fn <- interpolate_st_mev_to_grid
  }

  assertthat::assert_that(
    base::is.function(climate_fn),
    msg = "`climate_fn` must be a function."
  )

  assertthat::assert_that(
    base::is.function(spatial_interpolate_fn),
    msg = "`spatial_interpolate_fn` must be a function."
  )

  assertthat::assert_that(
    base::is.function(spatiotemporal_interpolate_fn),
    msg = "`spatiotemporal_interpolate_fn` must be a function."
  )

  if (
    base::is.null(predict_fn)
  ) {
    if (
      !base::isNamespaceLoaded("sjSDM")
    ) {
      base::loadNamespace("sjSDM")
    }

    predict_fn <-
      base::get(
        x = "predict.sjSDM",
        envir = base::asNamespace("sjSDM"),
        inherits = FALSE
      )
  }

  assertthat::assert_that(
    base::is.function(predict_fn),
    msg = "`predict_fn` must be a function."
  )

  data_climate <-
    climate_fn(
      data_grid = data_grid,
      age = age,
      abiotic_variables = abiotic_variables,
      x_lim = x_lim,
      y_lim = y_lim,
      cache_dir = cache_dir
    )

  data_abiotic_scaled <-
    scale_prediction_abiotic(
      data_climate = data_climate,
      scale_attributes = prediction_inputs |>
        purrr::chuck("data_model_input", "scale_attributes")
    )

  vec_grid_rownames <-
    stringr::str_c(
      "grid_",
      data_climate |>
        dplyr::pull("grid_id")
    )

  data_grid_coords_valid <-
    data_grid_coords_projected[
      vec_grid_rownames,
      ,
      drop = FALSE
    ]

  if (
    base::any(!stats::complete.cases(data_grid_coords_valid))
  ) {
    cli::cli_abort(
      c(
        "Some prediction grid coordinates could not be aligned.",
        "i" = "Check projected row names and grid identifiers."
      )
    )
  }

  data_spatial_predictors <- NULL

  if (
    spatial_mode == "spatial"
  ) {
    data_spatial_predictors <-
      spatial_interpolate_fn(
        data_coords_projected_train = prediction_inputs |>
          purrr::chuck("data_coords_projected"),
        data_mev_core = prediction_inputs |>
          purrr::chuck("data_spatial_mev_core"),
        data_coords_projected_pred = data_grid_coords_valid,
        spatial_scale_attributes = prediction_inputs |>
          purrr::chuck(
            "data_model_input",
            "spatial_scale_attributes"
          )
      )
  } else if (
    spatial_mode == "spatiotemporal"
  ) {
    data_spatial_predictors <-
      spatiotemporal_interpolate_fn(
        data_st_mev_samples = prediction_inputs |>
          purrr::chuck("data_spatial_mev_samples"),
        data_coords_projected_train = prediction_inputs |>
          purrr::chuck("data_coords_projected"),
        data_coords_projected_pred = data_grid_coords_valid,
        pred_age = age,
        spatial_scale_attributes = prediction_inputs |>
          purrr::chuck(
            "data_model_input",
            "spatial_scale_attributes"
          )
      )
  }

  mat_predictions <-
    predict_fn(
      object = prediction_inputs |>
        purrr::chuck("mod_jsdm"),
      newdata = data_abiotic_scaled,
      SP = data_spatial_predictors,
      type = "link"
    )

  mat_predictions <-
    assert_prediction_probabilities(
      data_predictions = mat_predictions
    )

  vec_species <-
    prediction_inputs |>
    purrr::chuck("mod_jsdm", "species")

  if (
    base::length(vec_species) == base::ncol(mat_predictions)
  ) {
    base::colnames(mat_predictions) <- vec_species
  }

  res_predictions <-
    dplyr::bind_cols(
      data_climate |>
        dplyr::select(
          "grid_id",
          "coord_long",
          "coord_lat",
          "age"
        ),
      tibble::as_tibble(mat_predictions)
    ) |>
    tidyr::pivot_longer(
      cols = -c("grid_id", "coord_long", "coord_lat", "age"),
      names_to = "taxon",
      values_to = "predicted_probability"
    )

  return(res_predictions)
}
