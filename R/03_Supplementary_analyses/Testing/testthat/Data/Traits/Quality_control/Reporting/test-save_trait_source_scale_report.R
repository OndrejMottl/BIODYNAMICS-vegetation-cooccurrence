testthat::test_that(
  "source-scale report records approved scaling for the release",
  {
    data_rule_audit <-
      tibble::tibble(
        source_scale_rule_id = "rule",
        data_source_id = 294L,
        trait_domain_name = "Leaf Area",
        trait_name = "",
        scale_factor = 100,
        n_matched = 1L,
        n_scaled = 1L,
        value_min_before = 1,
        value_max_before = 1,
        value_min_after = 100,
        value_max_after = 100
      )
    data_record_audit <-
      tibble::tibble(
        data_source_id = 294L,
        taxon_name = "A",
        trait_domain_name = "Leaf Area"
      )
    data_review_audit <-
      tibble::tibble(
        n_source_satisfied = 1L,
        n_scaled = 2L
      )
    path_report <-
      withr::local_tempfile(fileext = ".md")
    path_counts <-
      withr::local_tempfile(fileext = ".csv")

    vec_paths <-
      save_trait_source_scale_report(
        data_trait_source_scale_rule_audit = data_rule_audit,
        data_trait_source_scale_record_audit = data_record_audit,
        data_trait_review_application_audit = data_review_audit,
        vegvault_version = "2.0.0",
        path_report = path_report,
        path_taxon_counts = path_counts
      )

    report_text <-
      readr::read_file(path_report)
    data_counts <-
      readr::read_csv(path_counts, show_col_types = FALSE)

    testthat::expect_identical(vec_paths, base::c(path_report, path_counts))
    testthat::expect_true(base::all(base::file.exists(vec_paths)))
    testthat::expect_match(report_text, "VegVault 2.0.0")
    testthat::expect_match(report_text, "scaled 1 records")
    testthat::expect_match(report_text, "1 review-layer")
    testthat::expect_match(report_text, "3 uniquely scaled")
    testthat::expect_no_match(report_text, "PROVISIONAL")
    testthat::expect_no_match(report_text, "TRY")
    testthat::expect_equal(base::nrow(data_counts), 1L)
  }
)

testthat::test_that(
  "source-scale report states when the release has no approved rules",
  {
    data_records <-
      tibble::tibble(
        dataset_id = 1L,
        sample_id = 11L,
        trait_id = 21L,
        taxon_id = 31L,
        taxon_name = "A",
        data_source_id = NA_integer_,
        trait_domain_name = "Leaf Area",
        trait_name = "leaf area",
        trait_value = 1
      )
    data_rules <-
      tibble::tibble(
        source_scale_rule_id = base::character(),
        data_source_id = base::integer(),
        trait_domain_name = base::character(),
        trait_name = base::character(),
        scale_factor = base::numeric(),
        review_status = base::character()
      )
    list_application <-
      apply_trait_source_scale_rules(
        data_trait_records = data_records,
        data_trait_source_scale_rules = data_rules
      )
    data_review_audit <-
      tibble::tibble(
        n_source_satisfied = 0L,
        n_scaled = 0L
      )
    path_report <-
      withr::local_tempfile(fileext = ".md")
    path_counts <-
      withr::local_tempfile(fileext = ".csv")

    save_trait_source_scale_report(
      data_trait_source_scale_rule_audit =
        list_application[["data_source_scale_rule_audit"]],
      data_trait_source_scale_record_audit =
        list_application[["data_source_scale_record_audit"]],
      data_trait_review_application_audit = data_review_audit,
      vegvault_version = "2.0.0",
      path_report = path_report,
      path_taxon_counts = path_counts
    )

    report_text <-
      readr::read_file(path_report)
    data_counts <-
      readr::read_csv(path_counts, show_col_types = FALSE)

    testthat::expect_match(
      report_text,
      "No approved source-scale rules for VegVault 2.0.0"
    )
    testthat::expect_equal(base::nrow(data_counts), 0L)
    testthat::expect_named(
      data_counts,
      base::c(
        "data_source_id",
        "trait_domain_name",
        "taxon_name",
        "n_scaled_records"
      )
    )
  }
)

testthat::test_that(
  "source-scale report requires one VegVault version",
  {
    data_rule_audit <-
      tibble::tibble(
        source_scale_rule_id = "rule",
        data_source_id = 294L,
        trait_domain_name = "Leaf Area",
        trait_name = "",
        scale_factor = 100,
        n_matched = 1L,
        n_scaled = 1L,
        value_min_before = 1,
        value_max_before = 1,
        value_min_after = 100,
        value_max_after = 100
      )
    data_record_audit <-
      tibble::tibble(
        data_source_id = 294L,
        taxon_name = "A",
        trait_domain_name = "Leaf Area"
      )
    data_review_audit <-
      tibble::tibble(
        n_source_satisfied = 1L,
        n_scaled = 2L
      )

    purrr::walk(
      .x = base::list(NA_character_, base::c("2.0.0", "1.0.0"), 2),
      .f = ~ testthat::expect_error(
        save_trait_source_scale_report(
          data_trait_source_scale_rule_audit = data_rule_audit,
          data_trait_source_scale_record_audit = data_record_audit,
          data_trait_review_application_audit = data_review_audit,
          vegvault_version = .x,
          path_report = withr::local_tempfile(fileext = ".md"),
          path_taxon_counts = withr::local_tempfile(fileext = ".csv")
        ),
        regexp = "'vegvault_version' must be"
      )
    )
  }
)
