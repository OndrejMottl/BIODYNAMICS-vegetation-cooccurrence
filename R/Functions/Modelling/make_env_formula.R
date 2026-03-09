#' @title Make Environmental Formula
#' @description
#' Creates a formula for environmental variables from abiotic data. If an
#' 'age' column is present and `use_age = TRUE`, creates interaction terms
#' between age and other variables. When `use_age = FALSE`, age is excluded
#' from the formula even if the column exists in `data`.
#' @param data
#' A data frame containing abiotic environmental variables. Must have at
#' least one column and one row.
#' @param use_age
#' Logical scalar. If `TRUE` (default) and an 'age' column is present in
#' `data`, produces an interaction formula `~ (var1 + var2 + ...) * age - age`.
#' If `FALSE`, age is stripped from the formula regardless of its presence
#' in `data`, producing a simple additive formula `~ var1 + var2 + ...`.
#' @return
#' A formula object suitable for modeling. If 'age' is present and
#' `use_age = TRUE`, returns a formula with interaction terms (age *
#' variables). Otherwise, returns a simple additive formula. All formulas
#' exclude intercept terms.
#' @details
#' The function constructs different formulas based on the presence of an
#' 'age' column and the `use_age` flag:
#' - With age column and `use_age = TRUE`: ~ (var1 + var2 + ...) * age - age
#' - Without age column, or `use_age = FALSE`: ~ var1 + var2 + ...
#' The formula removes intercept terms and individual variable terms when
#' interactions are present.
#' @seealso [check_and_prepare_data_for_fit()]
#' @export
make_env_formula <- function(data, use_age = TRUE) {
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

  assertthat::assert_that(
    assertthat::is.flag(use_age) && !is.na(use_age),
    msg = "use_age must be a single logical value (TRUE or FALSE)"
  )

  vec_names <- colnames(data)

  # Only treat age as active if the column is present AND use_age is TRUE
  is_age_present <- "age" %in% vec_names && isTRUE(use_age)

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
       # the expected formula for 2 bio variables is: ~ (bio1 + bio12) * age - age
        " (",
        paste0(vec_names, collapse = " + "),
        ") * age - age"
      )
  } else {
    # Strip age from names even when use_age = FALSE but age col exists
    vec_names <- vec_names[!vec_names %in% c("age")]

    assertthat::assert_that(
      length(vec_names) > 0,
      msg = "data must have at least one column other than 'age'"
    )

    formula_text <-
      paste0(
        " ~ ",
        paste0(vec_names, collapse = " + ")
      )
  }

  res <- as.formula(formula_text)

  return(res)
}
