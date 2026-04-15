testthat::test_that(
  "check_data_sample_ids_n() errors when data_sample_ids is not a data frame",
  {
    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = "not a data frame",
        min_n_samples = 1L
      )
    )

    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = NULL,
        min_n_samples = 1L
      )
    )

    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = list(
          dataset_name = "site_a",
          age = 100
        ),
        min_n_samples = 1L
      )
    )

    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = base::matrix(
          c("site_a", "100"),
          nrow = 1
        ),
        min_n_samples = 1L
      )
    )
  }
)

testthat::test_that(
  "check_data_sample_ids_n() errors when required columns are missing",
  {
    data_no_age <-
      tibble::tibble(
        dataset_name = c("site_a", "site_b"),
        value = c(1, 2)
      )

    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = data_no_age,
        min_n_samples = 1L
      )
    )

    data_no_name <-
      tibble::tibble(
        age = c(100, 200),
        value = c(1, 2)
      )

    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = data_no_name,
        min_n_samples = 1L
      )
    )
  }
)

testthat::test_that(
  "check_data_sample_ids_n() errors when min_n_samples is not numeric",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_a"),
        age = c(100)
      )

    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = data_ids,
        min_n_samples = "1"
      )
    )

    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = data_ids,
        min_n_samples = NULL
      )
    )

    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = data_ids,
        min_n_samples = TRUE
      )
    )

    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = data_ids,
        min_n_samples = c(1L, 2L)
      )
    )
  }
)

testthat::test_that(
  "check_data_sample_ids_n() errors when min_n_samples is not positive",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_a"),
        age = c(100)
      )

    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = data_ids,
        min_n_samples = 0L
      )
    )

    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = data_ids,
        min_n_samples = -5L
      )
    )
  }
)

testthat::test_that(
  "check_data_sample_ids_n() returns input unchanged when sufficient rows",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_a", "site_b", "site_c"),
        age = c(100, 200, 300)
      )

    res <-
      check_data_sample_ids_n(
        data_sample_ids = data_ids,
        min_n_samples = 2L
      )

    testthat::expect_identical(res, data_ids)
  }
)

testthat::test_that(
  "check_data_sample_ids_n() returns a data frame",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_a", "site_b"),
        age = c(100, 200)
      )

    res <-
      check_data_sample_ids_n(
        data_sample_ids = data_ids,
        min_n_samples = 1L
      )

    testthat::expect_true(
      base::is.data.frame(res)
    )
  }
)

testthat::test_that(
  "check_data_sample_ids_n() preserves all rows and columns",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_a", "site_b"),
        age = c(100, 200)
      )

    res <-
      check_data_sample_ids_n(
        data_sample_ids = data_ids,
        min_n_samples = 1L
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
  "check_data_sample_ids_n() errors when nrow < min_n_samples",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_a", "site_b"),
        age = c(100, 200)
      )

    # 2 rows, threshold 5 -> should abort
    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = data_ids,
        min_n_samples = 5L
      )
    )

    # 1 row, threshold 2 -> should abort
    data_one_row <-
      tibble::tibble(
        dataset_name = "site_a",
        age = 100
      )

    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = data_one_row,
        min_n_samples = 2L
      )
    )
  }
)

testthat::test_that(
  "check_data_sample_ids_n() error message mentions actual count and threshold",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_a", "site_b"),
        age = c(100, 200)
      )

    # 2 rows, threshold 5: message should report "2" (actual count)
    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = data_ids,
        min_n_samples = 5L
      ),
      regexp = "2"
    )

    # 2 rows, threshold 5: message should also report "5" (threshold)
    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = data_ids,
        min_n_samples = 5L
      ),
      regexp = "5"
    )
  }
)

testthat::test_that(
  "check_data_sample_ids_n() passes when nrow equals min_n_samples exactly",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_a", "site_b", "site_c"),
        age = c(100, 200, 300)
      )

    res <-
      check_data_sample_ids_n(
        data_sample_ids = data_ids,
        min_n_samples = 3L
      )

    testthat::expect_identical(res, data_ids)
  }
)

testthat::test_that(
  "check_data_sample_ids_n() errors with 0 rows when min_n_samples > 0",
  {
    data_zero_rows <-
      tibble::tibble(
        dataset_name = base::character(0),
        age = base::numeric(0)
      )

    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = data_zero_rows,
        min_n_samples = 1L
      )
    )
  }
)

testthat::test_that(
  "check_data_sample_ids_n() default min_n_samples = 1 rejects empty frame",
  {
    data_zero_rows <-
      tibble::tibble(
        dataset_name = base::character(0),
        age = base::numeric(0)
      )

    testthat::expect_error(
      check_data_sample_ids_n(
        data_sample_ids = data_zero_rows
      )
    )
  }
)

testthat::test_that(
  "check_data_sample_ids_n() default min_n_samples = 1 passes with 1 row",
  {
    data_one_row <-
      tibble::tibble(
        dataset_name = "site_a",
        age = 100
      )

    res <-
      check_data_sample_ids_n(
        data_sample_ids = data_one_row
      )

    testthat::expect_identical(res, data_one_row)
  }
)
