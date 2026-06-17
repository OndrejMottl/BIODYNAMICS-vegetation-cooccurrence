testthat::test_that(
  "count_successful_targets() counts successful pattern matches",
  {
    data_meta <-
      tibble::tibble(
        name = c("model_evaluation_a", "model_evaluation_b", "other"),
        error = c(NA_character_, "err", NA_character_)
      )

    res <-
      count_successful_targets(
        store_path = "store_path",
        target_pattern = "^model_evaluation_",
        data_meta = data_meta
      )

    testthat::expect_identical(
      res,
      1L
    )
  }
)

testthat::test_that(
  "count_successful_targets() returns zero when no matches succeed",
  {
    data_meta <-
      tibble::tibble(
        name = c("target_a", "target_b"),
        error = c("err", NA_character_)
      )

    res <-
      count_successful_targets(
        store_path = "store_path",
        target_pattern = "^target_c$",
        data_meta = data_meta
      )

    testthat::expect_identical(res, 0L)
  }
)

testthat::test_that(
  "count_successful_targets() validates metadata columns",
  {
    data_meta <-
      tibble::tibble(
        target = "x"
      )

    testthat::expect_error(
      count_successful_targets(
        store_path = "store_path",
        target_pattern = "x",
        data_meta = data_meta
      ),
      regexp = "name"
    )
  }
)
