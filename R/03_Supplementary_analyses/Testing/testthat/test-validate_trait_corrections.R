# Input validation: non-character path -----
testthat::test_that(
  "errors if path_corrections is not character",
  {
    testthat::expect_error(
      validate_trait_corrections(
        path_corrections = 123L
      ),
      regexp = "path_corrections"
    )
  }
)

testthat::test_that(
  "errors if path_corrections is NULL",
  {
    testthat::expect_error(
      validate_trait_corrections(
        path_corrections = NULL
      ),
      regexp = "path_corrections"
    )
  }
)

testthat::test_that(
  "errors if path_corrections is length > 1",
  {
    testthat::expect_error(
      validate_trait_corrections(
        path_corrections = base::c("a.csv", "b.csv")
      ),
      regexp = "path_corrections"
    )
  }
)

# Input validation: file must exist -----
testthat::test_that(
  "errors if path_corrections file does not exist",
  {
    path_missing <- base::tempfile(fileext = ".csv")

    testthat::expect_error(
      validate_trait_corrections(
        path_corrections = path_missing
      ),
      regexp = "path_corrections"
    )
  }
)

# Output structure: valid file, all CHECKED = TRUE -----
testthat::test_that(
  "returns a tibble when all rows have CHECKED = TRUE",
  {
    path_temp <- base::tempfile(fileext = ".csv")

    readr::write_csv(
      tibble::tibble(
        taxon_name = "Quercus robur",
        trait_domain_name = "Leaf mass per area",
        action = "scale",
        scale_factor = 0.1,
        notes = "",
        CHECKED = TRUE
      ),
      path_temp
    )

    res <-
      validate_trait_corrections(
        path_corrections = path_temp
      )

    testthat::expect_s3_class(res, "tbl_df")
  }
)

testthat::test_that(
  "returned tibble has all expected columns",
  {
    path_temp <- base::tempfile(fileext = ".csv")

    readr::write_csv(
      tibble::tibble(
        taxon_name = "Quercus robur",
        trait_domain_name = "Leaf mass per area",
        action = "scale",
        scale_factor = 0.1,
        notes = "",
        CHECKED = TRUE
      ),
      path_temp
    )

    res <-
      validate_trait_corrections(
        path_corrections = path_temp
      )

    vec_expected_cols <-
      base::c(
        "taxon_name",
        "trait_domain_name",
        "action",
        "scale_factor",
        "notes",
        "CHECKED"
      )

    testthat::expect_named(
      res,
      vec_expected_cols,
      ignore.order = TRUE
    )
  }
)

testthat::test_that(
  "returned tibble has only rows with CHECKED = TRUE",
  {
    path_temp <- base::tempfile(fileext = ".csv")

    readr::write_csv(
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
      ),
      path_temp
    )

    res <-
      validate_trait_corrections(
        path_corrections = path_temp
      )

    vec_checked <-
      dplyr::pull(res, CHECKED)

    testthat::expect_true(
      base::all(vec_checked == TRUE)
    )
  }
)

# Guard behaviour: abort on unchecked rows -----
testthat::test_that(
  "aborts when a row has CHECKED = FALSE",
  {
    path_temp <- base::tempfile(fileext = ".csv")

    readr::write_csv(
      tibble::tibble(
        taxon_name = "Quercus robur",
        trait_domain_name = "Leaf mass per area",
        action = "scale",
        scale_factor = 0.1,
        notes = "",
        CHECKED = FALSE
      ),
      path_temp
    )

    testthat::expect_error(
      validate_trait_corrections(
        path_corrections = path_temp
      ),
      regexp = "CHECKED"
    )
  }
)

testthat::test_that(
  "aborts when a row has CHECKED = NA",
  {
    path_temp <- base::tempfile(fileext = ".csv")

    readr::write_csv(
      tibble::tibble(
        taxon_name = "Quercus robur",
        trait_domain_name = "Leaf mass per area",
        action = "scale",
        scale_factor = 0.1,
        notes = "",
        CHECKED = NA
      ),
      path_temp
    )

    testthat::expect_error(
      validate_trait_corrections(
        path_corrections = path_temp
      ),
      regexp = "CHECKED"
    )
  }
)

testthat::test_that(
  "aborts when the CHECKED column is missing from CSV",
  {
    path_temp <- base::tempfile(fileext = ".csv")

    readr::write_csv(
      tibble::tibble(
        taxon_name = "Quercus robur",
        trait_domain_name = "Leaf mass per area",
        action = "scale",
        scale_factor = 0.1,
        notes = ""
      ),
      path_temp
    )

    testthat::expect_error(
      validate_trait_corrections(
        path_corrections = path_temp
      ),
      regexp = "CHECKED"
    )
  }
)

testthat::test_that(
  "error message reports number of unchecked rows",
  {
    path_temp <- base::tempfile(fileext = ".csv")

    readr::write_csv(
      tibble::tibble(
        taxon_name = base::c("Quercus robur", "Betula pendula"),
        trait_domain_name = base::c(
          "Leaf mass per area",
          "Plant height"
        ),
        action = base::c("scale", "exclude"),
        scale_factor = base::c(0.1, NA_real_),
        notes = base::c("", "outlier"),
        CHECKED = base::c(FALSE, FALSE)
      ),
      path_temp
    )

    testthat::expect_error(
      validate_trait_corrections(
        path_corrections = path_temp
      ),
      regexp = "[0-9]+ row"
    )
  }
)

testthat::test_that(
  "aborts on a mix of TRUE and FALSE CHECKED rows",
  {
    path_temp <- base::tempfile(fileext = ".csv")

    readr::write_csv(
      tibble::tibble(
        taxon_name = base::c("Quercus robur", "Betula pendula"),
        trait_domain_name = base::c(
          "Leaf mass per area",
          "Plant height"
        ),
        action = base::c("scale", "exclude"),
        scale_factor = base::c(0.1, NA_real_),
        notes = base::c("", "outlier"),
        CHECKED = base::c(TRUE, FALSE)
      ),
      path_temp
    )

    testthat::expect_error(
      validate_trait_corrections(
        path_corrections = path_temp
      ),
      regexp = "CHECKED"
    )
  }
)

# Edge cases -----
testthat::test_that(
  "returns zero-row tibble for header-only CSV",
  {
    path_temp <- base::tempfile(fileext = ".csv")

    readr::write_csv(
      tibble::tibble(
        taxon_name = base::character(0),
        trait_domain_name = base::character(0),
        action = base::character(0),
        scale_factor = base::numeric(0),
        notes = base::character(0),
        CHECKED = base::logical(0)
      ),
      path_temp
    )

    res <-
      validate_trait_corrections(
        path_corrections = path_temp
      )

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(base::nrow(res), 0L)
  }
)

testthat::test_that(
  "returns n-row tibble when all n rows are CHECKED = TRUE",
  {
    path_temp <- base::tempfile(fileext = ".csv")

    n_rows <- 3L

    readr::write_csv(
      tibble::tibble(
        taxon_name = base::c(
          "Quercus robur",
          "Betula pendula",
          "Pinus sylvestris"
        ),
        trait_domain_name = base::c(
          "Leaf mass per area",
          "Plant height",
          "Stem density"
        ),
        action = base::c("scale", "exclude", "scale"),
        scale_factor = base::c(0.1, NA_real_, 2.0),
        notes = base::c("", "outlier", ""),
        CHECKED = base::c(TRUE, TRUE, TRUE)
      ),
      path_temp
    )

    res <-
      validate_trait_corrections(
        path_corrections = path_temp
      )

    testthat::expect_equal(base::nrow(res), n_rows)
  }
)
