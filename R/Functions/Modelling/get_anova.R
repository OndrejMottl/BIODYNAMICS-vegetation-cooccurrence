#' @title Get ANOVA for sjSDM Model
#' @description
#' Computes the ANOVA decomposition for a fitted sjSDM model,
#' partitioning variance explained by environmental and spatial
#' components.
#' @param mod
#' A fitted model object of class `sjSDM`.
#' @return
#' An ANOVA result object as returned by `sjSDM:::anova.sjSDM()`,
#' containing variance partitioning across model components.
#' @details
#' The function wraps the internal `sjSDM:::anova.sjSDM()` method
#' with `verbose = FALSE` to suppress printed output.
#' @seealso [fit_hmsc_model()]
#' @export
get_anova <- function(mod) {
  assertthat::assert_that(
    inherits(mod, "sjSDM"),
    msg = "The model must be of class 'sjSDM'."
  )

  res <-
    sjSDM:::anova.sjSDM(mod, verbose = FALSE)

  return(res)
}
