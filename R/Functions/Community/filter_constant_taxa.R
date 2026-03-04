#' @title Filter Constant Taxa from Community Matrix
#' @description
#' Removes taxa whose presence/absence shows no variation across
#' all samples. For binomial models, a taxon with all-zero or
#' all-one presence values cannot contribute to the likelihood and
#' must be excluded before fitting.
#' @param data_community_matrix
#' A numeric matrix with samples as rows and taxa as columns, as
#' returned by `prepare_community_for_fit()`.
#' @param error_family
#' A character string specifying the error family used for model
#' fitting. Must be `"binomial"` or `"gaussian"`. Filtering is
#' only applied when `error_family = "binomial"`.
#' @return
#' A numeric matrix of the same structure as the input, with
#' constant-presence taxa (all absent or all present) removed.
#' When `error_family = "gaussian"` the input matrix is returned
#' unchanged.
#' @details
#' For binomial models, taxa are converted to binary
#' presence/absence (`> 0`) before checking for variation.
#' A taxon is retained only if `0 < column_sum < n_samples`.
#' This step was previously performed silently inside
#' `fit_jsdm_model()` and is now a tracked pipeline target.
#' @seealso [prepare_community_for_fit()],
#'   [assemble_data_to_fit()]
#' @export
filter_constant_taxa <- function(
    data_community_matrix = NULL,
    error_family = c("binomial", "gaussian")) {
  assertthat::assert_that(
    is.matrix(data_community_matrix),
    msg = "data_community_matrix must be a matrix"
  )

  error_family <- match.arg(error_family)

  if (
    error_family == "binomial"
  ) {
    data_presence <-
      data_community_matrix > 0

    vec_has_any_presence <-
      colSums(data_presence) > 0

    vec_not_always_present <-
      colSums(data_presence) < nrow(data_presence)

    data_community_matrix <-
      data_community_matrix[
        ,
        vec_has_any_presence & vec_not_always_present,
        drop = FALSE
      ]
  }

  return(data_community_matrix)
}
