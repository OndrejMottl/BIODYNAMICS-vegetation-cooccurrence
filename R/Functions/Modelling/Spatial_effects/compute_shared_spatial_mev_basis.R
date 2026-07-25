#' @title Compute the Shared Spatial MEM Basis
#' @description
#' Applies the common spatial-predictor configuration and constructs the
#' reusable 2-D MEM basis when spatial predictors are enabled.
#' @param data_coords_projected
#' Projected input coordinates.
#' @param config_spatial_predictors
#' Shared spatial-predictor configuration.
#' @param compute_basis_function
#' Basis constructor. Defaults to [compute_spatial_mev_basis()].
#' @return
#' Reusable spatial MEM basis list, or `NULL` when 2-D spatial predictors are
#' disabled.
#' @export
compute_shared_spatial_mev_basis <- function(
    data_coords_projected,
    config_spatial_predictors,
    compute_basis_function = compute_spatial_mev_basis) {
  assertthat::assert_that(
    base::is.list(config_spatial_predictors),
    msg = "`config_spatial_predictors` must be a list."
  )

  assertthat::assert_that(
    base::is.function(compute_basis_function),
    msg = "`compute_basis_function` must be a function."
  )

  if (
    !base::isTRUE(config_spatial_predictors[["use_spatial"]]) ||
      config_spatial_predictors[["spatial_mode"]] != "spatial"
  ) {
    return(NULL)
  }

  list_spatial_mev_config <-
    config_spatial_predictors |>
    purrr::chuck("spatial_mev")

  res <-
    compute_basis_function(
      data_coords_projected = data_coords_projected,
      n_mev = config_spatial_predictors |>
        purrr::chuck("n_mev"),
      strategy = list_spatial_mev_config |>
        purrr::chuck("strategy"),
      exact_max_locations = list_spatial_mev_config |>
        purrr::chuck("exact_max_locations"),
      fast_eigenvectors = list_spatial_mev_config |>
        purrr::chuck("fast_eigenvectors"),
      fast_seed = list_spatial_mev_config |>
        purrr::chuck("fast_seed")
    )

  return(res)
}
