#' @title Select non-collinear predictors from abiotic data
#' @description
#' Filters a data frame of abiotic variables, retaining only predictors
#' identified as non-collinear by a collinearity analysis. The selection
#' is taken from the `result$selection` element of a `collinear_output`
#' object (as returned by `compute_predictor_collinearity()`).
#' @param data_source
#' A data frame containing abiotic variables. Must include a column
#' named `abiotic_variable_name` whose values are matched against the
#' selected predictors.
#' @param res_collinearity
#' A `collinear_output` object (as returned by
#' `compute_predictor_collinearity()`). Must contain a `result$selection`
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
#' @seealso [compute_predictor_collinearity()]
#' @export
select_non_collinear_predictors <- function(data_source = NULL,
                                            res_collinearity = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_source),
    msg = "data_source must be a data frame"
  )

  assertthat::assert_that(
    base::inherits(res_collinearity, "collinear_output"),
    msg = "res_collinearity must be a collinear_output object"
  )

  assertthat::assert_that(
    "result" %in% base::names(res_collinearity),
    msg = "res_collinearity should contain a 'result' element"
  )

  assertthat::assert_that(
    "selection" %in% base::names(res_collinearity$result),
    msg = "res_collinearity$result should contain a 'selection' element"
  )

  assertthat::assert_that(
    base::is.character(res_collinearity$result$selection),
    base::length(res_collinearity$result$selection) > 0L,
    msg = "Selection of predictors should be a non-empty character vector"
  )

  data_predictors_selected <-
    data_source |>
    dplyr::filter(
      abiotic_variable_name %in% res_collinearity$result$selection
    )

  assertthat::assert_that(
    base::nrow(data_predictors_selected) > 0L,
    msg = "No predictors selected after filtering. Check collinearity results."
  )

  base::return(data_predictors_selected)
}
