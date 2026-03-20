testthat::test_that(
  "error when vec_taxa_without_classification is not character",
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
  "error when vec_taxa_without_classification is numeric",
  {
    testthat::expect_error(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = c(1.1, 2.2)
      ),
      regexp = "character"
    )
  }
)

testthat::test_that(
  "returns TRUE invisibly when no taxa are missing",
  {
    result <-
      check_and_report_missing_taxa(
        vec_taxa_without_classification = character(0)
      )

    testthat::expect_true(
      isTRUE(result)
    )
  }
)

testthat::test_that(
  "stops with an error when missing taxa are present",
  {
    testthat::expect_error(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = c("Taxon_a", "Taxon_b")
      )
    )
  }
)

testthat::test_that(
  "error message contains count of missing taxa",
  {
    testthat::expect_error(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = c(
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
  "error message mentions data_missing_taxa_template",
  {
    testthat::expect_error(
      check_and_report_missing_taxa(
        vec_taxa_without_classification = c("Taxon_a")
      ),
      regexp = "data_missing_taxa_template"
    )
  }
)

