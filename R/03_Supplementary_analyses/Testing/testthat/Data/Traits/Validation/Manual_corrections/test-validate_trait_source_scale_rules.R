testthat::test_that(
  "source scale validation binds rules to version source and count",
  {
    path_vault <-
      withr::local_tempfile(fileext = ".sqlite")
    connection_vault <-
      DBI::dbConnect(RSQLite::SQLite(), path_vault)
    DBI::dbWriteTable(
      connection_vault,
      "version_control",
      tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
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

    data_release <-
      tibble::tibble(
        vegvault_version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )
    rule_key <-
      "2.0.0|294|Leaf Area||100"
    data_rules <-
      tibble::tibble(
        source_scale_rule_id = digest::digest(
          rule_key,
          algo = "sha256",
          serialize = FALSE
        ),
        vegvault_version = "2.0.0",
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
        data_source_id = base::c(294L, 294L, 500L, NA_integer_),
        trait_domain_name = "Leaf Area",
        trait_name = "leaf area",
        trait_value = base::c(1, 2, 3, 4)
      )

    data_validated <-
      validate_trait_source_scale_rules(
        data_trait_source_scale_rules = data_rules,
        data_trait_records = data_records,
        path_vegvault = path_vault,
        data_vegvault_release = data_release
      )

    testthat::expect_identical(data_validated, data_rules)
    testthat::expect_error(
      validate_trait_source_scale_rules(
        data_trait_source_scale_rules = data_rules |>
          dplyr::mutate(vegvault_version = "1.0.0"),
        data_trait_records = data_records,
        path_vegvault = path_vault,
        data_vegvault_release = data_release
      ),
      regexp = "version"
    )
    testthat::expect_error(
      validate_trait_source_scale_rules(
        data_trait_source_scale_rules = data_rules |>
          dplyr::mutate(expected_data_source_desc = "changed"),
        data_trait_records = data_records,
        path_vegvault = path_vault,
        data_vegvault_release = data_release
      ),
      regexp = "source description"
    )
    testthat::expect_error(
      validate_trait_source_scale_rules(
        data_trait_source_scale_rules = data_rules |>
          dplyr::mutate(expected_match_count = 3L),
        data_trait_records = data_records,
        path_vegvault = path_vault,
        data_vegvault_release = data_release
      ),
      regexp = "expected count"
    )
  }
)

testthat::test_that(
  "source scale validation passes an empty rule set",
  {
    path_vault <-
      withr::local_tempfile(fileext = ".sqlite")
    connection_vault <-
      DBI::dbConnect(RSQLite::SQLite(), path_vault)
    DBI::dbWriteTable(
      connection_vault,
      "version_control",
      tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
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

    data_release <-
      tibble::tibble(
        vegvault_version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )
    path_rules <-
      withr::local_tempfile(fileext = ".csv")
    readr::write_lines(
      stringr::str_c(
        "source_scale_rule_id,vegvault_version,data_source_id,",
        "expected_data_source_desc,trait_domain_name,trait_name,",
        "scale_factor,expected_match_count,rationale,",
        "evidence_reference,review_status,reviewer,reviewed_at"
      ),
      path_rules
    )
    data_rules <-
      load_trait_source_scale_rules(
        path_trait_source_scale_rules = path_rules
      )
    data_records <-
      tibble::tibble(
        data_source_id = base::c(294L, NA_integer_),
        trait_domain_name = "Leaf Area",
        trait_name = "leaf area",
        trait_value = base::c(1, 2)
      )

    data_validated <-
      validate_trait_source_scale_rules(
        data_trait_source_scale_rules = data_rules,
        data_trait_records = data_records,
        path_vegvault = path_vault,
        data_vegvault_release = data_release
      )

    testthat::expect_identical(data_validated, data_rules)
    testthat::expect_equal(base::nrow(data_validated), 0L)
  }
)

testthat::test_that(
  "source scale validation stops when one rule names another version",
  {
    path_vault <-
      withr::local_tempfile(fileext = ".sqlite")
    connection_vault <-
      DBI::dbConnect(RSQLite::SQLite(), path_vault)
    DBI::dbWriteTable(
      connection_vault,
      "version_control",
      tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )
    )
    DBI::dbWriteTable(
      connection_vault,
      "DatasetSourcesID",
      tibble::tibble(
        data_source_id = base::c(294L, 509L),
        data_source_desc = base::c("BE_LOW", "Other source")
      )
    )
    DBI::dbDisconnect(connection_vault)

    data_release <-
      tibble::tibble(
        vegvault_version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )
    vec_rule_keys <-
      base::c(
        "2.0.0|294|Leaf Area||100",
        "1.0.0|509|Leaf Area||10"
      )
    data_rules <-
      tibble::tibble(
        source_scale_rule_id = purrr::map_chr(
          vec_rule_keys,
          ~ digest::digest(
            .x,
            algo = "sha256",
            serialize = FALSE
          )
        ),
        vegvault_version = base::c("2.0.0", "1.0.0"),
        data_source_id = base::c(294L, 509L),
        expected_data_source_desc = base::c("BE_LOW", "Other source"),
        trait_domain_name = "Leaf Area",
        trait_name = "",
        scale_factor = base::c(100, 10),
        expected_match_count = 1L,
        rationale = "Documented source-unit error.",
        evidence_reference = "report:source-scale",
        review_status = "approved",
        reviewer = "Reviewer",
        reviewed_at = "2026-08-28"
      )
    data_records <-
      tibble::tibble(
        data_source_id = base::c(294L, 509L),
        trait_domain_name = "Leaf Area",
        trait_name = "leaf area",
        trait_value = base::c(1, 2)
      )

    testthat::expect_error(
      validate_trait_source_scale_rules(
        data_trait_source_scale_rules = data_rules,
        data_trait_records = data_records,
        path_vegvault = path_vault,
        data_vegvault_release = data_release
      ),
      regexp = "does not match the VegVault release"
    )
  }
)

testthat::test_that(
  "source scale validation stops when the file holds another release",
  {
    path_vault <-
      withr::local_tempfile(fileext = ".sqlite")
    connection_vault <-
      DBI::dbConnect(RSQLite::SQLite(), path_vault)
    DBI::dbWriteTable(
      connection_vault,
      "version_control",
      tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_rebuilt"
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

    data_release <-
      tibble::tibble(
        vegvault_version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )
    data_rules <-
      tibble::tibble(
        source_scale_rule_id = digest::digest(
          "2.0.0|294|Leaf Area||100",
          algo = "sha256",
          serialize = FALSE
        ),
        vegvault_version = "2.0.0",
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
    data_records <-
      tibble::tibble(
        data_source_id = 294L,
        trait_domain_name = "Leaf Area",
        trait_name = "leaf area",
        trait_value = 1
      )

    testthat::expect_error(
      validate_trait_source_scale_rules(
        data_trait_source_scale_rules = data_rules,
        data_trait_records = data_records,
        path_vegvault = path_vault,
        data_vegvault_release = data_release
      ),
      class = "biodynamics_vegvault_release_mismatch"
    )
  }
)

testthat::test_that(
  "source scale validation requires the release record",
  {
    path_vault <-
      withr::local_tempfile(fileext = ".sqlite")
    connection_vault <-
      DBI::dbConnect(RSQLite::SQLite(), path_vault)
    DBI::dbWriteTable(
      connection_vault,
      "version_control",
      tibble::tibble(
        id = 5L,
        version = "2.0.0",
        update_date = "2026-11-25"
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

    data_rules <-
      tibble::tibble(
        source_scale_rule_id = digest::digest(
          "2.0.0|294|Leaf Area||100",
          algo = "sha256",
          serialize = FALSE
        ),
        vegvault_version = "2.0.0",
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
    data_records <-
      tibble::tibble(
        data_source_id = 294L,
        trait_domain_name = "Leaf Area",
        trait_name = "leaf area",
        trait_value = 1
      )

    testthat::expect_error(
      validate_trait_source_scale_rules(
        data_trait_source_scale_rules = data_rules,
        data_trait_records = data_records,
        path_vegvault = path_vault
      ),
      regexp = "data_vegvault_release"
    )
  }
)

testthat::test_that(
  "source scale validation rejects malformed and overlapping rules",
  {
    path_vault <-
      withr::local_tempfile(fileext = ".sqlite")
    connection_vault <-
      DBI::dbConnect(RSQLite::SQLite(), path_vault)
    DBI::dbWriteTable(
      connection_vault,
      "version_control",
      tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
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

    data_release <-
      tibble::tibble(
        vegvault_version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )
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
          "2.0.0|294|Leaf Area||100",
          algo = "sha256",
          serialize = FALSE
        ),
        vegvault_version = "2.0.0",
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
        data_trait_source_scale_rules = data_rules |>
          dplyr::mutate(scale_factor = 0),
        data_trait_records = data_records,
        path_vegvault = path_vault,
        data_vegvault_release = data_release
      ),
      regexp = "positive finite"
    )
    testthat::expect_error(
      validate_trait_source_scale_rules(
        data_trait_source_scale_rules = dplyr::bind_rows(
          data_rules,
          data_rules
        ),
        data_trait_records = data_records,
        path_vegvault = path_vault,
        data_vegvault_release = data_release
      ),
      regexp = "overlap|unique"
    )
  }
)
