testthat::test_that(
  "decision loading enforces the canonical header",
  {
    path_decisions <-
      base::tempfile(fileext = ".csv")

    readr::write_csv(
      tibble::tibble(wrong_column = "value"),
      path_decisions
    )

    testthat::expect_error(
      load_trait_review_decisions(
        path_trait_review_decisions = path_decisions
      ),
      regexp = "canonical columns"
    )
  }
)

testthat::test_that(
  "decision loading returns typed empty decisions",
  {
    path_decisions <-
      here::here(
        "Data/Input/Trait_corrections/",
        "trait_review_decisions_raw.csv"
      )

    data_decisions <-
      load_trait_review_decisions(
        path_trait_review_decisions = path_decisions
      )

    testthat::expect_s3_class(data_decisions, "tbl_df")
    testthat::expect_equal(base::nrow(data_decisions), 0L)
    testthat::expect_type(
      dplyr::pull(data_decisions, dataset_id),
      "integer"
    )
    testthat::expect_type(
      dplyr::pull(data_decisions, value_lower),
      "double"
    )
  }
)
