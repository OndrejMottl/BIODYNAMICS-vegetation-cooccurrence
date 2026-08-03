testthat::test_that(
  "filter_community_by_minimum_proportion() validates data parameter type",
  {
    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = "not a data frame"
      ),
      "data_community must be a data frame"
    )

    testthat::expect_error(
      filter_community_by_minimum_proportion(data_community = NULL),
      "data_community must be a data frame"
    )

    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = list(taxon = 0.5, value = 10)
      ),
      "data_community must be a data frame"
    )

    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = matrix(1:4, nrow = 2)
      ),
      "data_community must be a data frame"
    )

    testthat::expect_error(
      filter_community_by_minimum_proportion(data_community = c(0.1, 0.2, 0.3)),
      "data_community must be a data frame"
    )
  }
)

testthat::test_that(
  "minimum-proportion filter rejects non-numeric thresholds",
  {
    data_test <- data.frame(value = c(0.05, 0.15, 0.25))

    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = data_test,
        minimum_proportion = "0.01"
      ),
      "minimum_proportion must be a numeric scalar"
    )

    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = data_test,
        minimum_proportion = NULL
      ),
      "minimum_proportion must be a numeric scalar"
    )

    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = data_test,
        minimum_proportion = TRUE
      ),
      "minimum_proportion must be a numeric scalar"
    )

    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = data_test,
        minimum_proportion = data.frame(x = 0.01)
      ),
      "minimum_proportion must be a numeric scalar"
    )
  }
)

testthat::test_that(
  "minimum-proportion filter rejects non-positive thresholds",
  {
    data_test <- data.frame(value = c(0.05, 0.15, 0.25))

    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = data_test,
        minimum_proportion = 0
      ),
      "minimum_proportion must be greater than 0"
    )

    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = data_test,
        minimum_proportion = -0.1
      ),
      "minimum_proportion must be greater than 0"
    )

    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = data_test,
        minimum_proportion = -1
      ),
      "minimum_proportion must be greater than 0"
    )
  }
)

testthat::test_that(
  "minimum-proportion filter rejects thresholds above one",
  {
    data_test <- data.frame(value = c(0.05, 0.15, 0.25))

    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = data_test,
        minimum_proportion = 1.1
      ),
      "minimum_proportion must be less than or equal to 1"
    )

    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = data_test,
        minimum_proportion = 2
      ),
      "minimum_proportion must be less than or equal to 1"
    )

    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = data_test,
        minimum_proportion = 100
      ),
      "minimum_proportion must be less than or equal to 1"
    )
  }
)

testthat::test_that(
  "minimum-proportion filter accepts valid thresholds",
  {
    data_test <- data.frame(value = c(0.05, 0.15, 0.5, 1))

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.01
    )

    testthat::expect_true(is.data.frame(res))

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.5
    )

    testthat::expect_true(is.data.frame(res))

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 1
    )

    testthat::expect_true(is.data.frame(res))

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.001
    )

    testthat::expect_true(is.data.frame(res))
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() returns data frame",
  {
    data_test <- data.frame(value = c(0.05, 0.15, 0.25))

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.01
    )

    testthat::expect_true(is.data.frame(res))

    testthat::expect_s3_class(res, "data.frame")
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() filters taxa correctly",
  {
    data_test <-
      data.frame(
        value = c(0.005, 0.015, 0.025, 0.050, 0.150)
      )

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.01
    )

    testthat::expect_equal(nrow(res), 4)

    testthat::expect_true(all(dplyr::pull(res, value) >= 0.01))

    testthat::expect_false(any(dplyr::pull(res, value) < 0.01))
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() filters with different thresholds",
  {
    data_test <-
      data.frame(
        value = c(0.005, 0.015, 0.025, 0.050, 0.150, 0.250)
      )

    res_01 <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.01
    )

    testthat::expect_equal(nrow(res_01), 5)

    testthat::expect_true(all(dplyr::pull(res_01, value) >= 0.01))

    res_05 <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.05
    )

    testthat::expect_equal(nrow(res_05), 3)

    testthat::expect_true(all(dplyr::pull(res_05, value) >= 0.05))

    res_10 <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.10
    )

    testthat::expect_equal(nrow(res_10), 2)

    testthat::expect_true(all(dplyr::pull(res_10, value) >= 0.10))
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() uses default minimum_proportion",
  {
    data_test <-
      data.frame(
        value = c(0.005, 0.015, 0.025, 0.050)
      )

    res <- filter_community_by_minimum_proportion(data_community = data_test)

    testthat::expect_equal(nrow(res), 3)

    testthat::expect_true(all(dplyr::pull(res, value) >= 0.01))
  }
)

testthat::test_that(
  "minimum-proportion filter preserves columns and structure",
  {
    data_test <-
      data.frame(
        value = c(0.05, 0.15, 0.25),
        species = c("sp1", "sp2", "sp3"),
        count = c(5, 15, 25)
      )

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.01
    )

    testthat::expect_equal(ncol(res), ncol(data_test))

    testthat::expect_equal(colnames(res), colnames(data_test))

    testthat::expect_true("species" %in% colnames(res))

    testthat::expect_true("count" %in% colnames(res))
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() errors when no taxa meet threshold",
  {
    data_test <-
      data.frame(
        value = c(0.005, 0.008, 0.009)
      )

    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = data_test,
        minimum_proportion = 0.01
      ),
      "No taxa found in data"
    )

    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = data_test,
        minimum_proportion = 0.01
      ),
      "minimum_proportion is too high"
    )
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() errors when all taxa filtered out",
  {
    data_test <-
      data.frame(
        value = c(0.05, 0.15, 0.25)
      )

    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = data_test,
        minimum_proportion = 0.5
      ),
      "No taxa found in data"
    )
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() handles exact threshold values",
  {
    data_test <-
      data.frame(
        value = c(0.01, 0.02, 0.03)
      )

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.01
    )

    testthat::expect_equal(nrow(res), 3)

    testthat::expect_true(all(dplyr::pull(res, value) >= 0.01))

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.02
    )

    testthat::expect_equal(nrow(res), 2)

    testthat::expect_true(min(dplyr::pull(res, value)) == 0.02)
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() handles single row data",
  {
    data_test <- data.frame(value = 0.05)

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.01
    )

    testthat::expect_equal(nrow(res), 1)

    testthat::expect_equal(dplyr::pull(res, value), 0.05)
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() handles single row below threshold",
  {
    data_test <- data.frame(value = 0.005)

    testthat::expect_error(
      filter_community_by_minimum_proportion(
        data_community = data_test,
        minimum_proportion = 0.01
      ),
      "No taxa found in data"
    )
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() handles larger datasets",
  {
    set.seed(900723)

    data_test <-
      data.frame(
        value = runif(1000, min = 0, max = 1)
      )

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.1
    )

    testthat::expect_true(is.data.frame(res))

    testthat::expect_true(all(dplyr::pull(res, value) >= 0.1))

    testthat::expect_true(nrow(res) < nrow(data_test))

    testthat::expect_equal(
      nrow(res),
      sum(dplyr::pull(data_test, value) >= 0.1)
    )
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() preserves row order",
  {
    data_test <-
      data.frame(
        value = c(0.25, 0.05, 0.15, 0.02, 0.35),
        id = 1:5
      )

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.03
    )

    expected_ids <- c(1, 2, 3, 5)

    testthat::expect_equal(dplyr::pull(res, id), expected_ids)

    testthat::expect_equal(dplyr::pull(res, value)[[1]], 0.25)

    testthat::expect_equal(dplyr::pull(res, value)[[2]], 0.05)
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() handles tibble input",
  {
    data_test <-
      tibble::tibble(
        value = c(0.05, 0.15, 0.25)
      )

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.01
    )

    testthat::expect_true(is.data.frame(res))

    testthat::expect_equal(nrow(res), 3)
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() handles NA values in value column",
  {
    data_test <-
      data.frame(
        value = c(0.05, NA, 0.15, 0.25)
      )

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.01
    )

    testthat::expect_true(is.data.frame(res))

    testthat::expect_false(any(is.na(dplyr::pull(res, value))))
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() handles special numeric values",
  {
    data_test <-
      data.frame(
        value = c(0.05, Inf, 0.15, -Inf, 0.25)
      )

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.01
    )

    testthat::expect_true(is.data.frame(res))

    testthat::expect_true(Inf %in% dplyr::pull(res, value))
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() handles boundary value 1",
  {
    data_test <-
      data.frame(
        value = c(0.5, 0.8, 1.0)
      )

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 1
    )

    testthat::expect_equal(nrow(res), 1)

    testthat::expect_equal(dplyr::pull(res, value), 1.0)
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() handles very small threshold",
  {
    data_test <-
      data.frame(
        value = c(0.00005, 0.00015, 0.00025)
      )

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.0001
    )

    testthat::expect_equal(nrow(res), 2)

    testthat::expect_true(all(dplyr::pull(res, value) >= 0.0001))
  }
)

testthat::test_that(
  "minimum-proportion filter handles signed values",
  {
    data_test <-
      data.frame(
        value = c(-0.05, 0.05, 0.15, 0.25)
      )

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.01
    )

    testthat::expect_equal(nrow(res), 3)

    testthat::expect_false(any(dplyr::pull(res, value) < 0))
  }
)

testthat::test_that(
  "filter_community_by_minimum_proportion() handles duplicate value values",
  {
    data_test <-
      data.frame(
        value = c(0.05, 0.05, 0.15, 0.15, 0.25),
        id = 1:5
      )

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = 0.1
    )

    testthat::expect_equal(nrow(res), 3)

    testthat::expect_true(all(dplyr::pull(res, value) >= 0.1))
  }
)

testthat::test_that(
  "minimum-proportion filter accepts length-one vectors",
  {
    data_test <-
      data.frame(
        value = c(0.05, 0.15, 0.25)
      )

    res <- filter_community_by_minimum_proportion(
      data_community = data_test,
      minimum_proportion = c(0.01)
    )

    testthat::expect_true(is.data.frame(res))

    testthat::expect_equal(nrow(res), 3)
  }
)
