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
#' input, test input, test observations, a taxon mapping, model-input
#' diagnostics, and fold-local spatial diagnostics.
#' @details
#' This route-specific wrapper delegates training-only MEM construction and
#' held-out projection to `prepare_fold_spatial_predictors()`, then delegates
#' common response filtering, alignment, and predictor scaling to
#' `prepare_model_fold_input()`.
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

  list_spatial_fold <-
    prepare_fold_spatial_predictors(
      data_coords_projected = inputs[["data_coords_projected"]],
      data_sample_ids = data_sample_ids_route,
      train_ids = train_ids,
      test_ids = test_ids,
      spatial_mode = spatial_mode,
      n_mev = config_spatial_predictors[["n_mev"]]
    )

  res_model_input <-
    prepare_model_fold_input(
      data_community_matrix = data_community_matrix,
      data_abiotic_wide = data_abiotic_wide,
      data_spatial_train = list_spatial_fold[["data_spatial_train"]],
      data_spatial_test = list_spatial_fold[["data_spatial_test"]],
      train_ids = train_ids,
      test_ids = test_ids,
      error_family = config_model_fitting[["error_family"]],
      min_n_taxa = config_data_processing[["min_n_taxa"]],
      age_scale_mode = age_scale_mode
    )

  res <-
    base::c(
      res_model_input,
      base::list(
        data_spatial_diagnostics = list_spatial_fold[[
          "data_diagnostics"
        ]]
      )
    )

  return(res)
}
