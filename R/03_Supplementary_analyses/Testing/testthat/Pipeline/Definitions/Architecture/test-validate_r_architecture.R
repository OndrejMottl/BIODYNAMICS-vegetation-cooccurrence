testthat::test_that(
  "validate_r_architecture() accepts excepted findings",
  {
    data_findings <-
      tibble::tibble(
        finding_id = "ARCH-FINDING-0001",
        finding_type = "function_naming",
        current_path = "R/Functions/example.R",
        symbol = "example",
        owner_issue = "#141",
        message = "Review the function name.",
        resolution_status = "excepted",
        exception_id = "ARCH-141-001"
      )

    testthat::expect_equal(
      validate_r_architecture(data_findings = data_findings),
      data_findings
    )
  }
)

testthat::test_that(
  "validate_r_architecture() rejects blocking findings",
  {
    data_findings <-
      tibble::tibble(
        finding_id = "ARCH-FINDING-0001",
        finding_type = "missing_script",
        current_path = "R/missing.R",
        symbol = NA_character_,
        owner_issue = "#157",
        message = "The script is missing.",
        resolution_status = "blocking",
        exception_id = NA_character_
      )

    testthat::expect_error(
      validate_r_architecture(data_findings = data_findings),
      class = "biodynamics_error_architecture_blocking"
    )
  }
)

testthat::test_that(
  "validate_r_architecture() rejects obsolete report-only status",
  {
    data_findings <-
      tibble::tibble(
        finding_id = "ARCH-FINDING-0001",
        finding_type = "function_naming",
        current_path = "R/Functions/example.R",
        symbol = "example",
        owner_issue = "#141",
        message = "Review the function name.",
        resolution_status = "report_only",
        exception_id = NA_character_
      )

    testthat::expect_error(
      validate_r_architecture(data_findings = data_findings),
      regexp = "blocking or excepted"
    )
  }
)
