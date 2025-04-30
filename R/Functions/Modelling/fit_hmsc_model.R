fit_hmsc_model <- function(
    data_community = NULL,
    data_abiotic = NULL,
    error_family = c("normal", "binomial"),
    fit_model = TRUE,
    # HMSC parameters
    n_chains = 20,
    n_samples = 10e3,
    n_thin = 5,
    n_transient = 2500,
    n_parallel = 20,
    n_samples_verbose = 500) {
  assertthat::assert_that(
    is.data.frame(data_community),
    msg = "data_community must be a data frame"
  )

  assertthat::assert_that(
    is.data.frame(data_abiotic),
    msg = "data_abiotic must be a data frame"
  )

  assertthat::assert_that(
    all(rownames(data_community) == rownames(data_abiotic)),
    msg = "data_abiotic_to_fit and data_community_to_fit must have the same row names"
  )

  error_family <- match.arg(error_family)

  assertthat::assert_that(
    is.character(error_family) && length(error_family) == 1,
    msg = "error_family must be a character string of length 1"
  )

  data_community_no_na <-
    tidyr::drop_na(data_community)

  data_abiotic_no_na <-
    tidyr::drop_na(data_abiotic)

  if (
    error_family == "binomial"
  ) {
    data_community_no_na <-
      data_community_no_na > 0

    error_family <- "probit"
  }

  mod_hmsc <-
    Hmsc::Hmsc(
      Y = data_community_no_na,
      XData = data_abiotic_no_na,
      distr = error_family
    )

  if (
    isFALSE(fit_model)
  ) {
    return(mod_hmsc)
  }

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
