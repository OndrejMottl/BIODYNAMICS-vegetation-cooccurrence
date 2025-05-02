#' @title Fit HMSC Model
#' @description
#' Fits a Hierarchical Modelling of Species Communities (HMSC) model to
#' community and abiotic data.
#' @param data_community
#' A data frame containing community data. Must have the same row names as
#' `data_abiotic`.
#' @param data_abiotic
#' A data frame containing abiotic data. Must have the same row names as
#' `data_community`.
#' @param error_family
#' A character string specifying the error family. Options are "normal" or
#' "binomial" (default: "normal").
#' @param fit_model
#' Logical. If `TRUE`, the model is fitted; otherwise, only the model object
#' is returned (default: `TRUE`).
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
#' If `fit_model` is `TRUE`, returns a fitted HMSC model object. Otherwise,
#' returns an unfitted HMSC model object.
#' @details
#' Validates input data, ensures compatibility between community and abiotic
#' data, and fits an HMSC model using the specified parameters. If
#' `error_family` is "binomial", the community data is converted to binary
#' presence/absence data, and the error family is set to "probit".
#' @export
fit_hmsc_model <- function(
    data_community = NULL,
    data_abiotic = NULL,
    random_structure = NULL,
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

  study_design <-
    random_structure %>%
    purrr::chuck("study_design")

  # make sure that all rownames are the same in all data frames

  vec_shared_rownames <-
    intersect(
      rownames(data_community_no_na),
      rownames(data_abiotic_no_na)
    ) %>%
    intersect(
      rownames(study_design)
    )

  data_community_to_fit <-
    data_community_no_na %>%
    as.data.frame() %>%
    tibble::rownames_to_column("row_names") %>%
    dplyr::filter(row_names %in% vec_shared_rownames) %>%
    tibble::column_to_rownames("row_names")

  data_abiotic_to_fit <-
    data_abiotic_no_na %>%
    as.data.frame() %>%
    tibble::rownames_to_column("row_names") %>%
    dplyr::filter(row_names %in% vec_shared_rownames) %>%
    tibble::column_to_rownames("row_names")

  study_design_to_fit <-
    study_design %>%
    as.data.frame() %>%
    tibble::rownames_to_column("row_names") %>%
    dplyr::filter(row_names %in% vec_shared_rownames) %>%
    tibble::column_to_rownames("row_names")

  mod_hmsc <-
    Hmsc::Hmsc(
      Y = data_community_to_fit,
      XData = data_abiotic_to_fit,
      distr = error_family,
      studyDesign = study_design_to_fit,
      ranLevels = random_structure$random_levels
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
