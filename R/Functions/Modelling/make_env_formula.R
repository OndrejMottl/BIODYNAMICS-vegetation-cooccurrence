#' @title Make Environmental Formula
#' @description
#' Creates a formula for environmental variables from abiotic data. If an
#' 'age' column is present, creates interaction terms between age and other
#' variables.
#' @param data
#' A data frame containing abiotic environmental variables. Must have at
#' least one column and one row.
#' @return
#' A formula object suitable for modeling. If 'age' is present, returns a
#' formula with interaction terms (age * variables). Otherwise, returns a
#' simple additive formula. All formulas exclude intercept terms.
#' @details
#' The function constructs different formulas based on the presence of an
#' 'age' column:
#' - With age: ~ age * (var1 + var2 + ...) - 0 - var1 - var2 - ...
#' - Without age: ~ var1 + var2 + ... - 0 - var1 - var2 - ...
#' The formula removes intercept terms and individual variable terms when
#' interactions are present.
#' @export
make_env_formula <- function(data) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    ncol(data) > 0,
    msg = "data must have at least one column"
  )

  assertthat::assert_that(
    nrow(data) > 0,
    msg = "data must have at least one row"
  )

  vec_names <- colnames(data)

  is_age_present <- "age" %in% vec_names

  if (
    isTRUE(is_age_present)
  ) {
    vec_names <- vec_names[!vec_names %in% c("age")]

    assertthat::assert_that(
      length(vec_names) > 0,
      msg = "data must have at least one column other than 'age' when 'age' is present"
    )

    formula_text <-
      paste0(
        " ~ ",
        " age * (",
        paste0(vec_names, collapse = " + "),
        ") - 0 - ",
        paste0(vec_names, collapse = " - ")
      )
  } else {
    formula_text <-
      paste0(
        " ~ ",
        paste0(vec_names, collapse = " + ")
      )
  }

  res <- as.formula(formula_text)

  return(res)
}
