#' @title Build the sjSDM Environmental Formula
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
#' - With an age column holding more than one distinct non-missing value and
#'   `use_age = TRUE`: ~ (var1 + var2 + ...) * age - age
#' - Without age column, with a single age, or with `use_age = FALSE`:
#'   ~ var1 + var2 + ...
#' A single age (for example one time slice) would make every age
#' interaction column zero, so age terms are dropped in that case.
#' The formula removes intercept terms and individual variable terms when
#' interactions are present.
#' @export
build_jsdm_environment_formula <- function(data, use_age = TRUE) {
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

  # Only treat age as active if the column is present, use_age is TRUE, and
  #   age varies. With a single age (one time slice) every age interaction
  #   column is zero, so the terms carry no information (issue #206).
  # Note: keep this a single expression. The returned formula stores this
  #   function's environment, so a new local would change the formula hash
  #   and invalidate every fitted model that uses it.
  is_age_present <-
    "age" %in% vec_names &&
      isTRUE(use_age) &&
      dplyr::n_distinct(data[["age"]], na.rm = TRUE) > 1L

  if (
    isTRUE(is_age_present)
  ) {
    vec_names <- vec_names[!vec_names %in% c("age")]

    assertthat::assert_that(
      length(vec_names) > 0,
      msg = base::paste0(
        "data must have at least one column other than 'age'",
        " when 'age' is present"
      )
    )

    formula_text <-
      paste0(
        " ~ ",
        # Expected for two variables:
        # ~ (bio1 + bio12) * age - age
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

  # A numeric predictor without finite values (for example one constant in
  #   the model input, so scaling divides by a zero standard deviation)
  #   makes model.matrix() drop every row; sjSDM then fails with an opaque
  #   Python ZeroDivisionError. Fail here with the predictor named (#181).
  #   The check is an if() condition so that no local is added.
  if (
    !base::all(
      purrr::map_lgl(
        .x = data[vec_names],
        .f = ~ !base::is.numeric(.x) || base::any(base::is.finite(.x))
      )
    )
  ) {
    cli::cli_abort(
      base::c(
        "Predictor(s) without finite values in the model input.",
        "x" = stringr::str_c(
          "{vec_names[!purrr::map_lgl(data[vec_names], ",
          "~ !is.numeric(.x) || any(is.finite(.x)))]}"
        ),
        "i" = "A predictor that is constant within the input cannot be scaled."
      ),
      class = "jsdm_formula_predictor_not_finite"
    )
  }

  res <- as.formula(formula_text)

  return(res)
}
