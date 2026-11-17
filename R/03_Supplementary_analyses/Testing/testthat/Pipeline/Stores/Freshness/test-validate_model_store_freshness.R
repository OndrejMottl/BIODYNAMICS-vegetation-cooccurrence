testthat::test_that(
  "validate_model_store_freshness() passes without blocking findings",
  {
    data_findings_resolved <-
      tibble::tibble(
        store_path_relative = "Data/targets/a/pipeline",
        target_name = base::c("list_partition", "data_progress"),
        finding_type = base::c("outdated", "always_cued_not_evaluated"),
        resolution_status = base::c("ledger_covered", "informational")
      )

    testthat::expect_invisible(
      validate_model_store_freshness(data_findings_resolved)
    )
    testthat::expect_equal(
      validate_model_store_freshness(data_findings_resolved),
      data_findings_resolved
    )
  }
)

testthat::test_that(
  "validate_model_store_freshness() aborts on blocking findings",
  {
    testthat::expect_error(
      validate_model_store_freshness(
        tibble::tibble(
          store_path_relative = "Data/targets/a/pipeline",
          target_name = "mod_jsdm_genus",
          finding_type = "outdated",
          resolution_status = "blocking"
        )
      ),
      class = "model_store_not_current"
    )
  }
)

testthat::test_that(
  "validate_model_store_freshness() validates its input",
  {
    testthat::expect_error(
      validate_model_store_freshness(tibble::tibble(a = 1)),
      "freshness ledger"
    )
  }
)
