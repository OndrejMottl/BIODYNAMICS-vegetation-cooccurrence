#' @title Resolve sjSDM Early-Stopping Patience
#' @description
#' Internal helper that preserves the three-tier early-stopping semantics used
#' by `fit_jsdm_model()`.
#' @param iter Positive number of fitting epochs.
#' @param n_early_stopping Requested patience or `NULL` for automatic mode.
#' @return Integer early-stopping patience passed to `sjSDMControl()`.
#' @keywords internal
#' @noRd
.resolve_sjsdm_early_stopping <- function(
    iter = 100L,
    n_early_stopping = NULL) {
  minimum_patience <-
    base::as.integer(base::round(iter * 0.20))

  if (
    base::is.null(n_early_stopping)
  ) {
    return(minimum_patience)
  }

  if (
    n_early_stopping <= 0
  ) {
    return(0L)
  }

  return(
    base::max(
      base::as.integer(n_early_stopping),
      minimum_patience
    )
  )
}
