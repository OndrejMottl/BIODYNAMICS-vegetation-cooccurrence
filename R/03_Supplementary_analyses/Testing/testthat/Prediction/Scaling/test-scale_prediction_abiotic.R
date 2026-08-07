testthat::test_that(
  "scale_prediction_abiotic() applies training scale attributes",
  {
    data_climate <-
      tibble::tibble(
        age = c(0, 1000),
        bio1 = c(4, 8),
        bio12 = c(100, 150),
        unused = c(1, 2)
      )

    list_scale_attributes <-
      base::list(
        age = base::list(
          "scaled:center" = 500,
          "scaled:scale" = 500
        ),
        bio1 = base::list(
          "scaled:center" = 6,
          "scaled:scale" = 2
        ),
        bio12 = base::list(
          "scaled:center" = 100,
          "scaled:scale" = 50
        )
      )

    res <-
      scale_prediction_abiotic(
        data_climate = data_climate,
        scale_attributes = list_scale_attributes
      )

    testthat::expect_equal(base::colnames(res), c("age", "bio1", "bio12"))
    testthat::expect_equal(dplyr::pull(res, age), c(-1, 1))
    testthat::expect_equal(dplyr::pull(res, bio1), c(-1, 1))
    testthat::expect_equal(dplyr::pull(res, bio12), c(0, 1))
  }
)

testthat::test_that(
  "scale_prediction_abiotic() treats missing scale as one",
  {
    data_climate <-
      tibble::tibble(age = 0, bio1 = 8)

    list_scale_attributes <-
      base::list(
        age = base::list("scaled:center" = 0),
        bio1 = base::list(
          "scaled:center" = 6,
          "scaled:scale" = 0
        )
      )

    res <-
      scale_prediction_abiotic(
        data_climate = data_climate,
        scale_attributes = list_scale_attributes
      )

    testthat::expect_equal(dplyr::pull(res, bio1), 2)
  }
)
