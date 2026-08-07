testthat::test_that(
  "validate_sample_count() errors when data_sample_ids is not a data frame",
  {
    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = "not a data frame",
        minimum_sample_count = 1L
      )
    )

    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = NULL,
        minimum_sample_count = 1L
      )
    )

    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = list(
          dataset_name = "site_a",
          age = 100
        ),
        minimum_sample_count = 1L
      )
    )

    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = base::matrix(
          c("site_a", "100"),
          nrow = 1
        ),
        minimum_sample_count = 1L
      )
    )
  }
)

testthat::test_that(
  "validate_sample_count() errors when required columns are missing",
  {
    data_no_age <-
      tibble::tibble(
        dataset_name = c("site_a", "site_b"),
        value = c(1, 2)
      )

    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = data_no_age,
        minimum_sample_count = 1L
      )
    )

    data_no_name <-
      tibble::tibble(
        age = c(100, 200),
        value = c(1, 2)
      )

    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = data_no_name,
        minimum_sample_count = 1L
      )
    )
  }
)

testthat::test_that(
  "validate_sample_count() errors when minimum_sample_count is not numeric",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_a"),
        age = c(100)
      )

    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = data_ids,
        minimum_sample_count = "1"
      )
    )

    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = data_ids,
        minimum_sample_count = NULL
      )
    )

    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = data_ids,
        minimum_sample_count = TRUE
      )
    )

    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = data_ids,
        minimum_sample_count = c(1L, 2L)
      )
    )
  }
)

testthat::test_that(
  "validate_sample_count() errors when minimum_sample_count is not positive",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_a"),
        age = c(100)
      )

    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = data_ids,
        minimum_sample_count = 0L
      )
    )

    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = data_ids,
        minimum_sample_count = -5L
      )
    )
  }
)

testthat::test_that(
  "validate_sample_count() returns input unchanged when sufficient rows",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_a", "site_b", "site_c"),
        age = c(100, 200, 300)
      )

    res <-
      validate_sample_count(
        data_sample_ids = data_ids,
        minimum_sample_count = 2L
      )

    testthat::expect_identical(res, data_ids)
  }
)

testthat::test_that(
  "validate_sample_count() returns a data frame",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_a", "site_b"),
        age = c(100, 200)
      )

    res <-
      validate_sample_count(
        data_sample_ids = data_ids,
        minimum_sample_count = 1L
      )

    testthat::expect_true(
      base::is.data.frame(res)
    )
  }
)

testthat::test_that(
  "validate_sample_count() preserves all rows and columns",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_a", "site_b"),
        age = c(100, 200)
      )

    res <-
      validate_sample_count(
        data_sample_ids = data_ids,
        minimum_sample_count = 1L
      )

    testthat::expect_equal(
      base::nrow(res),
      base::nrow(data_ids)
    )

    testthat::expect_equal(
      base::ncol(res),
      base::ncol(data_ids)
    )

    testthat::expect_equal(
      base::colnames(res),
      base::colnames(data_ids)
    )
  }
)

testthat::test_that(
  "validate_sample_count() errors when nrow < minimum_sample_count",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_a", "site_b"),
        age = c(100, 200)
      )

    # 2 rows, threshold 5 -> should abort
    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = data_ids,
        minimum_sample_count = 5L
      )
    )

    # 1 row, threshold 2 -> should abort
    data_one_row <-
      tibble::tibble(
        dataset_name = "site_a",
        age = 100
      )

    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = data_one_row,
        minimum_sample_count = 2L
      )
    )
  }
)

testthat::test_that(
  "validate_sample_count() error message mentions actual count and threshold",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_a", "site_b"),
        age = c(100, 200)
      )

    # 2 rows, threshold 5: message should report "2" (actual count)
    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = data_ids,
        minimum_sample_count = 5L
      ),
      regexp = "2"
    )

    # 2 rows, threshold 5: message should also report "5" (threshold)
    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = data_ids,
        minimum_sample_count = 5L
      ),
      regexp = "5"
    )
  }
)

testthat::test_that(
  "sample-count validation accepts the threshold count",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_a", "site_b", "site_c"),
        age = c(100, 200, 300)
      )

    res <-
      validate_sample_count(
        data_sample_ids = data_ids,
        minimum_sample_count = 3L
      )

    testthat::expect_identical(res, data_ids)
  }
)

testthat::test_that(
  "validate_sample_count() errors with 0 rows when minimum_sample_count > 0",
  {
    data_zero_rows <-
      tibble::tibble(
        dataset_name = base::character(0),
        age = base::numeric(0)
      )

    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = data_zero_rows,
        minimum_sample_count = 1L
      )
    )
  }
)

testthat::test_that(
  "sample-count validation rejects an empty frame by default",
  {
    data_zero_rows <-
      tibble::tibble(
        dataset_name = base::character(0),
        age = base::numeric(0)
      )

    testthat::expect_error(
      validate_sample_count(
        data_sample_ids = data_zero_rows
      )
    )
  }
)

testthat::test_that(
  "validate_sample_count() default minimum_sample_count = 1 passes with 1 row",
  {
    data_one_row <-
      tibble::tibble(
        dataset_name = "site_a",
        age = 100
      )

    res <-
      validate_sample_count(
        data_sample_ids = data_one_row
      )

    testthat::expect_identical(res, data_one_row)
  }
)
