#' @title Compute Predictor Collinearity
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
#' [extract_abiotic_data()] for producing the expected input format.
#' @export
compute_predictor_collinearity <- function(data_source) {
  assertthat::assert_that(
    base::is.data.frame(data_source),
    msg = "data_source must be a data frame"
  )

  assertthat::assert_that(
    base::all(
      base::c("abiotic_variable_name", "abiotic_value") %in%
        base::colnames(data_source)
    ),
    msg = stringr::str_c(
      "data_source must contain columns",
      " 'abiotic_variable_name' and 'abiotic_value'"
    )
  )

  # Capture predictor names before pivoting so the variation check
  # is restricted to predictors only (not ID/metadata columns)
  vec_predictor_names <-
    dplyr::pull(data_source, abiotic_variable_name) |>
    base::unique() |>
    base::setdiff("age")

  data_predictors_wide <-
    data_source |>
    tidyr::pivot_wider(
      names_from = abiotic_variable_name,
      values_from = abiotic_value,
      values_fill = list(abiotic_value = NA)
    ) |>
    dplyr::select(
      !dplyr::any_of(c("age"))
    )

  vec_predictor_has_variation <-
    data_predictors_wide |>
    dplyr::select(
      dplyr::any_of(vec_predictor_names)
    ) |>
    purrr::map_lgl(
      .f = ~ stats::sd(.x, na.rm = TRUE) > 0
    )

  vec_zero_variance_predictors <-
    base::names(vec_predictor_has_variation)[
      !vec_predictor_has_variation
    ]

  if (
    base::length(vec_zero_variance_predictors) > 0L
  ) {
    cli::cli_warn(
      base::c(
        "!" = stringr::str_c(
          "{base::length(vec_zero_variance_predictors)} ",
          "zero-variance column(s) ",
          "dropped before collinearity analysis:"
        ),
        "i" = "{.val {vec_zero_variance_predictors}}"
      )
    )
  }

  vec_variable_predictors <-
    base::names(vec_predictor_has_variation)[
      vec_predictor_has_variation
    ]

  if (
    base::length(vec_variable_predictors) == 0L
  ) {
    cli::cli_abort(
      base::c(
        "x" = stringr::str_c(
          "No columns with non-zero variance remain after ",
          "removing constant columns."
        ),
        "i" = stringr::str_c(
          "All {base::length(vec_predictor_names)} predictor column(s)",
          " have zero variance."
        )
      )
    )
  }

  res_collinearity <-
    data_predictors_wide |>
    dplyr::select(
      dplyr::all_of(vec_variable_predictors)
    ) |>
    collinear::collinear(quiet = TRUE)

  assertthat::assert_that(
    base::inherits(res_collinearity, "collinear_output"),
    msg = stringr::str_c(
      "Output of collinear::collinear()",
      " should be a collinear_output object"
    )
  )

  assertthat::assert_that(
    "result" %in% base::names(res_collinearity),
    msg = stringr::str_c(
      "Output of collinear::collinear()",
      " should contain a 'result' element"
    )
  )

  assertthat::assert_that(
    "selection" %in% base::names(res_collinearity$result),
    msg = stringr::str_c(
      "Output of collinear::collinear()",
      " should contain a 'selection' element in the 'result'"
    )
  )

  assertthat::assert_that(
    base::is.character(res_collinearity$result$selection),
    base::length(res_collinearity$result$selection) > 0L,
    msg = "Selection of predictors should be a non-empty character vector"
  )

  base::return(res_collinearity)
}
