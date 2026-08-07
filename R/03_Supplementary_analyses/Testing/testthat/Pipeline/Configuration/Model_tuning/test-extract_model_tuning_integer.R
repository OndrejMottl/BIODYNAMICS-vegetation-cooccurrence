testthat::test_that(
  "extract_model_tuning_integer() distinguishes required and optional values",
  {
    data_tuning_row <-
      tibble::tibble(
        n_iter = 100.8,
        n_step_size = NA_real_
      )

    testthat::expect_identical(
      extract_model_tuning_integer(
        data_tuning_row = data_tuning_row,
        column_name = "n_iter",
        scale_id = "europe"
      ),
      100L
    )

    testthat::expect_null(
      extract_model_tuning_integer(
        data_tuning_row = data_tuning_row,
        column_name = "n_step_size",
        scale_id = "europe",
        required = FALSE
      )
    )

    testthat::expect_error(
      extract_model_tuning_integer(
        data_tuning_row = data_tuning_row,
        column_name = "n_step_size",
        scale_id = "europe"
      ),
      "must not be missing"
    )
  }
)
