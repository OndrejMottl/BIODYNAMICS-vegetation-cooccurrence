testthat::test_that(
  "source-scale report records scaling and provisional TRY LMA",
  {
    path_vault <-
      base::tempfile(fileext = ".sqlite")
    connection_vault <-
      DBI::dbConnect(RSQLite::SQLite(), path_vault)
    DBI::dbWriteTable(
      connection_vault,
      "Datasets",
      tibble::tibble(
        dataset_id = base::c(1L, 2L),
        data_source_id = base::c(294L, 900L),
        data_source_type_id = base::c(1L, 4L)
      )
    )
    DBI::dbDisconnect(connection_vault)
    data_before <-
      tibble::tibble(
        dataset_id = base::c(1L, 2L),
        data_source_id = base::c(294L, 900L),
        taxon_name = base::c("A", "B"),
        trait_domain_name = base::c(
          "Leaf Area",
          "Leaf mass per area"
        ),
        trait_value = base::c(1, 2)
      )
    data_after <-
      data_before |>
      dplyr::mutate(trait_value = base::c(100, 2))
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
      base::tempfile(fileext = ".md")
    path_counts <-
      base::tempfile(fileext = ".csv")

    vec_paths <-
      save_trait_source_scale_report(
        data_trait_records_raw = data_before,
        data_trait_records_source_scaled = data_after,
        data_trait_source_scale_rule_audit = data_rule_audit,
        data_trait_source_scale_record_audit = data_record_audit,
        data_trait_review_application_audit = data_review_audit,
        path_vegvault = path_vault,
        path_report = path_report,
        path_taxon_counts = path_counts
      )

    report_text <-
      readr::read_file(path_report)
    testthat::expect_true(base::all(base::file.exists(vec_paths)))
    testthat::expect_match(report_text, "PROVISIONAL")
    testthat::expect_match(report_text, "1 TRY-derived")
    testthat::expect_match(report_text, "1 review-layer")
    testthat::expect_match(report_text, "3 uniquely scaled")
  }
)
