testthat::test_that(
  "check_and_report_missing_taxa() rejects integer input",
  {
    testthat::expect_error(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = 123L
      ),
      regexp = "character"
    )
  }
)

testthat::test_that(
  "check_and_report_missing_taxa() rejects numeric input",
  {
    testthat::expect_error(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = base::c(1.1, 2.2)
      ),
      regexp = "character"
    )
  }
)

testthat::test_that(
  "check_and_report_missing_taxa() returns TRUE for empty input",
  {
    result <-
      check_and_report_missing_taxa(
        vec_taxa_without_classification = base::character(0)
      )

    testthat::expect_true(
      base::isTRUE(result)
    )
  }
)

testthat::test_that(
  "check_and_report_missing_taxa() stops for missing taxa",
  {
    testthat::expect_error(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = base::c("Taxon_a", "Taxon_b")
      )
    )
  }
)

testthat::test_that(
  "check_and_report_missing_taxa() reports missing taxa count",
  {
    testthat::expect_error(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = base::c(
          "Taxon_a",
          "Taxon_b",
          "Taxon_c"
        )
      ),
      regexp = "3"
    )
  }
)

testthat::test_that(
  "check_and_report_missing_taxa() mentions targets object",
  {
    testthat::expect_error(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = base::c("Taxon_a")
      ),
      regexp = "data_missing_taxa_template"
    )
  }
)

testthat::test_that(
  "check_and_report_missing_taxa() mentions template CSV",
  {
    testthat::expect_error(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = base::c("Taxon_a")
      ),
      regexp = "missing_taxa_template\\.csv"
    )
  }
)

