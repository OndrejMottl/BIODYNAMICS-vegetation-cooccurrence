testthat::test_that(
  "check_min_n_cores() errors when data_coords is not a data frame",
  {
    testthat::expect_error(
      check_min_n_cores(
        data_coords = "not a data frame",
        min_n_cores = 2
      ),
      "must be a data frame"
    )

    testthat::expect_error(
      check_min_n_cores(
        data_coords = NULL,
        min_n_cores = 2
      ),
      "must be a data frame"
    )

    testthat::expect_error(
      check_min_n_cores(
        data_coords = list(coord_long = 1, coord_lat = 1),
        min_n_cores = 2
      ),
      "must be a data frame"
    )

    testthat::expect_error(
      check_min_n_cores(
        data_coords = base::matrix(c(1, 2), nrow = 1),
        min_n_cores = 2
      ),
      "must be a data frame"
    )
  }
)

testthat::test_that(
  "check_min_n_cores() errors when min_n_cores is not a numeric scalar",
  {
    data_coords <-
      tibble::tibble(coord_long = 1, coord_lat = 1)

    testthat::expect_error(
      check_min_n_cores(
        data_coords = data_coords,
        min_n_cores = "2"
      ),
      "must be a single numeric value"
    )

    testthat::expect_error(
      check_min_n_cores(
        data_coords = data_coords,
        min_n_cores = NULL
      ),
      "must be a single numeric value"
    )

    testthat::expect_error(
      check_min_n_cores(
        data_coords = data_coords,
        min_n_cores = TRUE
      ),
      "must be a single numeric value"
    )

    testthat::expect_error(
      check_min_n_cores(
        data_coords = data_coords,
        min_n_cores = c(2, 3)
      ),
      "must be a single numeric value"
    )
  }
)

testthat::test_that(
  "check_min_n_cores() errors when min_n_cores is less than 1",
  {
    data_coords <-
      tibble::tibble(coord_long = 1, coord_lat = 1)

    testthat::expect_error(
      check_min_n_cores(
        data_coords = data_coords,
        min_n_cores = 0
      ),
      "greater than or equal to 1"
    )

    testthat::expect_error(
      check_min_n_cores(
        data_coords = data_coords,
        min_n_cores = -5
      ),
      "greater than or equal to 1"
    )
  }
)

testthat::test_that(
  "check_min_n_cores() errors when n cores is below min_n_cores",
  {
    data_coords <-
      tibble::tibble(
        coord_long = c(14.0, 15.0),
        coord_lat = c(50.0, 50.5)
      )

    # 2 cores, threshold 5 → should abort
    testthat::expect_error(
      check_min_n_cores(
        data_coords = data_coords,
        min_n_cores = 5
      ),
      "Not enough cores"
    )

    # exactly 1 core, threshold 2
    data_one_row <-
      tibble::tibble(coord_long = 14.0, coord_lat = 50.0)

    testthat::expect_error(
      check_min_n_cores(
        data_coords = data_one_row,
        min_n_cores = 2
      ),
      "Not enough cores"
    )
  }
)

testthat::test_that(
  "check_min_n_cores() error message names actual and required count",
  {
    data_coords <-
      tibble::tibble(
        coord_long = c(14.0, 15.0),
        coord_lat = c(50.0, 50.5)
      )

    testthat::expect_error(
      check_min_n_cores(
        data_coords = data_coords,
        min_n_cores = 5
      ),
      "2"
    )

    testthat::expect_error(
      check_min_n_cores(
        data_coords = data_coords,
        min_n_cores = 5
      ),
      "5"
    )
  }
)

testthat::test_that(
  "check_min_n_cores() returns TRUE when cores meet threshold",
  {
    data_coords <-
      tibble::tibble(
        coord_long = c(14.0, 15.0, 16.0),
        coord_lat = c(50.0, 50.5, 51.0)
      )

    res <-
      check_min_n_cores(
        data_coords = data_coords,
        min_n_cores = 3
      )

    testthat::expect_true(res)
  }
)

testthat::test_that(
  "check_min_n_cores() returns TRUE when cores exceed threshold",
  {
    data_coords <-
      tibble::tibble(
        coord_long = c(14.0, 15.0, 16.0, 17.0),
        coord_lat = c(50.0, 50.5, 51.0, 51.5)
      )

    res <-
      check_min_n_cores(
        data_coords = data_coords,
        min_n_cores = 2
      )

    testthat::expect_true(res)
  }
)

testthat::test_that(
  "check_min_n_cores() passes when nrow equals min_n_cores exactly",
  {
    data_coords <-
      tibble::tibble(
        coord_long = c(14.0, 15.0),
        coord_lat = c(50.0, 50.5)
      )

    res <-
      check_min_n_cores(
        data_coords = data_coords,
        min_n_cores = 2
      )

    testthat::expect_true(res)
  }
)

testthat::test_that(
  "check_min_n_cores() errors on zero-row data_coords",
  {
    data_empty <-
      tibble::tibble(coord_long = numeric(0), coord_lat = numeric(0))

    testthat::expect_error(
      check_min_n_cores(
        data_coords = data_empty,
        min_n_cores = 1
      ),
      "Not enough cores"
    )
  }
)

testthat::test_that(
  "check_min_n_cores() return value is invisible",
  {
    data_coords <-
      tibble::tibble(
        coord_long = c(14.0, 15.0),
        coord_lat = c(50.0, 50.5)
      )

    res <-
      base::withVisible(
        check_min_n_cores(
          data_coords = data_coords,
          min_n_cores = 2
        )
      )

    testthat::expect_false(res$visible)
    testthat::expect_true(res$value)
  }
)

testthat::test_that(
  "check_min_n_cores() default min_n_cores is 2",
  {
    # 1 core → should fail with default threshold of 2
    data_one_row <-
      tibble::tibble(coord_long = 14.0, coord_lat = 50.0)

    testthat::expect_error(
      check_min_n_cores(data_coords = data_one_row),
      "Not enough cores"
    )

    # 2 cores → should pass with default threshold of 2
    data_two_rows <-
      tibble::tibble(
        coord_long = c(14.0, 15.0),
        coord_lat = c(50.0, 50.5)
      )

    testthat::expect_true(
      check_min_n_cores(data_coords = data_two_rows)
    )
  }
)
