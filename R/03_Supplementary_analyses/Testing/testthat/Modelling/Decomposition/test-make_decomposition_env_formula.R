testthat::test_that(
  "make_decomposition_env_formula() excludes age in none mode",
  {
    data_predictors <-
      base::data.frame(
        age = c(0, 1),
        bio = c(-1, 1)
      )

    res <-
      make_decomposition_env_formula(
        data = data_predictors,
        age_formula_mode = "none"
      )

    testthat::expect_equal(
      base::deparse(res),
      "~bio"
    )
  }
)

testthat::test_that(
  "make_decomposition_env_formula() includes age as main effect",
  {
    data_predictors <-
      base::data.frame(
        age = c(0, 1),
        bio = c(-1, 1)
      )

    res <-
      make_decomposition_env_formula(
        data = data_predictors,
        age_formula_mode = "main_effect"
      )

    testthat::expect_equal(
      base::deparse(res),
      "~age + bio"
    )
  }
)

testthat::test_that(
  "make_decomposition_env_formula() preserves interaction mode",
  {
    data_predictors <-
      base::data.frame(
        age = c(0, 1),
        bio = c(-1, 1)
      )

    res <-
      make_decomposition_env_formula(
        data = data_predictors,
        age_formula_mode = "interaction"
      )

    testthat::expect_equal(
      base::deparse(res),
      "~(bio) * age - age"
    )
  }
)
