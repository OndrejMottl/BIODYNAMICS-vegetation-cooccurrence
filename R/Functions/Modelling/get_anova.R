#' @title Get ANOVA for sjSDM Model
#' @description
#' Computes the ANOVA decomposition for a fitted sjSDM model,
#' partitioning variance explained by environmental and spatial
#' components.
#' @param mod
#' A fitted model object of class `sjSDM`.
#' @param n_samples
#' Integer; number of Monte Carlo samples used for the variation
#' partitioning calculation. Larger values yield more stable
#' estimates but are slower. Defaults to `5000L`.
#' @param verbose
#' Logical; if `TRUE`, prints detailed output from the ANOVA
#' computation.
#' @return
#' An ANOVA result object as returned by `sjSDM:::anova.sjSDM()`,
#' containing variance partitioning across model components.
#' @details
#' The function wraps the internal `sjSDM:::anova.sjSDM()` method.
#' The `n_samples` argument controls how many Monte Carlo draws are
#' used to approximate the likelihoods in each variation partition.
#' For exploratory runs, a value of 1000 is sufficient; for
#' publication-quality results, 3000–5000 is recommended.
#' @seealso [fit_jsdm_model()]
#' @export
get_anova <- function(
    mod,
    n_samples = 5000L,
    verbose = FALSE) {
  assertthat::assert_that(
    inherits(mod, "sjSDM"),
    msg = "The model must be of class 'sjSDM'."
  )

  assertthat::assert_that(
    assertthat::is.count(n_samples),
    msg = "n_samples must be a single positive integer."
  )

  assertthat::assert_that(
    assertthat::is.flag(verbose),
    !is.na(verbose) && length(verbose) == 1L,
    msg = "verbose must be a single logical value (TRUE or FALSE)."
  )

  res <-
    sjSDM:::anova.sjSDM(mod, samples = n_samples, verbose = verbose)

  return(res)
}
