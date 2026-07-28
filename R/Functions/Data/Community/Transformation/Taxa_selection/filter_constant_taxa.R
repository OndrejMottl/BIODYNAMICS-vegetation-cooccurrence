#' @title Filter Constant Taxa from Community Matrix
#' @description
#' Removes taxa that show no variation across all samples. A
#' taxon is considered constant when its standard deviation is
#' zero, meaning every sample has the same value. Constant
#' taxa cannot contribute to any model likelihood and must be
#' excluded before fitting. Filtering is applied regardless of
#' the error family (binomial, Gaussian, Poisson, beta, etc.).
#' @param data_community_matrix
#' A numeric matrix with samples as rows and taxa as columns,
#' as returned by `prepare_community_for_fit()`.
#' @return
#' A numeric matrix of the same structure as the input, with
#' all constant taxa (standard deviation equal to zero) removed.
#' If no taxa are constant the input matrix is returned
#' unchanged.
#' @details
#' Variation is assessed by computing `stats::sd()` for each
#' column via `purrr::map_dbl()`. A column is retained only
#' when its standard deviation is strictly greater than zero.
#' This family-agnostic approach replaces the previous
#' binomial-only binarisation check and is now a tracked
#' pipeline target.
#' @seealso [prepare_community_for_fit()],
#'   [assemble_data_to_fit()]
#' @export
filter_constant_taxa <- function(
    data_community_matrix = NULL) {
  assertthat::assert_that(
    is.matrix(data_community_matrix),
    msg = "data_community_matrix must be a matrix"
  )

  vec_col_sd <-
    purrr::map_dbl(
      .x = colnames(data_community_matrix),
      .f = ~ stats::sd(data_community_matrix[, .x])
    )

  vec_is_variable <-
    vec_col_sd > 0

  data_community_matrix <-
    data_community_matrix[
      ,
      vec_is_variable,
      drop = FALSE
    ]

  return(data_community_matrix)
}
