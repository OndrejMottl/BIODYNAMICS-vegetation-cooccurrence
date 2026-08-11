testthat::test_that(
  "apply_r_architecture_exceptions() matches exact exceptions",
  {
    data_findings <-
      tibble::tibble(
        finding_type = "function_naming",
        current_path = "R/Functions/example.R",
        symbol = "example",
        owning_issue = "#141",
        message = "Review the function name."
      )

    data_exceptions <-
      tibble::tibble(
        exception_id = "ARCH-141-001",
        finding_type = "function_naming",
        current_path = "R/Functions/example.R",
        symbol = "example",
        owner_issue = "#141",
        rationale = "Deferred to Issue #141.",
        expiry_issue = "#141"
      )

    data_result <-
      apply_r_architecture_exceptions(
        data_findings = data_findings,
        data_exceptions = data_exceptions
      )

    testthat::expect_equal(
      data_result[["resolution_status"]],
      "excepted"
    )
    testthat::expect_equal(
      data_result[["exception_id"]],
      "ARCH-141-001"
    )
  }
)

testthat::test_that(
  "apply_r_architecture_exceptions() blocks unmatched findings",
  {
    data_findings <-
      tibble::tibble(
        finding_type = "missing_script",
        current_path = "R/missing.R",
        symbol = NA_character_,
        owning_issue = "#157",
        message = "The script is missing."
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
      apply_r_architecture_exceptions(
        data_findings = data_findings,
        data_exceptions = data_exceptions
      )

    testthat::expect_equal(
      data_result[["resolution_status"]],
      "blocking"
    )
    testthat::expect_true(base::is.na(data_result[["exception_id"]]))
  }
)

testthat::test_that(
  "apply_r_architecture_exceptions() reports orphaned exceptions",
  {
    data_findings <-
      tibble::tibble(
        finding_type = character(),
        current_path = character(),
        symbol = character(),
        owning_issue = character(),
        message = character()
      )

    data_exceptions <-
      tibble::tibble(
        exception_id = "ARCH-141-001",
        finding_type = "function_naming",
        current_path = "R/Functions/example.R",
        symbol = "example",
        owner_issue = "#141",
        rationale = "Deferred to Issue #141.",
        expiry_issue = "#141"
      )

    data_result <-
      apply_r_architecture_exceptions(
        data_findings = data_findings,
        data_exceptions = data_exceptions
      )

    testthat::expect_equal(
      data_result[["finding_type"]],
      "exception_without_finding"
    )
    testthat::expect_equal(
      data_result[["resolution_status"]],
      "blocking"
    )
  }
)

testthat::test_that(
  "apply_r_architecture_exceptions() rejects malformed ledgers",
  {
    data_findings <-
      tibble::tibble(
        finding_type = character(),
        current_path = character(),
        symbol = character(),
        owning_issue = character(),
        message = character()
      )

    data_exceptions <-
      tibble::tibble(
        exception_id = NA_character_,
        finding_type = "function_naming",
        current_path = "R/Functions/example.R",
        symbol = "example",
        owner_issue = "#141",
        rationale = "Deferred to Issue #141.",
        expiry_issue = "#141"
      )

    testthat::expect_error(
      apply_r_architecture_exceptions(
        data_findings = data_findings,
        data_exceptions = data_exceptions
      ),
      class = "biodynamics_error_architecture_exception_schema"
    )
  }
)

testthat::test_that(
  "apply_r_architecture_exceptions() rejects duplicate targets",
  {
    data_findings <-
      tibble::tibble(
        finding_type = character(),
        current_path = character(),
        symbol = character(),
        owning_issue = character(),
        message = character()
      )

    data_exception <-
      tibble::tibble(
        exception_id = "ARCH-141-001",
        finding_type = "function_naming",
        current_path = "R/Functions/example.R",
        symbol = "example",
        owner_issue = "#141",
        rationale = "Deferred to Issue #141.",
        expiry_issue = "#141"
      )

    data_exceptions <-
      dplyr::bind_rows(
        data_exception,
        dplyr::mutate(
          data_exception,
          exception_id = "ARCH-141-002"
        )
      )

    testthat::expect_error(
      apply_r_architecture_exceptions(
        data_findings = data_findings,
        data_exceptions = data_exceptions
      ),
      class = "biodynamics_error_architecture_exception_duplicate_key"
    )
  }
)

testthat::test_that(
  "apply_r_architecture_exceptions() rejects duplicate IDs",
  {
    data_findings <-
      tibble::tibble(
        finding_type = character(),
        current_path = character(),
        symbol = character(),
        owning_issue = character(),
        message = character()
      )

    data_exceptions <-
      tibble::tibble(
        exception_id = base::rep("ARCH-141-001", 2L),
        finding_type = base::c(
          "function_naming",
          "nested_named_helper"
        ),
        current_path = base::c(
          "R/Functions/example.R",
          "R/Functions/another_example.R"
        ),
        symbol = base::c("example", "another_example"),
        owner_issue = base::rep("#141", 2L),
        rationale = base::rep("Deferred to Issue #141.", 2L),
        expiry_issue = base::rep("#141", 2L)
      )

    testthat::expect_error(
      apply_r_architecture_exceptions(
        data_findings = data_findings,
        data_exceptions = data_exceptions
      ),
      class = "biodynamics_error_architecture_exception_duplicate_id"
    )
  }
)
