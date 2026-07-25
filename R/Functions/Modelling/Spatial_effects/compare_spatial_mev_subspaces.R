#' @title Compare Spatial MEM Subspaces
#' @description
#' Compares two spatial MEM bases with sign- and rotation-invariant canonical
#' correlations and principal angles.
#' @param data_mev_reference,data_mev_candidate
#' Numeric data frames or matrices with aligned rows.
#' @return
#' One-row tibble containing aligned row count, compared dimension, canonical
#' correlation summaries, and the largest principal angle in degrees.
#' @export
compare_spatial_mev_subspaces <- function(
    data_mev_reference,
    data_mev_candidate) {
  mat_reference <-
    base::as.matrix(data_mev_reference)

  mat_candidate <-
    base::as.matrix(data_mev_candidate)

  assertthat::assert_that(
    base::is.numeric(mat_reference),
    base::is.numeric(mat_candidate),
    base::nrow(mat_reference) == base::nrow(mat_candidate),
    base::nrow(mat_reference) > 0L,
    base::ncol(mat_reference) > 0L,
    base::ncol(mat_candidate) > 0L,
    base::all(base::is.finite(mat_reference)),
    base::all(base::is.finite(mat_candidate)),
    msg = "MEM bases must be finite numeric matrices with aligned rows."
  )

  qr_reference <-
    base::qr(mat_reference)

  qr_candidate <-
    base::qr(mat_candidate)

  rank_reference <-
    qr_reference[["rank"]]

  rank_candidate <-
    qr_candidate[["rank"]]

  n_dimensions <-
    base::min(rank_reference, rank_candidate)

  assertthat::assert_that(
    n_dimensions > 0L,
    msg = "MEM bases must each contain at least one non-zero dimension."
  )

  mat_q_reference <-
    base::qr.Q(qr_reference)[
      ,
      base::seq_len(rank_reference),
      drop = FALSE
    ]

  mat_q_candidate <-
    base::qr.Q(qr_candidate)[
      ,
      base::seq_len(rank_candidate),
      drop = FALSE
    ]

  vec_canonical_correlations <-
    base::svd(
      base::crossprod(mat_q_reference, mat_q_candidate),
      nu = 0L,
      nv = 0L
    )[["d"]] |>
    utils::head(n_dimensions) |>
    base::pmin(1) |>
    base::pmax(0)

  vec_principal_angles_degrees <-
    base::acos(vec_canonical_correlations) * 180 / base::pi

  res <-
    tibble::tibble(
      n_rows = base::nrow(mat_reference),
      rank_reference = rank_reference,
      rank_candidate = rank_candidate,
      n_dimensions = n_dimensions,
      mean_squared_canonical_correlation =
        base::mean(vec_canonical_correlations^2),
      minimum_canonical_correlation =
        base::min(vec_canonical_correlations),
      maximum_principal_angle_degrees =
        base::max(vec_principal_angles_degrees)
    )

  return(res)
}
