#' @title Check Abiotic Interpolation Contract
#' @description
#' Validates that abiotic interpolation inputs use the deterministic
#' interpolation contract and do not contain age-uncertainty routing artifacts.
#' @param data
#' A data frame containing abiotic data to interpolate.
#' @param by
#' A character vector of column names that will be used to group interpolation.
#' Must not include uncertainty iteration columns.
#' @param age_var
#' Name of the age variable column used for interpolation. Must not be
#' `age_uncertainty`.
#' @return
#' The input `data`, invisibly, when the contract is valid.
#' @details
#' Abiotic predictors must use deterministic sample ages. Age uncertainty is
#' restricted to paleo community interpolation through
#' [interpolate_community_data_with_uncertainty()]. This guard fails fast if
#' uncertainty columns or uncertainty-routing arguments reach the abiotic path.
#' @seealso
#' [interpolate_data()], [interpolate_community_data_with_uncertainty()]
#' @export
check_abiotic_interpolation_contract <- function(data,
                                                 by = "dataset_name",
                                                 age_var = "age") {
  assertthat::assert_that(
    base::is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    base::is.character(by) && base::length(by) > 0,
    msg = "by must be a character vector with at least one element"
  )

  assertthat::assert_that(
    base::is.character(age_var) && base::length(age_var) == 1,
    msg = "age_var must be a single character string"
  )

  vec_uncertainty_artifacts <-
    base::c(
      "iteration",
      "age_uncertainty"
    )

  vec_data_artifacts <-
    base::intersect(
      vec_uncertainty_artifacts,
      base::colnames(data)
    )

  assertthat::assert_that(
    base::length(vec_data_artifacts) == 0,
    msg = stringr::str_glue(
      "Abiotic interpolation must be deterministic; uncertainty columns ",
      "are not allowed: ",
      "{stringr::str_c(vec_data_artifacts, collapse = ', ')}"
    )
  )

  vec_by_artifacts <-
    base::intersect(
      vec_uncertainty_artifacts,
      by
    )

  assertthat::assert_that(
    base::length(vec_by_artifacts) == 0,
    msg = stringr::str_glue(
      "Abiotic interpolation must be deterministic; uncertainty grouping ",
      "columns are not allowed: ",
      "{stringr::str_c(vec_by_artifacts, collapse = ', ')}"
    )
  )

  assertthat::assert_that(
    !age_var %in% "age_uncertainty",
    msg = stringr::str_c(
      "Abiotic interpolation must be deterministic; ",
      "age_var cannot be age_uncertainty"
    )
  )

  base::return(base::invisible(data))
}
