testthat::test_that(
  "trait correction loading rejects non-character paths",
  {
    testthat::expect_error(
      load_trait_corrections(
        path_trait_corrections = 123L
      ),
      regexp = "path_trait_corrections"
    )

    testthat::expect_error(
      load_trait_corrections(
        path_trait_corrections = NULL
      ),
      regexp = "path_trait_corrections"
    )
  }
)

testthat::test_that(
  "trait correction loading rejects multiple paths",
  {
    testthat::expect_error(
      load_trait_corrections(
        path_trait_corrections = base::c("a.csv", "b.csv")
      ),
      regexp = "path_trait_corrections"
    )
  }
)

testthat::test_that(
  "trait correction loading requires an existing file",
  {
    path_missing <-
      base::tempfile(fileext = ".csv")

    testthat::expect_error(
      load_trait_corrections(
        path_trait_corrections = path_missing
      ),
      regexp = "path_trait_corrections"
    )
  }
)

testthat::test_that(
  "trait correction loading returns the CSV records",
  {
    path_trait_corrections <-
      base::tempfile(fileext = ".csv")

    data_trait_corrections <-
      tibble::tibble(
        taxon_name = "Quercus robur",
        trait_domain_name = "Leaf mass per area",
        action = "scale",
        scale_factor = 0.1,
        notes = "",
        CHECKED = TRUE
      )

    readr::write_csv(
      data_trait_corrections,
      path_trait_corrections
    )

    data_trait_corrections_loaded <-
      load_trait_corrections(
        path_trait_corrections = path_trait_corrections
      )

    testthat::expect_s3_class(
      data_trait_corrections_loaded,
      "tbl_df"
    )
    testthat::expect_named(
      data_trait_corrections_loaded,
      base::colnames(data_trait_corrections)
    )
    testthat::expect_equal(
      base::nrow(data_trait_corrections_loaded),
      1L
    )
  }
)

testthat::test_that(
  "trait correction loading does not enforce approval",
  {
    path_trait_corrections <-
      base::tempfile(fileext = ".csv")

    readr::write_csv(
      tibble::tibble(
        taxon_name = "Quercus robur",
        CHECKED = FALSE
      ),
      path_trait_corrections
    )

    testthat::expect_no_error(
      load_trait_corrections(
        path_trait_corrections = path_trait_corrections
      )
    )
  }
)

testthat::test_that(
  "trait correction loading preserves an empty table",
  {
    path_trait_corrections <-
      base::tempfile(fileext = ".csv")

    readr::write_csv(
      tibble::tibble(
        taxon_name = base::character(0),
        CHECKED = base::logical(0)
      ),
      path_trait_corrections
    )

    data_trait_corrections_loaded <-
      load_trait_corrections(
        path_trait_corrections = path_trait_corrections
      )

    testthat::expect_s3_class(
      data_trait_corrections_loaded,
      "tbl_df"
    )
    testthat::expect_equal(
      base::nrow(data_trait_corrections_loaded),
      0L
    )
  }
)
