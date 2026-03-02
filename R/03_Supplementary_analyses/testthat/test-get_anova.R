testthat::test_that(
  "get_anova() validates input class - rejects non-sjSDM objects",
  {
    testthat::expect_error(
      get_anova(mod = NULL),
      "The model must be of class 'sjSDM'."
    )

    testthat::expect_error(
      get_anova(mod = list()),
      "The model must be of class 'sjSDM'."
    )

    testthat::expect_error(
      get_anova(mod = 42),
      "The model must be of class 'sjSDM'."
    )

    testthat::expect_error(
      get_anova(mod = "a string"),
      "The model must be of class 'sjSDM'."
    )

    testthat::expect_error(
      get_anova(mod = data.frame(x = 1)),
      "The model must be of class 'sjSDM'."
    )
  }
)

testthat::test_that(
  "get_anova() validates input class - rejects lm/glm objects",
  {
    mod_lm <-
      stats::lm(formula = mpg ~ wt, data = mtcars)

    testthat::expect_error(
      get_anova(mod = mod_lm),
      "The model must be of class 'sjSDM'."
    )

    mod_glm <-
      stats::glm(
        formula = am ~ wt,
        data = mtcars,
        family = stats::binomial()
      )

    testthat::expect_error(
      get_anova(mod = mod_glm),
      "The model must be of class 'sjSDM'."
    )
  }
)

testthat::test_that(
  "get_anova() functional output requires real sjSDM model",
  {
    testthat::skip_if_not_installed("sjSDM")

    set.seed(900723)
    data_dummy <-
      sjSDM::simulate_SDM(env = 3L, species = 10L, sites = 100L)

    data_community <-
      data_dummy$response
    data_abiotic <-
      data_dummy$env_weights
    data_coords <-
      data.frame(
        base::matrix(
          data = stats::rnorm(n = 200, mean = 0, sd = 0.3),
          nrow = 100,
          ncol = 2
        )
      ) # Spatial coordinates


    # Fit model:
    mod <-
      sjSDM::sjSDM(
        Y = data_community,
        env = sjSDM::linear(
          data = data_abiotic,
          formula = ~ X1 + X2 + X3
        ),
        spatial = sjSDM::linear(
          data = data_coords,
          formula = ~ 0 + X1 * X2
        ),
        family = stats::binomial(link = "probit"),
        verbose = FALSE,
        iter = 20L
      ) # Increase iter for real analysis


    anova_res <-
      get_anova(mod = mod)
    testthat::expect_s3_class(anova_res, "sjSDManova")
  }
)
