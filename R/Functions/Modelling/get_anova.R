#' @title Get ANOVA for sjSDM Model
#' @description
#' Computes the ANOVA decomposition for a fitted sjSDM model,
#' partitioning variance explained by environmental and spatial
#' components.
#' @param mod
#' A fitted model object of class `sjSDM`.
#' @param verbose
#' Logical; if `TRUE`, prints detailed output from the ANOVA computation.
#' @return
#' An ANOVA result object as returned by `sjSDM:::anova.sjSDM()`,
#' containing variance partitioning across model components.
#' @details
#' The function wraps the internal `sjSDM:::anova.sjSDM()` method
#' with `verbose = FALSE` to suppress printed output.
#' @seealso [fit_jsdm_model()]
#' @export
get_anova <- function(
    mod,
    verbose = FALSE) {
  assertthat::assert_that(
    inherits(mod, "sjSDM"),
    msg = "The model must be of class 'sjSDM'."
  )

  assertthat::assert_that(
    assertthat::is.flag(verbose),
    !is.na(verbose) && length(verbose) == 1L,
    msg = "verbose must be a single logical value (TRUE or FALSE)."
  )

  res <-
    sjSDM:::anova.sjSDM(mod, verbose = verbose)

  return(res)
}
