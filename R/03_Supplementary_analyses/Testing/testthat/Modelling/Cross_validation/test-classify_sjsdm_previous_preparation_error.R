testthat::test_that(
  "previous expected roots supersede refreshed cache cascades",
  {
    data_previous_errors <-
      tibble::tibble(
        name = "data_vegvault_extracted",
        error = paste(
          "Failed to extract VegVault data for this spatial unit.",
          "The upstream backend returned an empty/opaque error message."
        )
      )
    data_new_errors <-
      tibble::tibble(
        name = "folds_genus",
        error = paste(
          "could not load dependency data_vegvault_extracted of target",
          "folds_genus. there is no package called 'qs'"
        )
      )

    res <-
      classify_sjsdm_previous_preparation_error(
        data_target_errors = data_previous_errors,
        data_new_errors = data_new_errors
      )

    testthat::expect_identical(res[["status"]], "expected_infeasible")
    testthat::expect_identical(res[["reason_code"]], "no_spatial_records")
  }
)

testthat::test_that(
  "new substantive failures supersede previous expected roots",
  {
    data_previous_errors <-
      tibble::tibble(
        name = "flag_available_core_count_validated",
        error = "Not enough cores in this spatial window."
      )
    data_new_errors <-
      tibble::tibble(
        name = "data_vegvault_extracted",
        error = paste(
          "Failed to extract VegVault data for this spatial unit.",
          "Database connection failed."
        )
      )

    res <-
      classify_sjsdm_previous_preparation_error(
        data_target_errors = data_previous_errors,
        data_new_errors = data_new_errors
      )

    testthat::expect_identical(res[["status"]], "unexpected_error")
    testthat::expect_true(base::is.na(res[["reason_code"]]))
  }
)

testthat::test_that(
  "previous preparation classification ignores model errors",
  {
    data_errors <-
      tibble::tibble(
        name = base::c(
          "flag_available_core_count_validated",
          "model_jsdm_genus"
        ),
        error = base::c(
          paste(
            "Not enough cores in this spatial window.",
            "Found 2 core(s); at least 5 required."
          ),
          "Final model did not converge."
        )
      )

    result <-
      classify_sjsdm_previous_preparation_error(data_errors)

    testthat::expect_identical(
      result[["status"]],
      "expected_infeasible"
    )
    testthat::expect_identical(
      result[["reason_code"]],
      "insufficient_cores"
    )
  }
)
