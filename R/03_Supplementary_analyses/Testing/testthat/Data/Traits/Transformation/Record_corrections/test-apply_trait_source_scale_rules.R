testthat::test_that(
  "source scaling changes all and only selected source records",
  {
    data_records <-
      tibble::tibble(
        dataset_id = base::c(1L, 2L, 3L),
        sample_id = base::c(11L, 12L, 13L),
        trait_id = base::c(21L, 22L, 23L),
        taxon_id = base::c(31L, 32L, 33L),
        taxon_name = base::c("A", "B", "C"),
        data_source_id = base::c(294L, 294L, 500L),
        trait_domain_name = "Leaf Area",
        trait_name = "leaf area",
        trait_value = base::c(1, 2, 3)
      )
    data_rules <-
      tibble::tibble(
        source_scale_rule_id = "rule-294",
        data_source_id = 294L,
        trait_domain_name = "Leaf Area",
        trait_name = "",
        scale_factor = 100,
        review_status = "approved"
      )

    list_result <-
      apply_trait_source_scale_rules(data_records, data_rules)
    data_corrected <-
      list_result[["data_trait_records_source_scaled"]]
    data_record_audit <-
      list_result[["data_source_scale_record_audit"]]

    testthat::expect_equal(
      data_corrected[["trait_value"]],
      base::c(100, 200, 3)
    )
    testthat::expect_equal(base::nrow(data_record_audit), 2L)
    testthat::expect_equal(
      data_record_audit[["trait_value_before"]],
      base::c(1, 2)
    )
    testthat::expect_equal(
      data_record_audit[["trait_value_after"]],
      base::c(100, 200)
    )
  }
)

testthat::test_that(
  "source scaling rejects non-unique record identifiers",
  {
    data_records <-
      tibble::tibble(
        dataset_id = base::rep(1L, 2L),
        sample_id = base::rep(11L, 2L),
        trait_id = base::rep(21L, 2L),
        taxon_id = base::rep(31L, 2L),
        taxon_name = base::rep("A", 2L),
        data_source_id = 294L,
        trait_domain_name = "Leaf Area",
        trait_name = "leaf area",
        trait_value = base::c(1, 2)
      )
    data_rules <-
      tibble::tibble(
        source_scale_rule_id = "rule-294",
        data_source_id = 294L,
        trait_domain_name = "Leaf Area",
        trait_name = "",
        scale_factor = 100,
        review_status = "approved"
      )

    testthat::expect_error(
      apply_trait_source_scale_rules(data_records, data_rules),
      regexp = "unique record identifiers"
    )
  }
)
