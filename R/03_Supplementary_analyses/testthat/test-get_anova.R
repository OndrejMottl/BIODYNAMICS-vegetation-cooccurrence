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
    mod_lm <- lm(mpg ~ wt, data = mtcars)

    testthat::expect_error(
      get_anova(mod = mod_lm),
      "The model must be of class 'sjSDM'."
    )

    mod_glm <- glm(
      am ~ wt,
      data = mtcars,
      family = binomial()
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
    skip_if_not_installed("sjSDM")

    data_dummy <-
      sjSDM::simulate_SDM(env = 3L, species = 10L, sites = 100L)

    data_community <-
      data_dummy$response
    data_abiotic <-
      data_dummy$env_weights
    data_coords <-
      data.frame(
        matrix(
          rnorm(200, 0, 0.3), 100, 2
        )
      ) # spatial coordinates


    # fit model:
    mod <-
      sjSDM::sjSDM(
        Y = data_community,
        env = linear(data = data_abiotic, formula = ~ X1 + X2 + X3),
        spatial = linear(data = data_coords, formula = ~ 0 + X1 * X2),
        family = binomial("probit"),
        verbose = FALSE,
        iter = 20
      ) # increase iter for real analysis


    anova_res <- get_anova(mod)
    testthat::expect_s3_class(anova_res, "sjSDManova")
  }
)
