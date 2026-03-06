#' @title Binarize Community Data Matrix
#' @description
#' Converts a numeric community matrix of proportions (or
#' counts) to a binary presence-absence matrix. Any value
#' strictly greater than zero is recoded as `1L`; zeros
#' remain `0L`. The resulting integer matrix is suitable
#' for `filter_constant_taxa()` when the model uses a
#' binomial error family.
#' @param data_community_matrix
#' A numeric matrix with samples as rows and taxa as columns,
#' as returned by `prepare_community_for_fit()`. Values must
#' be non-negative.
#' @return
#' An integer matrix of the same dimensions and dimnames as
#' the input, with all non-zero values replaced by `1L`.
#' @details
#' Pre-binarization before `filter_constant_taxa()` is
#' essential when using a binomial error family: a taxon
#' recorded at non-zero varying proportions in every sample
#' has positive SD on the proportion scale but becomes a
#' constant-1 column after binarization inside the model,
#' causing implicit intercept saturation. Applying this
#' function first ensures that `filter_constant_taxa()`
#' removes such taxa before they reach the model.
#'
#' For other error families (e.g., Gaussian, future hurdle
#' models) the raw proportional matrix should be passed to
#' `filter_constant_taxa()` directly; use the
#' `error_family` configuration key to control this choice
#' in the pipeline.
#' @seealso [prepare_community_for_fit()],
#'   [filter_constant_taxa()], [assemble_data_to_fit()]
#' @export
binarize_community_data <- function(
    data_community_matrix = NULL) {
  assertthat::assert_that(
    is.matrix(data_community_matrix),
    msg = "data_community_matrix must be a matrix"
  )

  assertthat::assert_that(
    is.numeric(data_community_matrix),
    msg = "data_community_matrix must be a numeric matrix"
  )

  assertthat::assert_that(
    nrow(data_community_matrix) > 0,
    msg = "data_community_matrix must have at least one row"
  )

  assertthat::assert_that(
    ncol(data_community_matrix) > 0,
    msg = "data_community_matrix must have at least one column"
  )

  assertthat::assert_that(
    base::all(data_community_matrix >= 0, na.rm = TRUE),
    msg = "data_community_matrix values must all be >= 0"
  )

  res <-
    (data_community_matrix > 0) * 1L

  base::rownames(res) <- base::rownames(data_community_matrix)
  base::colnames(res) <- base::colnames(data_community_matrix)

  return(res)
}
