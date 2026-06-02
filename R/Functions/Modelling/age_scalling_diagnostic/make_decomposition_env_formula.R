#' @title Make Decomposition Environmental Formula
#' @description
#' Creates environmental formulas for decomposition diagnostics with
#' explicit control over how `age` enters the model.
#' @param data
#' Data frame of scaled abiotic predictors.
#' @param age_formula_mode
#' Single character string. One of `"none"`, `"main_effect"`, or
#' `"interaction"`.
#' @return
#' Formula object suitable for `fit_jsdm_model()`.
#' @export
make_decomposition_env_formula <- function(
    data = NULL,
    age_formula_mode = c("none", "main_effect", "interaction")) {
  assertthat::assert_that(
    base::is.data.frame(data),
    msg = "`data` must be a data frame."
  )

  age_formula_mode <-
    base::match.arg(age_formula_mode)

  if (
    age_formula_mode == "none"
  ) {
    return(
      make_env_formula(
        data = data,
        use_age = FALSE
      )
    )
  }

  if (
    age_formula_mode == "interaction"
  ) {
    return(
      make_env_formula(
        data = data,
        use_age = TRUE
      )
    )
  }

  vec_names <-
    base::colnames(data)

  assertthat::assert_that(
    "age" %in% vec_names,
    msg = "`data` must contain `age` when age_formula_mode is main_effect."
  )

  vec_formula_names <-
    c(
      "age",
      vec_names[!vec_names %in% "age"]
    )

  assertthat::assert_that(
    base::length(vec_formula_names) > 1L,
    msg = "`data` must contain at least one predictor besides `age`."
  )

  formula_text <-
    stringr::str_glue(
      " ~ {stringr::str_c(vec_formula_names, collapse = ' + ')}"
    )

  res <-
    stats::as.formula(formula_text)

  return(res)
}
