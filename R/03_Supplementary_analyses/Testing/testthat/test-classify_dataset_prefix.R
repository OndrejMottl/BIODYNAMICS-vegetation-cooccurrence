testthat::test_that(
  "classify_dataset_prefix() classifies bien, splot, and other",
  {
    vec_dataset_name <-
      base::c(
        "bien_alpha",
        "splot_beta",
        "vegvault_gamma"
      )

    res <-
      classify_dataset_prefix(data_source = vec_dataset_name)

    testthat::expect_equal(
      res,
      base::c("bien", "splot", "other")
    )
  }
)


testthat::test_that(
  "classify_dataset_prefix() validates input type and missing values",
  {
    testthat::expect_error(
      classify_dataset_prefix(data_source = base::list("bien_a")),
      regexp = "character"
    )

    testthat::expect_error(
      classify_dataset_prefix(data_source = base::c("bien_a", NA_character_)),
      regexp = "must not contain NA"
    )
  }
)
