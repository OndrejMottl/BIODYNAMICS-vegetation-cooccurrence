testthat::test_that(
  "diagnose_r_architecture() returns the maintained schema",
  {
    data_findings <-
      tibble::tibble(
        finding_type = "missing_function",
        current_path = "R/Functions/missing.R",
        symbol = "missing",
        owning_issue = "#157",
        message = "The function is missing."
      )

    data_exceptions <-
      tibble::tibble(
        exception_id = character(),
        finding_type = character(),
        current_path = character(),
        symbol = character(),
        owner_issue = character(),
        rationale = character(),
        expiry_issue = character()
      )

    data_result <-
      diagnose_r_architecture(
        data_findings = data_findings,
        data_exceptions = data_exceptions
      )

    testthat::expect_named(
      data_result,
      base::c(
        "finding_id",
        "finding_type",
        "current_path",
        "symbol",
        "owner_issue",
        "message",
        "resolution_status",
        "exception_id"
      )
    )
  }
)
