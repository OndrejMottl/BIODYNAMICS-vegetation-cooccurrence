#' @title Prepare Decomposition Fold Input
#' @description
#' Rebuilds model input for one route and one train/test split using
#' fold-local response filtering and train-only predictor scaling.
#' @param route
#' One-row route data frame or named list.
#' @param inputs
#' List returned by `load_decomposition_diagnostic_inputs()`.
#' @param train_ids
#' Character vector of training sample row names.
#' @param test_ids
#' Character vector of test sample row names.
#' @return
#' Named list returned by `prepare_model_fold_input()`, including training
#' input, test input, test observations, a taxon mapping, and diagnostics.
#' @details
#' This route-specific wrapper obtains the decomposition samples and spatial
#' predictors, then delegates common response filtering, alignment, and
#' predictor scaling to `prepare_model_fold_input()`.
#' @examples
#' \dontrun{
#' data_fold <-
#'   prepare_decomposition_fold_input(
#'     route = data_route,
#'     inputs = list_decomposition_inputs,
#'     train_ids = vec_train_ids,
#'     test_ids = vec_test_ids
#'   )
#' }
#' @export
prepare_decomposition_fold_input <- function(
    route = NULL,
    inputs = NULL,
    train_ids = NULL,
    test_ids = NULL) {
  assertthat::assert_that(
    base::is.data.frame(route) || base::is.list(route),
    msg = "`route` must be a one-row data frame or named list."
  )

  assertthat::assert_that(
    base::is.list(inputs),
    msg = "`inputs` must be a list."
  )

  assertthat::assert_that(
    base::is.character(train_ids),
    base::length(train_ids) > 0L,
    msg = "`train_ids` must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.character(test_ids),
    base::length(test_ids) > 0L,
    msg = "`test_ids` must be a non-empty character vector."
  )

  spatial_mode <-
    route[["spatial_mode"]][[1L]]

  age_scale_mode <-
    if (
      "age_scale_mode" %in% base::names(route)
    ) {
      route[["age_scale_mode"]][[1L]]
    } else {
      "center"
    }

  data_sample_ids_route <-
    get_decomposition_route_sample_ids(
      route = route,
      inputs = inputs
    )

  data_community_matrix <-
    inputs |>
    purrr::chuck("data_community_matrix")

  data_abiotic_wide <-
    inputs |>
    purrr::chuck("data_abiotic_wide")

  config_model_fitting <-
    inputs |>
    purrr::chuck("config_model_fitting")

  config_data_processing <-
    inputs |>
    purrr::chuck("config_data_processing")

  config_spatial_predictors <-
    inputs |>
    purrr::chuck("config_spatial_predictors")

  data_spatial_raw <-
    if (
      spatial_mode == "spatial"
    ) {
      data_spatial_mev_core <-
        inputs[["data_spatial_mev_core"]]

      data_spatial_mev_available <-
        if (
          base::is.null(data_spatial_mev_core)
        ) {
          compute_spatial_mev(
            data_coords_projected = inputs[["data_coords_projected"]],
            n_mev = config_spatial_predictors[["n_mev"]]
          )
        } else {
          data_spatial_mev_core
        }

      prepare_spatial_predictors_for_fit(
        data_spatial = data_spatial_mev_available,
        data_sample_ids = data_sample_ids_route
      )
    } else if (
      spatial_mode == "spatiotemporal"
    ) {
      compute_spatiotemporal_mev(
        data_coords_projected = inputs[["data_coords_projected"]],
        data_sample_ids = data_sample_ids_route,
        n_mev = config_spatial_predictors[["n_mev"]]
      )
    } else {
      cli::cli_abort(
        stringr::str_glue("Unknown spatial mode: {spatial_mode}.")
      )
    }

  vec_spatial_ids <-
    base::rownames(data_spatial_raw)

  if (
    !base::all(base::c(train_ids, test_ids) %in% vec_spatial_ids)
  ) {
    cli::cli_abort(
      "Decomposition spatial predictors are missing fold samples."
    )
  }

  data_spatial_train <-
    data_spatial_raw[
      train_ids,
      ,
      drop = FALSE
    ]

  data_spatial_test <-
    data_spatial_raw[
      test_ids,
      ,
      drop = FALSE
    ]

  res <-
    prepare_model_fold_input(
      data_community_matrix = data_community_matrix,
      data_abiotic_wide = data_abiotic_wide,
      data_spatial_train = data_spatial_train,
      data_spatial_test = data_spatial_test,
      train_ids = train_ids,
      test_ids = test_ids,
      error_family = config_model_fitting[["error_family"]],
      min_n_taxa = config_data_processing[["min_n_taxa"]],
      age_scale_mode = age_scale_mode
    )

  return(res)
}
