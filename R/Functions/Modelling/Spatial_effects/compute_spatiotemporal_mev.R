#' @title Compute Spatiotemporal Moran Eigenvector Maps
#' @description
#' Computes Moran Eigenvector Maps (MEMs) from a 3-D
#' coordinate matrix `(x_km, y_km, age_kyr)` built at the
#' **sample level** (one row per site × time-slice).
#' All three dimensions are z-scored before eigenvector
#' computation so that spatial and temporal extents
#' contribute equally to the Euclidean distance structure.
#' Returns the first `n_mev` eigenvectors as a data frame
#' with row names in `"dataset_name__age"` format, ready
#' for `scale_spatial_for_fit()` and
#' `assemble_data_to_fit()`.
#' @param data_coords_projected
#' A data frame with `dataset_name` as row names and
#' columns `coord_x_km` and `coord_y_km`, as returned by
#' `project_coords_to_metric()`. One row per unique
#' site/core.
#' @param data_sample_ids
#' A data frame with columns `dataset_name` and `age`
#' giving the valid (site × time-slice) pairs to model,
#' as returned by `align_sample_ids()`.
#' @param n_mev
#' A positive integer giving the number of eigenvectors to
#' return. If it exceeds the number of positive Moran
#' eigenvectors produced by `sjSDM::generateSpatialEV()`
#' for the 3-D coordinate matrix, it is automatically
#' clamped down to that count and a `cli::cli_warn()`
#' message is emitted. Default is `20L`.
#' @return
#' A data frame with row names `"<dataset_name>__<age>"`
#' and `n_mev` columns named `mev_1`, `mev_2`, …,
#' `mev_{n_mev}`. The row order follows
#' `data_sample_ids` sorted by `dataset_name` then `age`,
#' matching the ordering produced by
#' `prepare_abiotic_for_fit()` and
#' `prepare_community_for_fit()`.
#' @details
#' Unlike `compute_spatial_mev()`, which operates on
#' unique site coordinates and must be expanded to sample
#' level via `prepare_spatial_predictors_for_fit()`, this
#' function builds the eigenvectors directly on the
#' sample-level 3-D coordinate matrix. This means each
#' observation (site × age) gets a unique row in the MEV
#' matrix, and within-core temporal autocorrelation is
#' captured alongside between-site spatial autocorrelation.
#'
#' The 3-D coordinate matrix is constructed as follows:
#' 1. Join `data_coords_projected` (x_km, y_km) onto
#'    `data_sample_ids` to get one row per sample.
#' 2. Convert age (years BP) to kiloyears: `age_kyr =
#'    age / 1000`.
#' 3. Z-score each dimension independently so that the
#'    spatial and temporal extents are on the same scale
#'    before Euclidean distances are computed.
#'
#' The z-scoring step is critical: if age is left in
#' kiloyears and coordinates in km, the time axis will
#' dominate or be negligible depending on the data range,
#' producing eigenvectors that are either purely temporal
#' or purely spatial.
#'
#' Because the eigenvectors are computed at the sample
#' level, **no further expansion step is required**.
#' Pass the returned data frame directly to
#' `scale_spatial_for_fit()`.
#' @seealso
#'   [compute_spatial_mev()],
#'   [project_coords_to_metric()],
#'   [align_sample_ids()],
#'   [scale_spatial_for_fit()],
#'   [assemble_data_to_fit()]
#' @export
compute_spatiotemporal_mev <- function(
    data_coords_projected = NULL,
    data_sample_ids = NULL,
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
    msg = base::paste0(
      "data_coords_projected must contain columns",
      " 'coord_x_km' and 'coord_y_km'"
    )
  )

  assertthat::assert_that(
    is.data.frame(data_sample_ids),
    msg = "data_sample_ids must be a data frame"
  )

  assertthat::assert_that(
    all(
      c("dataset_name", "age") %in%
        base::names(data_sample_ids)
    ),
    msg = base::paste0(
      "data_sample_ids must contain columns",
      " 'dataset_name' and 'age'"
    )
  )

  assertthat::assert_that(
    is.numeric(n_mev) || is.integer(n_mev),
    length(n_mev) == 1,
    n_mev >= 1,
    msg = "n_mev must be a single positive integer"
  )

  n_mev <- base::as.integer(n_mev)

  # 1. Build sample-level 3-D coordinate data frame -----

  data_samples_3d <-
    data_sample_ids |>
    dplyr::arrange(dataset_name, age) |>
    dplyr::inner_join(
      data_coords_projected |>
        tibble::rownames_to_column("dataset_name"),
      by = dplyr::join_by(dataset_name)
    ) |>
    dplyr::mutate(
      age_kyr = age / 1000,
      .row_name = base::paste0(dataset_name, "__", age)
    )

  assertthat::assert_that(
    nrow(data_samples_3d) >= 3,
    msg = base::paste0(
      "The joined sample × site data must have at least",
      " 3 rows (required by sjSDM::generateSpatialEV())"
    )
  )

  # 2. Z-score each dimension separately -----

  mat_coords_3d_raw <-
    data_samples_3d |>
    dplyr::select(coord_x_km, coord_y_km, age_kyr) |>
    base::as.matrix()

  mat_coords_3d <-
    base::scale(
      mat_coords_3d_raw,
      center = TRUE,
      scale = TRUE
    )

  # 3. Compute Moran eigenvectors on 3-D matrix -----

  mat_mev_raw <-
    sjSDM::generateSpatialEV(
      coords = mat_coords_3d
    )

  # Force to matrix: sjSDM returns a vector when exactly
  # one positive eigenvalue is found (drops the dimension)
  mat_mev_all <-
    base::as.matrix(mat_mev_raw)

  # 4. Post-call validation: clamp n_mev if needed -----

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

  # 5. Select first n_mev columns -----

  mat_mev <-
    mat_mev_all[, base::seq_len(n_mev), drop = FALSE]

  # 6. Coerce to data frame with named columns -----

  vec_col_names <-
    base::paste0("mev_", base::seq_len(n_mev))

  res <-
    base::as.data.frame(mat_mev)

  base::colnames(res) <- vec_col_names
  base::rownames(res) <- data_samples_3d$.row_name

  return(res)
}
