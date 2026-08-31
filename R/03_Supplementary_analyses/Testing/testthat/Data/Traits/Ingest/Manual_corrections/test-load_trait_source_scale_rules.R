testthat::test_that(
  "source scale rule loading enforces the canonical header",
  {
    path_rules <-
      base::tempfile(fileext = ".csv")
    readr::write_csv(
      tibble::tibble(wrong_column = "value"),
      path_rules
    )

    testthat::expect_error(
      load_trait_source_scale_rules(path_rules),
      regexp = "canonical columns"
    )
  }
)

testthat::test_that(
  "source scale rule loading returns canonical types",
  {
    path_rules <-
      base::tempfile(fileext = ".csv")
    readr::write_csv(
      tibble::tibble(
        source_scale_rule_id = character(),
        vegvault_version = character(),
        data_source_id = integer(),
        expected_data_source_desc = character(),
        trait_domain_name = character(),
        trait_name = character(),
        scale_factor = double(),
        expected_match_count = integer(),
        rationale = character(),
        evidence_reference = character(),
        review_status = character(),
        reviewer = character(),
        reviewed_at = character()
      ),
      path_rules
    )

    data_rules <-
      load_trait_source_scale_rules(path_rules)

    testthat::expect_s3_class(data_rules, "tbl_df")
    testthat::expect_type(data_rules[["data_source_id"]], "integer")
    testthat::expect_type(data_rules[["scale_factor"]], "double")
  }
)
