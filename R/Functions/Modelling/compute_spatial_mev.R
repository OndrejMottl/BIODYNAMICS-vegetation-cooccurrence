#' @title Compute Moran Eigenvector Maps for Spatial Filtering
#' @description
#' Computes Moran Eigenvector Maps (MEMs) from projected
#' core locations (km) using
#' `sjSDM::generateSpatialEV()` and returns the first
#' `n_mev` eigenvectors as a data frame suitable for
#' `prepare_spatial_predictors_for_fit()`.
#' @param data_coords_projected
#' A data frame with `dataset_name` as row names and
#' columns `coord_x_km` and `coord_y_km`, as returned by
#' `project_coords_to_metric()`. Must have more than 3 rows
#' (required by `sjSDM::generateSpatialEV()`). Each row
#' represents one unique core/site location.
#' @param n_mev
#' A positive integer giving the number of eigenvectors to
#' return. The actual count of positive Moran eigenvectors
#' produced by `sjSDM::generateSpatialEV()` for the
#' supplied coordinates depends on the spatial structure
#' of the sites and is typically small (often 2). If
#' `n_mev` exceeds the available count, it is clamped
#' down automatically and a `cli::cli_warn()` message is
#' emitted. Default is `20L`.
#' @return
#' A data frame with the same row names as
#' `data_coords_projected`, and `n_mev` columns named
#' `mev_1`, `mev_2`, …, `mev_{n_mev}`, containing the
#' first `n_mev` Moran eigenvectors. This data frame is a
#' drop-in replacement for
#' `dplyr::select(data_coords_projected,
#' coord_x_km, coord_y_km)` as input to
#' `prepare_spatial_predictors_for_fit()`.
#' @details
#' MEMs capture the spatial autocorrelation structure of
#' the sampling locations and are used as spatial
#' predictors in the sjSDM model. Eigenvectors are
#' computed on the unique core locations; the caller is
#' responsible for expanding to sample level via
#' `prepare_spatial_predictors_for_fit()`.
#'
#' `sjSDM::generateSpatialEV()` returns only eigenvectors
#' with positive eigenvalues; the count often equals 2 for
#' 2-D coordinate sets. If `n_mev` exceeds the number of
#' positive eigenvectors actually produced, the function
#' automatically lowers `n_mev` to that count, emits a
#' `cli::cli_warn()` message, and continues normally.
#' @seealso
#'   [project_coords_to_metric()],
#'   [prepare_spatial_predictors_for_fit()],
#'   [scale_spatial_for_fit()]
#' @export
compute_spatial_mev <- function(
    data_coords_projected = NULL,
    n_mev = 20L) {
  assertthat::assert_that(
    is.data.frame(data_coords_projected),
    msg = "data_coords_projected must be a data frame"
  )

  assertthat::assert_that(
    all(
      c("coord_x_km", "coord_y_km") %in%
        base::names(data_coords_projected)
    ),
    msg = paste0(
      "data_coords_projected must contain columns",
      " 'coord_x_km' and 'coord_y_km'"
    )
  )

  assertthat::assert_that(
    nrow(data_coords_projected) > 3,
    msg = paste0(
      "data_coords_projected must have more than 3 rows",
      " (required by sjSDM::generateSpatialEV())"
    )
  )

  assertthat::assert_that(
    is.numeric(n_mev) || is.integer(n_mev),
    length(n_mev) == 1,
    n_mev >= 1,
    msg = "n_mev must be a single positive integer"
  )

  n_mev <- base::as.integer(n_mev)

  # 1. Build km-coordinate matrix -----

  mat_coords_km <-
    data_coords_projected |>
    dplyr::select(coord_x_km, coord_y_km) |>
    base::as.matrix()

  # 2. Compute Moran eigenvectors -----

  mat_mev_raw <-
    sjSDM::generateSpatialEV(
      coords = mat_coords_km
    )

  # Force to matrix: sjSDM returns a vector when exactly
  # one positive eigenvalue is found (drops the dimension)
  mat_mev_all <-
    base::as.matrix(mat_mev_raw)

  # 3. Post-call validation: clamp n_mev if needed -----

  n_produced <-
    base::ncol(mat_mev_all)

  if (
    n_mev > n_produced
  ) {
    cli::cli_warn(
      c(
        "{n_mev} MEV(s) requested; only {n_produced} positive.",
        "i" = "Lowering n_mev from {n_mev} to {n_produced}."
      )
    )
    n_mev <- n_produced
  }

  # 4. Select first n_mev columns -----

  mat_mev <-
    mat_mev_all[, base::seq_len(n_mev), drop = FALSE]

  # 5. Coerce to data frame with named columns -----

  vec_col_names <-
    base::paste0("mev_", base::seq_len(n_mev))

  res <-
    base::as.data.frame(mat_mev)

  base::colnames(res) <- vec_col_names
  base::rownames(res) <- base::rownames(data_coords_projected)

  return(res)
}
