#' @title Prepare the sjSDM Response and Error Family
#' @description
#' Internal helper that preserves the response preparation performed by
#' `fit_jsdm_model()`.
#' @param data_community Community response matrix.
#' @param error_family Selected error-family name.
#' @return Named list containing the prepared community matrix and family.
#' @keywords internal
#' @noRd
.prepare_sjsdm_response <- function(
    data_community = NULL,
    error_family = c("gaussian", "binomial")) {
  error_family <- base::match.arg(error_family)

  if (
    error_family == "binomial"
  ) {
    data_community <- data_community > 0
    error_family <- stats::binomial("probit")
  } else {
    error_family <- stats::gaussian()
  }

  return(
    base::list(
      data_community = data_community,
      error_family = error_family
    )
  )
}
