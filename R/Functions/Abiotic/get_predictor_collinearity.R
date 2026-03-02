#' @title Get predictor collinearity
#' @description
#' Analyses collinearity among abiotic predictors in a long-format
#' data frame and returns a `collinear_output` object produced by
#' `collinear::collinear()`. The function pivots `data_source` from
#' long to wide format (one column per variable), removes any `age`
#' column, and then performs the collinearity analysis.
#' @param data_source
#' A data frame in long format containing at minimum the columns
#' `abiotic_variable_name` (character, predictor names) and
#' `abiotic_value` (numeric, predictor values).  An optional `age`
#' column is silently dropped before analysis.
#' @return
#' A `collinear_output` object as returned by
#' `collinear::collinear()`. The object contains a `result` element
#' with a `selection` character vector of the non-collinear predictor
#' names that were retained.
#' @details
#' The function validates inputs with `assertthat` and performs
#' post-hoc assertions on the output to guarantee structural
#' integrity before returning.  Missing values are filled with `NA`
#' when pivoting to wide format.  The `age` column is excluded
#' because it is a sampling dimension rather than a predictor.
#' @seealso
#' [collinear::collinear()] for the underlying collinearity method,
#' [get_abiotic_data()] for producing the expected input format.
#' @export
get_predictor_collinearity <- function(data_source) {
  assertthat::assert_that(
    is.data.frame(data_source),
    msg = "data_source must be a data frame"
  )

  assertthat::assert_that(
    all(c("abiotic_variable_name", "abiotic_value") %in% colnames(data_source)),
    msg = "data_source must contain columns 'abiotic_variable_name' and 'abiotic_value'"
  )


  res <-
    data_source |>
    tidyr::pivot_wider(
      names_from = abiotic_variable_name,
      values_from = abiotic_value,
      values_fill = list(abiotic_value = NA)
    ) |>
    dplyr::select(
      !dplyr::any_of(c("age"))
    ) |>
    collinear::collinear(quiet = TRUE)

  assertthat::assert_that(
    inherits(res, "collinear_output"),
    msg = "Output of collinear::collinear() should be a collinear_output object"
  )

  assertthat::assert_that(
    "result" %in% names(res),
    msg = "Output of collinear::collinear() should contain a 'result' element"
  )

  assertthat::assert_that(
    "selection" %in% names(res$result),
    msg = "Output of collinear::collinear() should contain a 'selection' element in the 'result'"
  )

  assertthat::assert_that(
    is.character(res$result$selection),
    length(res$result$selection) > 0,
    msg = "Selection of predictors should be a non-empty character vector"
  )

  return(res)
}
