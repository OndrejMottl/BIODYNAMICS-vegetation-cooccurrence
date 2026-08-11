#' @title Compute the Exact Spatial MEM Basis Engine Result
#' @description
#' Internal exact-strategy helper for [compute_spatial_mev_basis()].
#' @param mat_coords Numeric projected-coordinate matrix.
#' @param exact_function Exact Moran-eigenvector construction function.
#' @return
#' Named list containing the complete MEV matrix, empty fast-basis state,
#' engine method, and projection method.
#' @keywords internal
#' @keywords internal
.compute_exact_spatial_mev_basis <- function(
    mat_coords,
    exact_function) {
  assertthat::assert_that(
    base::is.matrix(mat_coords),
    base::is.numeric(mat_coords),
    base::is.function(exact_function),
    msg = "Exact MEM construction requires a matrix and engine function."
  )

  mat_mev_all <-
    exact_function(coords = mat_coords) |>
    base::as.matrix()

  res <-
    base::list(
      mat_mev_all = mat_mev_all,
      list_fast_basis = NULL,
      engine_method = "sjsdm_exact",
      projection_method = "idw"
    )

  return(res)
}
