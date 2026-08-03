testthat::test_that(
  "classify_dataset_prefix() classifies bien, splot, and other",
  {
    vec_dataset_names <-
      base::c(
        "bien_alpha",
        "splot_beta",
        "vegvault_gamma"
      )

    res_dataset_prefixes <-
      classify_dataset_prefix(vec_dataset_names = vec_dataset_names)

    testthat::expect_equal(
      res_dataset_prefixes,
      base::c("bien", "splot", "other")
    )
  }
)


testthat::test_that(
  "classify_dataset_prefix() validates input type and missing values",
  {
    testthat::expect_error(
      classify_dataset_prefix(vec_dataset_names = base::list("bien_a")),
      regexp = "character"
    )

    testthat::expect_error(
      classify_dataset_prefix(
        vec_dataset_names = base::c("bien_a", NA_character_)
      ),
      regexp = "must not contain NA"
    )
  }
)
