#' @title Get predictor collinearity
#' @description
#' Analyses collinearity among abiotic predictors in a long-format
#' data frame and returns a `collinear_output` object produced by
#' `collinear::collinear()`. The function pivots `data_source` from
#' long to wide format (one column per variable), removes any `age`
#' column, screens out zero-variance columns, and then performs the
#' collinearity analysis.
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
#' Predictor names are captured before pivoting so that the
#' zero-variance check is scoped to predictor columns only —
#' ID or metadata columns that survive the pivot are never passed
#' to `collinear::collinear()`.  Any predictor whose standard
#' deviation is zero across all samples is dropped and reported via
#' `cli::cli_warn()`.  If no predictor with non-zero variance
#' remains, the function aborts via `cli::cli_abort()`.
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
    all(
      c("abiotic_variable_name", "abiotic_value") %in%
        colnames(data_source)
    ),
    msg = paste0(
      "data_source must contain columns",
      " 'abiotic_variable_name' and 'abiotic_value'"
    )
  )

  # Capture predictor names before pivoting so the variation check
  # is restricted to predictors only (not ID/metadata columns)
  vec_predictor_names <-
    dplyr::pull(data_source, abiotic_variable_name) |>
    base::unique() |>
    base::setdiff(c("age"))

  data_wide <-
    data_source |>
    tidyr::pivot_wider(
      names_from = abiotic_variable_name,
      values_from = abiotic_value,
      values_fill = list(abiotic_value = NA)
    ) |>
    dplyr::select(
      !dplyr::any_of(c("age"))
    )

  vec_has_variation <-
    data_wide |>
    dplyr::select(
      dplyr::any_of(vec_predictor_names)
    ) |>
    purrr::map_lgl(
      .f = ~ stats::sd(.x, na.rm = TRUE) > 0
    )

  vec_cols_zero_var <-
    base::names(vec_has_variation)[!vec_has_variation]

  if (
    base::length(vec_cols_zero_var) > 0
  ) {
    cli::cli_warn(
      c(
        "!" = paste0(
          "{base::length(vec_cols_zero_var)} zero-variance column(s) ",
          "dropped before collinearity analysis:"
        ),
        "i" = "{.val {vec_cols_zero_var}}"
      )
    )
  }

  vec_cols_with_variation <-
    base::names(vec_has_variation)[vec_has_variation]

  if (
    base::length(vec_cols_with_variation) == 0L
  ) {
    cli::cli_abort(
      c(
        "x" = paste0(
          "No columns with non-zero variance remain after ",
          "removing constant columns."
        ),
        "i" = paste0(
          "All {base::length(vec_predictor_names)} predictor column(s)",
          " have zero variance."
        )
      )
    )
  }

  res <-
    data_wide |>
    dplyr::select(
      dplyr::all_of(vec_cols_with_variation)
    ) |>
    collinear::collinear(quiet = TRUE)

  assertthat::assert_that(
    inherits(res, "collinear_output"),
    msg = paste0(
      "Output of collinear::collinear()",
      " should be a collinear_output object"
    )
  )

  assertthat::assert_that(
    "result" %in% names(res),
    msg = paste0(
      "Output of collinear::collinear()",
      " should contain a 'result' element"
    )
  )

  assertthat::assert_that(
    "selection" %in% names(res$result),
    msg = paste0(
      "Output of collinear::collinear()",
      " should contain a 'selection' element in the 'result'"
    )
  )

  assertthat::assert_that(
    is.character(res$result$selection),
    length(res$result$selection) > 0,
    msg = "Selection of predictors should be a non-empty character vector"
  )

  return(res)
}
