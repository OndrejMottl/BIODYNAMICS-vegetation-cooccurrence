#' @title Fit HMSC Model
#' @description
#' Sample the MCMC process for the HMSC model.
#' @param mod_hmsc
#' An unfitted HMSC model object.
#' @param n_chains
#' Number of MCMC chains (default: 20).
#' @param n_samples
#' Number of MCMC samples (default: 10,000).
#' @param n_thin
#' Thinning interval for MCMC samples (default: 5).
#' @param n_transient
#' Number of transient iterations (default: 2,500).
#' @param n_parallel
#' Number of parallel chains (default: 20).
#' @param n_samples_verbose
#' Verbosity interval for MCMC sampling (default: 500).
#' @return
#' Returns a fitted HMSC model object.
#' @export
fit_hmsc_model <- function(
    mod_hmsc,
    n_chains = 20,
    n_samples = 10e3,
    n_thin = 1,
    n_transient = 2500,
    n_parallel = 20,
    n_samples_verbose = 500) {
  assertthat::assert_that(
    inherits(mod_hmsc, "Hmsc"),
    msg = "mod_hmsc must be an HMSC model object"
  )

  assertthat::assert_that(
    is.numeric(n_chains) && n_chains > 0,
    msg = "n_chains must be a positive number"
  )

  assertthat::assert_that(
    is.numeric(n_samples) && n_samples > 0,
    msg = "n_samples must be a positive number"
  )

  assertthat::assert_that(
    is.numeric(n_thin) && n_thin > 0,
    msg = "n_thin must be a positive number"
  )

  assertthat::assert_that(
    is.numeric(n_transient) && n_transient > 0,
    msg = "n_transient must be a positive number"
  )

  assertthat::assert_that(
    is.numeric(n_parallel) && n_parallel > 0,
    msg = "n_parallel must be a positive number"
  )

  assertthat::assert_that(
    is.numeric(n_samples_verbose) && n_samples_verbose > 0,
    msg = "n_samples_verbose must be a positive number"
  )

  mod_hmsc_fitted <-
    Hmsc::sampleMcmc(
      mod_hmsc,
      nChains = n_chains,
      samples = n_samples,
      thin = n_thin,
      transient = n_transient,
      verbose = n_samples_verbose,
      nParallel = n_parallel
    )

  return(mod_hmsc_fitted)
}
