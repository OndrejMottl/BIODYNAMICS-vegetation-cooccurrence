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
      base::tempfile(fileext = ".csv")
    readr::write_csv(
      tibble::tibble(
        decision_id = character(),
        candidate_id = character(),
        taxon_name = character(),
        trait_domain_name = character(),
        trait_name = character(),
        dataset_id = integer(),
        value_lower = double(),
        value_lower_inclusive = logical(),
        value_upper = double(),
        value_upper_inclusive = logical(),
        action = character(),
        scale_factor = double(),
        rationale = character(),
        evidence_reference = character(),
        source_reference = character(),
        review_status = character(),
        reviewer = character(),
        reviewed_at = character()
      ),
      path_decisions
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
