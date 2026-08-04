#' @title Compute Community Presence-Absence Matrix
#' @description
#' Computes a binary presence-absence matrix from numeric community
#' proportions or counts. Positive values become `1L`; zeros and missing
#' values become `0L`.
#' @param mat_community
#' A numeric matrix with samples as rows and taxa as columns,
#' as returned by `prepare_community_for_fit()`. Values must
#' be non-negative.
#' @return
#' An integer matrix with the same dimensions and dimnames as
#' `mat_community`, containing only `0L` and `1L`.
#' @details
#' Presence-absence conversion before `filter_constant_taxa()` is essential
#' when using a binomial error family: a taxon
#' recorded at non-zero varying proportions in every sample
#' has positive SD on the proportion scale but becomes a
#' constant-1 column after conversion inside the model,
#' causing implicit intercept saturation. Applying this
#' function first ensures that `filter_constant_taxa()`
#' removes such taxa before they reach the model.
#'
#' For other error families (e.g., Gaussian, future hurdle
#' models) the raw proportional matrix should be passed to
#' `filter_constant_taxa()` directly; use the
#' `error_family` configuration key to control this choice
#' in the pipeline.
#' @examples
#' mat_community <-
#'   base::matrix(
#'     base::c(0, 0.25, NA_real_, 1),
#'     nrow = 2
#'   )
#'
#' compute_community_presence_absence(
#'   mat_community = mat_community
#' )
#' @seealso [prepare_community_for_fit()],
#'   [filter_constant_taxa()], [build_jsdm_fit_input()]
#' @export
compute_community_presence_absence <- function(
    mat_community = NULL) {
  assertthat::assert_that(
    base::is.matrix(mat_community),
    msg = "mat_community must be a matrix"
  )

  assertthat::assert_that(
    base::is.numeric(mat_community),
    msg = "mat_community must be a numeric matrix"
  )

  assertthat::assert_that(
    base::nrow(mat_community) > 0L,
    msg = "mat_community must have at least one row"
  )

  assertthat::assert_that(
    base::ncol(mat_community) > 0L,
    msg = "mat_community must have at least one column"
  )

  assertthat::assert_that(
    base::all(
      mat_community >= 0,
      na.rm = TRUE
    ),
    msg = "mat_community values must all be >= 0"
  )

  res_community_presence_absence <-
    base::replace(
      x = (mat_community > 0) * 1L,
      list = base::is.na(mat_community),
      values = 0L
    )

  return(res_community_presence_absence)
}
