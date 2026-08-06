#' @title Compute the Fast Spatial MEM Basis Engine Result
#' @description
#' Fixed-seed Nyström-strategy implementation for
#' [compute_spatial_mev_basis()].
#' @param mat_coords Numeric projected-coordinate matrix.
#' @param fast_eigenvectors Positive integer controlling the low-rank basis.
#' @param fast_seed Positive integer used locally for knot selection.
#' @param fast_function Fast Moran-eigenvector construction function.
#' @return
#' Named list containing the complete MEV matrix, fast projection state,
#' engine method, and projection method.
#' @export
compute_fast_spatial_mev_basis <- function(
    mat_coords,
    fast_eigenvectors,
    fast_seed,
    fast_function = NULL) {
  assertthat::assert_that(
    base::is.matrix(mat_coords),
    base::is.numeric(mat_coords),
    base::is.numeric(fast_eigenvectors),
    base::length(fast_eigenvectors) == 1L,
    base::is.numeric(fast_seed),
    base::length(fast_seed) == 1L,
    msg = "Fast MEM construction requires numeric matrix and settings."
  )

  if (
    base::is.null(fast_function)
  ) {
    fast_function <- spmoran::meigen_f
  }

  assertthat::assert_that(
    base::is.function(fast_function),
    msg = "The fast MEM construction argument must be a function."
  )

  list_fast_basis <-
    withr::with_seed(
      seed = base::as.integer(fast_seed),
      code = fast_function(
        coords = mat_coords,
        model = "exp",
        enum = base::as.integer(fast_eigenvectors),
        threshold = 0,
        interact = FALSE
      )
    )

  assertthat::assert_that(
    base::is.list(list_fast_basis),
    base::is.matrix(list_fast_basis[["sf"]]),
    msg = "Fast MEM construction must return a matrix in `sf`."
  )

  fast_flag <-
    list_fast_basis |>
    purrr::chuck("other", "fast")

  if (
    !base::identical(base::as.integer(fast_flag), 1L)
  ) {
    cli::cli_abort(
      c(
        "The requested fast MEM strategy did not use Nyström.",
        "i" = "Use at least 2,000 locations for the package fast path."
      )
    )
  }

  res <-
    base::list(
      mat_mev_all = list_fast_basis[["sf"]],
      list_fast_basis = list_fast_basis,
      engine_method = "spmoran_nystrom",
      projection_method = "spmoran_nystrom"
    )

  return(res)
}
