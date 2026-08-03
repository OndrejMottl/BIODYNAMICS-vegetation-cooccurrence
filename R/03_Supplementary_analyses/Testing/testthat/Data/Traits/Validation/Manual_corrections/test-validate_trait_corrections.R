testthat::test_that(
  "trait correction validation rejects non-data-frame input",
  {
    testthat::expect_error(
      validate_trait_corrections(
        data_trait_corrections = NULL
      ),
      regexp = "data_trait_corrections"
    )

    testthat::expect_error(
      validate_trait_corrections(
        data_trait_corrections = "not a data frame"
      ),
      regexp = "data_trait_corrections"
    )
  }
)

testthat::test_that(
  "trait correction validation requires CHECKED",
  {
    data_trait_corrections <-
      tibble::tibble(
        taxon_name = "Quercus robur",
        action = "exclude"
      )

    testthat::expect_error(
      validate_trait_corrections(
        data_trait_corrections = data_trait_corrections
      ),
      regexp = "CHECKED"
    )
  }
)

testthat::test_that(
  "trait correction validation returns approved rows",
  {
    data_trait_corrections <-
      tibble::tibble(
        taxon_name = base::c("Quercus robur", "Betula pendula"),
        trait_domain_name = base::c(
          "Leaf mass per area",
          "Plant height"
        ),
        action = base::c("scale", "exclude"),
        scale_factor = base::c(0.1, NA_real_),
        notes = base::c("", "outlier"),
        CHECKED = base::c(TRUE, TRUE)
      )

    data_trait_corrections_validated <-
      validate_trait_corrections(
        data_trait_corrections = data_trait_corrections
      )

    testthat::expect_s3_class(
      data_trait_corrections_validated,
      "tbl_df"
    )
    testthat::expect_identical(
      data_trait_corrections_validated,
      data_trait_corrections
    )
  }
)

testthat::test_that(
  "trait correction validation rejects unchecked rows",
  {
    data_trait_corrections <-
      tibble::tibble(
        taxon_name = "Quercus robur",
        CHECKED = FALSE
      )

    testthat::expect_error(
      validate_trait_corrections(
        data_trait_corrections = data_trait_corrections
      ),
      regexp = "CHECKED"
    )
  }
)

testthat::test_that(
  "trait correction validation rejects missing approval",
  {
    data_trait_corrections <-
      tibble::tibble(
        taxon_name = "Quercus robur",
        CHECKED = NA
      )

    testthat::expect_error(
      validate_trait_corrections(
        data_trait_corrections = data_trait_corrections
      ),
      regexp = "CHECKED"
    )
  }
)

testthat::test_that(
  "trait correction validation reports unchecked row count",
  {
    data_trait_corrections <-
      tibble::tibble(
        taxon_name = base::c("Quercus robur", "Betula pendula"),
        CHECKED = base::c(FALSE, FALSE)
      )

    testthat::expect_error(
      validate_trait_corrections(
        data_trait_corrections = data_trait_corrections
      ),
      regexp = "2 rows"
    )
  }
)

testthat::test_that(
  "trait correction validation accepts an empty approved table",
  {
    data_trait_corrections <-
      tibble::tibble(
        taxon_name = base::character(0),
        CHECKED = base::logical(0)
      )

    data_trait_corrections_validated <-
      validate_trait_corrections(
        data_trait_corrections = data_trait_corrections
      )

    testthat::expect_s3_class(
      data_trait_corrections_validated,
      "tbl_df"
    )
    testthat::expect_equal(
      base::nrow(data_trait_corrections_validated),
      0L
    )
  }
)
