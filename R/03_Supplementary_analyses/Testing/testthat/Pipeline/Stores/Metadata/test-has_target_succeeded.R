testthat::test_that(
  "has_target_succeeded() returns TRUE for present target without error",
  {
    data_meta <-
      tibble::tibble(
        name = "model_evaluation_genus",
        error = NA_character_
      )

    res <-
      has_target_succeeded(
        data_meta = data_meta,
        target_name = "model_evaluation_genus"
      )

    testthat::expect_true(res)
  }
)

testthat::test_that(
  "has_target_succeeded() returns FALSE for missing metadata",
  {
    res_null <-
      has_target_succeeded(
        data_meta = NULL,
        target_name = "model_evaluation_genus"
      )

    data_meta_missing_columns <-
      tibble::tibble(target = "model_evaluation_genus")

    res_missing_columns <-
      has_target_succeeded(
        data_meta = data_meta_missing_columns,
        target_name = "model_evaluation_genus"
      )

    testthat::expect_false(res_null)
    testthat::expect_false(res_missing_columns)
  }
)

testthat::test_that(
  "has_target_succeeded() returns FALSE for errored target",
  {
    data_meta <-
      tibble::tibble(
        name = "model_evaluation_genus",
        error = "failed"
      )

    res <-
      has_target_succeeded(
        data_meta = data_meta,
        target_name = "model_evaluation_genus"
      )

    testthat::expect_false(res)
  }
)

testthat::test_that(
  "has_target_succeeded() validates target_name",
  {
    data_meta <-
      tibble::tibble(
        name = "model_evaluation_genus",
        error = NA_character_
      )

    testthat::expect_error(
      has_target_succeeded(
        data_meta = data_meta,
        target_name = character()
      ),
      regexp = "target_name"
    )
  }
)
