#' @title Validate Abiotic Interpolation Contract
#' @description
#' Validates that abiotic interpolation inputs use the deterministic
#' interpolation contract and do not contain age-uncertainty routing artifacts.
#' @param data_source
#' A data frame containing abiotic data to interpolate.
#' @param grouping_variables
#' A character vector of column names that will be used to group interpolation.
#' Must not include uncertainty iteration columns.
#' @param age_variable_name
#' Name of the age variable column used for interpolation. Must not be
#' `age_uncertainty`.
#' @return
#' The input `data_source`, invisibly, when the contract is valid.
#' @details
#' Abiotic predictors must use deterministic sample ages. Age uncertainty is
#' restricted to paleo community interpolation through
#' [interpolate_paleo_community_with_age_uncertainty()]. This guard fails fast if
#' uncertainty columns or uncertainty-routing arguments reach the abiotic path.
#' @seealso
#' [interpolate_grouped_time_series()],
#' [interpolate_paleo_community_with_age_uncertainty()]
#' @export
validate_abiotic_interpolation_contract <- function(
    data_source,
    grouping_variables = "dataset_name",
    age_variable_name = "age") {
  assertthat::assert_that(
    base::is.data.frame(data_source),
    msg = "data_source must be a data frame"
  )

  assertthat::assert_that(
    base::is.character(grouping_variables) &&
      base::length(grouping_variables) > 0L,
    msg = stringr::str_c(
      "grouping_variables must be a character vector ",
      "with at least one element"
    )
  )

  assertthat::assert_that(
    base::is.character(age_variable_name) &&
      base::length(age_variable_name) == 1L,
    msg = "age_variable_name must be a single character string"
  )

  vec_uncertainty_artifacts <-
    base::c(
      "iteration",
      "age_uncertainty"
    )

  vec_present_data_artifacts <-
    base::intersect(
      vec_uncertainty_artifacts,
      base::colnames(data_source)
    )

  assertthat::assert_that(
    base::length(vec_present_data_artifacts) == 0L,
    msg = stringr::str_glue(
      "Abiotic interpolation must be deterministic; uncertainty columns ",
      "are not allowed: ",
      "{stringr::str_c(vec_present_data_artifacts, collapse = ', ')}"
    )
  )

  vec_present_grouping_artifacts <-
    base::intersect(
      vec_uncertainty_artifacts,
      grouping_variables
    )

  assertthat::assert_that(
    base::length(vec_present_grouping_artifacts) == 0L,
    msg = stringr::str_glue(
      "Abiotic interpolation must be deterministic; uncertainty grouping ",
      "columns are not allowed: ",
      "{stringr::str_c(vec_present_grouping_artifacts, collapse = ', ')}"
    )
  )

  assertthat::assert_that(
    !age_variable_name %in% "age_uncertainty",
    msg = stringr::str_c(
      "Abiotic interpolation must be deterministic; ",
      "age_variable_name cannot be age_uncertainty"
    )
  )

  base::return(base::invisible(data_source))
}
