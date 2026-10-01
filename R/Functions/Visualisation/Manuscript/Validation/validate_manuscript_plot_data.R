#' @title Validate Manuscript Plot Data
#' @description
#' Enforces common figure-data requirements before a manuscript figure is
#' drawn or its auditable plot-data table is written.
#' @param data_plot Data frame to validate.
#' @param required_columns Character vector of required column names.
#' @param numeric_bounds Named list. Each element must be a numeric vector of
#' length two giving inclusive lower and upper bounds for the named column.
#' Infinite bounds are permitted.
#' Missing values are allowed, but non-missing values must be finite and
#' inside the declared bounds.
#' @param allow_empty Logical scalar. If `FALSE`, zero-row data are rejected.
#' @return The validated data frame, invisibly.
#' @export
validate_manuscript_plot_data <- function(
    data_plot,
    required_columns,
    numeric_bounds = base::list(),
    allow_empty = FALSE) {
  assertthat::assert_that(
    base::is.data.frame(data_plot),
    msg = "`data_plot` must be a data frame."
  )
  assertthat::assert_that(
    base::is.character(required_columns),
    !base::any(base::is.na(required_columns)),
    !base::any(base::duplicated(required_columns)),
    msg = "`required_columns` must contain unique column names."
  )
  assertthat::assert_that(
    base::is.list(numeric_bounds),
    base::length(numeric_bounds) == 0L ||
      (
        !base::is.null(base::names(numeric_bounds)) &&
          base::all(base::nzchar(base::names(numeric_bounds))) &&
          !base::any(base::duplicated(base::names(numeric_bounds)))
      ),
    msg = "`numeric_bounds` must be a named list."
  )
  assertthat::assert_that(
    base::is.logical(allow_empty),
    base::length(allow_empty) == 1L,
    !base::is.na(allow_empty),
    msg = "`allow_empty` must be TRUE or FALSE."
  )

  vec_missing_columns <-
    base::setdiff(required_columns, base::names(data_plot))

  if (
    base::length(vec_missing_columns) > 0L
  ) {
    cli::cli_abort(
      base::c(
        "Plot data are missing required columns.",
        "x" = stringr::str_glue(
          "Missing: {stringr::str_c(vec_missing_columns, collapse = ', ')}."
        )
      )
    )
  }

  if (
    !allow_empty && base::nrow(data_plot) == 0L
  ) {
    cli::cli_abort("Plot data must contain at least one row.")
  }

  vec_bound_columns <-
    base::names(numeric_bounds)

  if (
    !base::all(vec_bound_columns %in% base::names(data_plot))
  ) {
    cli::cli_abort(
      "Every `numeric_bounds` name must identify a plot-data column."
    )
  }

  for (
    column_name in vec_bound_columns
  ) {
    vec_bounds <-
      numeric_bounds[[column_name]]
    assertthat::assert_that(
      base::is.numeric(vec_bounds),
      base::length(vec_bounds) == 2L,
      !base::any(base::is.na(vec_bounds)),
      vec_bounds[[1L]] <= vec_bounds[[2L]],
      msg = stringr::str_glue(
        "Bounds for `{column_name}` must be two ordered numbers."
      )
    )

    vec_values <-
      data_plot[[column_name]]
    assertthat::assert_that(
      base::is.numeric(vec_values),
      msg = stringr::str_glue("`{column_name}` must be numeric.")
    )

    vec_observed <-
      vec_values[!base::is.na(vec_values)]
    flag_invalid_values <-
      base::any(!base::is.finite(vec_observed)) ||
      base::any(vec_observed < vec_bounds[[1L]]) ||
      base::any(vec_observed > vec_bounds[[2L]])

    if (
      flag_invalid_values
    ) {
      cli::cli_abort(
        base::c(
          "Plot data violate declared numeric bounds.",
          "x" = stringr::str_glue(
            "`{column_name}` must remain within ",
            "[{vec_bounds[[1L]]}, {vec_bounds[[2L]]}]."
          )
        )
      )
    }
  }

  return(base::invisible(data_plot))
}
