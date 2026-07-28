testthat::test_that(
  "validate_taxa_classification_coverage() rejects integer input",
  {
    testthat::expect_error(
      validate_taxa_classification_coverage(
        vec_taxa_without_classification = 123L
      ),
      regexp = "character"
    )
  }
)

testthat::test_that(
  "validate_taxa_classification_coverage() rejects numeric input",
  {
    testthat::expect_error(
      validate_taxa_classification_coverage(
        vec_taxa_without_classification = base::c(1.1, 2.2)
      ),
      regexp = "character"
    )
  }
)

testthat::test_that(
  "validate_taxa_classification_coverage() returns TRUE for empty input",
  {
    res_validation <-
      validate_taxa_classification_coverage(
        vec_taxa_without_classification = base::character(0)
      )

    testthat::expect_true(
      base::isTRUE(res_validation)
    )
  }
)

testthat::test_that(
  "validate_taxa_classification_coverage() stops for missing taxa",
  {
    testthat::expect_error(
      validate_taxa_classification_coverage(
        vec_taxa_without_classification = base::c("Taxon_a", "Taxon_b")
      )
    )
  }
)

testthat::test_that(
  "validate_taxa_classification_coverage() reports missing taxa count",
  {
    testthat::expect_error(
      validate_taxa_classification_coverage(
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
  "validate_taxa_classification_coverage() mentions targets object",
  {
    testthat::expect_error(
      validate_taxa_classification_coverage(
        vec_taxa_without_classification = base::c("Taxon_a")
      ),
      regexp = "data_missing_taxa_template"
    )
  }
)

testthat::test_that(
  "validate_taxa_classification_coverage() mentions template CSV",
  {
    testthat::expect_error(
      validate_taxa_classification_coverage(
        vec_taxa_without_classification = base::c("Taxon_a")
      ),
      regexp = "missing_taxa_template\\.csv"
    )
  }
)
