#' @title Make HMSC Model
#' @description
#' Create a Hierarchical Modelling of Species Communities (HMSC) model to
#' fit community and abiotic data.
#' @param data_to_fit
#' A list containing the community and abiotic data to fit the model.
#' @param random_structure
#' A list containing the random structure for the model, including the
#' study design and random levels.
#' @param error_family
#' A character string specifying the error family. Options are "normal" or
#' "binomial" (default: "normal").
#' @return
#' returns an unfitted HMSC model object.
#' @details
#' If `error_family` is "binomial", the community data is converted to binary
#' presence/absence data, and the error family is set to "probit".
#' @export
make_hmsc_model <- function(
    data_to_fit = NULL,
    sel_formula = NULL,
    random_structure = NULL,
    error_family = c("normal", "binomial")) {
  assertthat::assert_that(
    is.list(data_to_fit),
    msg = "data_to_fit must be a list"
  )

  data_community <-
    data_to_fit %>%
    purrr::chuck("data_community_to_fit")


  assertthat::assert_that(
    is.data.frame(data_community),
    msg = "data_community must be a data frame"
  )

  data_abiotic <-
    data_to_fit %>%
    purrr::chuck("data_abiotic_to_fit")


  assertthat::assert_that(
    is.data.frame(data_abiotic),
    msg = "data_abiotic must be a data frame"
  )


  assertthat::assert_that(
    is.character(sel_formula),
    msg = "sel_formula must be a character string "
  )

  assertthat::assert_that(
    any(
      error_family %in% c("normal", "binomial")
    ),
    msg = "error_family must be either 'normal' or 'binomial'"
  )

  error_family <- match.arg(error_family)

  assertthat::assert_that(
    length(sel_formula) == 1,
    msg = "sel_formula must be a character string of length 1"
  )

  if (
    error_family == "binomial"
  ) {
    data_community <-
      data_community > 0

    error_family <- "probit"
  }

  assertthat::assert_that(
    is.list(random_structure),
    msg = "random_structure must be a list"
  )

  assertthat::assert_that(
    all(c("study_design", "random_levels") %in% names(random_structure)),
    msg = "random_structure must contain study_design and random_levels"
  )

  study_design <-
    random_structure %>%
    purrr::chuck("study_design")

  mod_hmsc <-
    Hmsc::Hmsc(
      Y = data_community,
      XData = data_abiotic,
      XFormula = as.formula(sel_formula),
      distr = error_family,
      studyDesign = study_design,
      ranLevels = random_structure$random_levels
    )

  return(mod_hmsc)
}
