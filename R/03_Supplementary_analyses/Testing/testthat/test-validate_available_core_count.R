testthat::test_that(
  "validate_available_core_count() errors when data_coords is not a data frame",
  {
    testthat::expect_error(
      validate_available_core_count(
        data_coords = "not a data frame",
        minimum_core_count = 2
      ),
      "must be a data frame"
    )

    testthat::expect_error(
      validate_available_core_count(
        data_coords = NULL,
        minimum_core_count = 2
      ),
      "must be a data frame"
    )

    testthat::expect_error(
      validate_available_core_count(
        data_coords = list(coord_long = 1, coord_lat = 1),
        minimum_core_count = 2
      ),
      "must be a data frame"
    )

    testthat::expect_error(
      validate_available_core_count(
        data_coords = base::matrix(c(1, 2), nrow = 1),
        minimum_core_count = 2
      ),
      "must be a data frame"
    )
  }
)

testthat::test_that(
  "available-core validation rejects non-numeric thresholds",
  {
    data_coords <-
      tibble::tibble(coord_long = 1, coord_lat = 1)

    testthat::expect_error(
      validate_available_core_count(
        data_coords = data_coords,
        minimum_core_count = "2"
      ),
      "minimum_core_count must be a numeric scalar"
    )

    testthat::expect_error(
      validate_available_core_count(
        data_coords = data_coords,
        minimum_core_count = NULL
      ),
      "minimum_core_count must be a numeric scalar"
    )

    testthat::expect_error(
      validate_available_core_count(
        data_coords = data_coords,
        minimum_core_count = TRUE
      ),
      "minimum_core_count must be a numeric scalar"
    )

    testthat::expect_error(
      validate_available_core_count(
        data_coords = data_coords,
        minimum_core_count = c(2, 3)
      ),
      "minimum_core_count must be a numeric scalar"
    )
  }
)

testthat::test_that(
  "available-core validation rejects thresholds below one",
  {
    data_coords <-
      tibble::tibble(coord_long = 1, coord_lat = 1)

    testthat::expect_error(
      validate_available_core_count(
        data_coords = data_coords,
        minimum_core_count = 0
      ),
      "greater than or equal to 1"
    )

    testthat::expect_error(
      validate_available_core_count(
        data_coords = data_coords,
        minimum_core_count = -5
      ),
      "greater than or equal to 1"
    )
  }
)

testthat::test_that(
  "available-core validation rejects insufficient cores",
  {
    data_coords <-
      tibble::tibble(
        coord_long = c(14.0, 15.0),
        coord_lat = c(50.0, 50.5)
      )

    # 2 cores, threshold 5 -> should abort
    testthat::expect_error(
      validate_available_core_count(
        data_coords = data_coords,
        minimum_core_count = 5
      ),
      "Not enough cores"
    )

    # exactly 1 core, threshold 2
    data_one_row <-
      tibble::tibble(coord_long = 14.0, coord_lat = 50.0)

    testthat::expect_error(
      validate_available_core_count(
        data_coords = data_one_row,
        minimum_core_count = 2
      ),
      "Not enough cores"
    )
  }
)

testthat::test_that(
  "available-core validation reports actual and required counts",
  {
    data_coords <-
      tibble::tibble(
        coord_long = c(14.0, 15.0),
        coord_lat = c(50.0, 50.5)
      )

    testthat::expect_error(
      validate_available_core_count(
        data_coords = data_coords,
        minimum_core_count = 5
      ),
      "2"
    )

    testthat::expect_error(
      validate_available_core_count(
        data_coords = data_coords,
        minimum_core_count = 5
      ),
      "5"
    )
  }
)

testthat::test_that(
  "validate_available_core_count() returns TRUE when cores meet threshold",
  {
    data_coords <-
      tibble::tibble(
        coord_long = c(14.0, 15.0, 16.0),
        coord_lat = c(50.0, 50.5, 51.0)
      )

    res <-
      validate_available_core_count(
        data_coords = data_coords,
        minimum_core_count = 3
      )

    testthat::expect_true(res)
  }
)

testthat::test_that(
  "validate_available_core_count() returns TRUE when cores exceed threshold",
  {
    data_coords <-
      tibble::tibble(
        coord_long = c(14.0, 15.0, 16.0, 17.0),
        coord_lat = c(50.0, 50.5, 51.0, 51.5)
      )

    res <-
      validate_available_core_count(
        data_coords = data_coords,
        minimum_core_count = 2
      )

    testthat::expect_true(res)
  }
)

testthat::test_that(
  "available-core validation accepts the threshold count",
  {
    data_coords <-
      tibble::tibble(
        coord_long = c(14.0, 15.0),
        coord_lat = c(50.0, 50.5)
      )

    res <-
      validate_available_core_count(
        data_coords = data_coords,
        minimum_core_count = 2
      )

    testthat::expect_true(res)
  }
)

testthat::test_that(
  "validate_available_core_count() errors on zero-row data_coords",
  {
    data_empty <-
      tibble::tibble(coord_long = numeric(0), coord_lat = numeric(0))

    testthat::expect_error(
      validate_available_core_count(
        data_coords = data_empty,
        minimum_core_count = 1
      ),
      "Not enough cores"
    )
  }
)

testthat::test_that(
  "validate_available_core_count() return value is invisible",
  {
    data_coords <-
      tibble::tibble(
        coord_long = c(14.0, 15.0),
        coord_lat = c(50.0, 50.5)
      )

    res <-
      base::withVisible(
        validate_available_core_count(
          data_coords = data_coords,
          minimum_core_count = 2
        )
      )

    testthat::expect_false(res$visible)
    testthat::expect_true(res$value)
  }
)

testthat::test_that(
  "validate_available_core_count() default minimum_core_count is 2",
  {
    # 1 core -> should fail with default threshold of 2
    data_one_row <-
      tibble::tibble(coord_long = 14.0, coord_lat = 50.0)

    testthat::expect_error(
      validate_available_core_count(data_coords = data_one_row),
      "Not enough cores"
    )

    # 2 cores -> should pass with default threshold of 2
    data_two_rows <-
      tibble::tibble(
        coord_long = c(14.0, 15.0),
        coord_lat = c(50.0, 50.5)
      )

    testthat::expect_true(
      validate_available_core_count(data_coords = data_two_rows)
    )
  }
)
