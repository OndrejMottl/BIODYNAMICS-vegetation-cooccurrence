testthat::test_that(
  "apply_decomposition_scale_attributes() scales held-out rows",
  {
    data_predictors <-
      base::data.frame(
        age = c(300, 500),
        bio = c(12, 16)
      )

    base::rownames(data_predictors) <- c("a__300", "b__500")

    scale_attributes <-
      base::list(
        age = base::list("scaled:center" = 100),
        bio = base::list(
          "scaled:center" = 10,
          "scaled:scale" = 2
        )
      )

    res <-
      apply_decomposition_scale_attributes(
        data_predictors = data_predictors,
        scale_attributes = scale_attributes
      )

    testthat::expect_equal(base::rownames(res), c("a__300", "b__500"))
    testthat::expect_equal(res[["age"]], c(200, 400))
    testthat::expect_equal(res[["bio"]], c(1, 3))
  }
)

testthat::test_that(
  "apply_decomposition_scale_attributes() validates columns",
  {
    data_predictors <-
      base::data.frame(age = c(1, 2))

    scale_attributes <-
      base::list(
        age = base::list("scaled:center" = 0),
        bio = base::list("scaled:center" = 0)
      )

    testthat::expect_error(
      apply_decomposition_scale_attributes(
        data_predictors = data_predictors,
        scale_attributes = scale_attributes
      ),
      "all scaled columns"
    )
  }
)
