testthat::test_that(
  "apply_scale_attributes() applies training transformations",
  {
    data_predictors <-
      base::data.frame(
        age = base::c(300, 500),
        bio = base::c(12, 16)
      )

    base::rownames(data_predictors) <-
      base::c("a__300", "b__500")

    scale_attributes <-
      base::list(
        age = base::list("scaled:center" = 100),
        bio = base::list(
          "scaled:center" = 10,
          "scaled:scale" = 2
        )
      )

    res <-
      apply_scale_attributes(
        data_predictors = data_predictors,
        scale_attributes = scale_attributes
      )

    testthat::expect_equal(
      base::rownames(res),
      base::c("a__300", "b__500")
    )
    testthat::expect_equal(base::colnames(res), base::c("age", "bio"))
    testthat::expect_equal(res[["age"]], base::c(200, 400))
    testthat::expect_equal(res[["bio"]], base::c(1, 3))
  }
)

testthat::test_that(
  "apply_scale_attributes() validates scaled columns",
  {
    data_predictors <-
      base::data.frame(age = base::c(1, 2))

    scale_attributes <-
      base::list(
        age = base::list("scaled:center" = 0),
        bio = base::list("scaled:center" = 0)
      )

    testthat::expect_error(
      apply_scale_attributes(
        data_predictors = data_predictors,
        scale_attributes = scale_attributes
      ),
      "contain every scaled predictor"
    )
  }
)

testthat::test_that(
  "apply_scale_attributes() validates transformation values",
  {
    data_predictors <-
      base::data.frame(age = base::c(1, 2))

    scale_attributes <-
      base::list(
        age = base::list(
          "scaled:center" = 0,
          "scaled:scale" = 0
        )
      )

    testthat::expect_error(
      apply_scale_attributes(
        data_predictors = data_predictors,
        scale_attributes = scale_attributes
      ),
      "non-zero scale"
    )
  }
)
