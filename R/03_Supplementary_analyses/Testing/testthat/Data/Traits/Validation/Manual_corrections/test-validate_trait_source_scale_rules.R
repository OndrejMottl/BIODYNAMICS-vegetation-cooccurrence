testthat::test_that(
  "source scale validation binds rules to version source and count",
  {
    path_vault <-
      base::tempfile(fileext = ".sqlite")
    connection_vault <-
      DBI::dbConnect(RSQLite::SQLite(), path_vault)
    DBI::dbWriteTable(
      connection_vault,
      "version_control",
      tibble::tibble(
        id = 1L,
        version = "1.0.0",
        update_date = "2025-01-20"
      )
    )
    DBI::dbWriteTable(
      connection_vault,
      "DatasetSourcesID",
      tibble::tibble(
        data_source_id = 294L,
        data_source_desc = "BE_LOW"
      )
    )
    DBI::dbDisconnect(connection_vault)

    rule_key <-
      "1.0.0|294|Leaf Area||100"
    data_rules <-
      tibble::tibble(
        source_scale_rule_id = digest::digest(
          rule_key,
          algo = "sha256",
          serialize = FALSE
        ),
        vegvault_version = "1.0.0",
        data_source_id = 294L,
        expected_data_source_desc = "BE_LOW",
        trait_domain_name = "Leaf Area",
        trait_name = "",
        scale_factor = 100,
        expected_match_count = 2L,
        rationale = "Documented source-unit error.",
        evidence_reference = "report:source-scale",
        review_status = "approved",
        reviewer = "Reviewer",
        reviewed_at = "2026-08-28"
      )
    data_records <-
      tibble::tibble(
        data_source_id = base::c(294L, 294L, 500L),
        trait_domain_name = "Leaf Area",
        trait_name = "leaf area",
        trait_value = base::c(1, 2, 3)
      )

    data_validated <-
      validate_trait_source_scale_rules(
        data_trait_source_scale_rules = data_rules,
        data_trait_records = data_records,
        path_vegvault = path_vault
      )

    testthat::expect_identical(data_validated, data_rules)
    testthat::expect_error(
      validate_trait_source_scale_rules(
        data_rules |>
          dplyr::mutate(vegvault_version = "1.0.1"),
        data_records,
        path_vault
      ),
      regexp = "version"
    )
    testthat::expect_error(
      validate_trait_source_scale_rules(
        data_rules |>
          dplyr::mutate(expected_data_source_desc = "changed"),
        data_records,
        path_vault
      ),
      regexp = "source description"
    )
    testthat::expect_error(
      validate_trait_source_scale_rules(
        data_rules |>
          dplyr::mutate(expected_match_count = 1L),
        data_records,
        path_vault
      ),
      regexp = "expected count"
    )
  }
)

testthat::test_that(
  "source scale validation rejects malformed and overlapping rules",
  {
    path_vault <-
      base::tempfile(fileext = ".sqlite")
    connection_vault <-
      DBI::dbConnect(RSQLite::SQLite(), path_vault)
    DBI::dbWriteTable(
      connection_vault,
      "version_control",
      tibble::tibble(
        id = 1L,
        version = "1.0.0",
        update_date = "2025-01-20"
      )
    )
    DBI::dbWriteTable(
      connection_vault,
      "DatasetSourcesID",
      tibble::tibble(
        data_source_id = 294L,
        data_source_desc = "BE_LOW"
      )
    )
    DBI::dbDisconnect(connection_vault)
    data_records <-
      tibble::tibble(
        data_source_id = 294L,
        trait_domain_name = "Leaf Area",
        trait_name = "leaf area",
        trait_value = 1
      )
    data_rules <-
      tibble::tibble(
        source_scale_rule_id = digest::digest(
          "1.0.0|294|Leaf Area||100",
          algo = "sha256",
          serialize = FALSE
        ),
        vegvault_version = "1.0.0",
        data_source_id = 294L,
        expected_data_source_desc = "BE_LOW",
        trait_domain_name = "Leaf Area",
        trait_name = "",
        scale_factor = 100,
        expected_match_count = 1L,
        rationale = "Documented source-unit error.",
        evidence_reference = "report:source-scale",
        review_status = "approved",
        reviewer = "Reviewer",
        reviewed_at = "2026-08-28"
      )

    testthat::expect_error(
      validate_trait_source_scale_rules(
        data_rules |>
          dplyr::mutate(scale_factor = 0),
        data_records,
        path_vault
      ),
      regexp = "positive finite"
    )
    testthat::expect_error(
      validate_trait_source_scale_rules(
        dplyr::bind_rows(data_rules, data_rules),
        data_records,
        path_vault
      ),
      regexp = "overlap|unique"
    )
  }
)
