#' @title Select non-collinear predictors from abiotic data
#' @description
#' Filters a data frame of abiotic variables, retaining only predictors
#' identified as non-collinear by a collinearity analysis. The selection
#' is taken from the `result$selection` element of a `collinear_output`
#' object (as returned by `get_predictor_collinearity()`).
#' @param data_source
#' A data frame containing abiotic variables. Must include a column
#' named `abiotic_variable_name` whose values are matched against the
#' selected predictors.
#' @param collinearity_res
#' A `collinear_output` object (as returned by
#' `get_predictor_collinearity()`). Must contain a `result$selection`
#' element — a non-empty character vector of selected predictor names.
#' @return
#' A filtered data frame (same structure as `data_source`) containing
#' only rows whose `abiotic_variable_name` is in the set of selected
#' non-collinear predictors.
#' @details
#' Input validation is performed with `assertthat`. The function
#' requires that the filtering produces at least one row; if no
#' predictor names match, an error is raised suggesting the user check
#' the collinearity results.
#' @seealso [get_predictor_collinearity()]
#' @export
select_non_collinear_predictors <- function(data_source = NULL,
                                            collinearity_res = NULL) {
  assertthat::assert_that(
    is.data.frame(data_source),
    msg = "data_source must be a data frame"
  )

  assertthat::assert_that(
    inherits(collinearity_res, "collinear_output"),
    msg = "collinearity_res must be a collinear_output object"
  )

  assertthat::assert_that(
    "result" %in% names(collinearity_res),
    msg = "collinearity_res should contain a 'result' element"
  )

  assertthat::assert_that(
    "selection" %in% names(collinearity_res$result),
    msg = "collinearity_res$result should contain a 'selection' element"
  )

  assertthat::assert_that(
    is.character(collinearity_res$result$selection),
    length(collinearity_res$result$selection) > 0,
    msg = "Selection of predictors should be a non-empty character vector"
  )

  res <-
    data_source |>
    dplyr::filter(
      abiotic_variable_name %in% collinearity_res$result$selection
    )

  assertthat::assert_that(
    nrow(res) > 0,
    msg = "No predictors selected after filtering. Check collinearity results."
  )

  return(res)
}
