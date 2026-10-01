#' @title Compute the Exact Spatial MEM Basis Engine Result
#' @description
#' Internal exact-strategy helper for [compute_spatial_mev_basis()].
#' @param mat_coords Numeric projected-coordinate matrix.
#' @param exact_function Exact Moran-eigenvector construction function.
#' @return
#' Named list containing the complete MEV matrix, empty fast-basis state,
#' engine method, and projection method.
#' @details
#' `sjSDM::generateSpatialEV()` drops matrix dimensions when exactly one
#' positive eigenvector is available and then errors while naming columns.
#' This helper detects only that error and repeats the same calculation with
#' dimension-preserving subsetting.
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

  list_exact_attempt <-
    base::tryCatch(
      expr = base::list(
        value = exact_function(coords = mat_coords),
        error = NULL
      ),
      error = function(condition) {
        base::list(
          value = NULL,
          error = condition
        )
      }
    )

  condition_exact <-
    list_exact_attempt[["error"]]

  flag_single_vector_error <-
    base::inherits(condition_exact, "error") &&
    base::identical(
      base::conditionMessage(condition_exact),
      "argument of length 0"
    )

  if (
    !base::is.null(condition_exact) &&
      !base::isTRUE(flag_single_vector_error)
  ) {
    base::stop(condition_exact)
  }

  if (
    base::isTRUE(flag_single_vector_error)
  ) {
    mat_distance <-
      stats::dist(mat_coords) |>
      base::as.matrix()
    mat_zero <-
      base::diag(0, base::ncol(mat_distance))
    mat_weights <-
      1 / mat_distance
    mat_weights[base::is.infinite(mat_weights)] <- 1
    base::diag(mat_weights) <- 0
    vec_row_sums <-
      base::rowSums(mat_weights)
    vec_row_sums[vec_row_sums == 0] <- 1
    mat_weights_standardized <-
      mat_weights / vec_row_sums
    mat_row_means <-
      mat_zero + base::rowMeans(mat_weights_standardized)
    mat_column_means <-
      base::t(mat_zero + base::colMeans(mat_weights_standardized))
    mat_weights_centered <-
      mat_weights_standardized -
      mat_row_means -
      mat_column_means +
      base::mean(mat_weights_standardized)
    list_eigen <-
      base::eigen(mat_weights_centered, symmetric = TRUE)
    vec_scaled_eigenvalues <-
      list_eigen[["values"]] /
      base::max(base::abs(list_eigen[["values"]]))
    vec_positive <-
      vec_scaled_eigenvalues > 0

    if (
      base::sum(vec_positive) != 1L
    ) {
      base::stop(condition_exact)
    }

    mat_mev_all <-
      list_eigen[["vectors"]][, vec_positive, drop = FALSE]
    base::colnames(mat_mev_all) <- "SE_1"
    engine_method <- "sjsdm_exact_single_vector_compatibility"
  } else {
    mat_mev_all <-
      list_exact_attempt[["value"]] |>
      base::as.matrix()
    engine_method <- "sjsdm_exact"
  }

  res <-
    base::list(
      mat_mev_all = mat_mev_all,
      list_fast_basis = NULL,
      engine_method = engine_method,
      projection_method = "idw"
    )

  return(res)
}
