testthat::test_that(
  ".allocate_shapley_variance_components() preserves equal-split allocation",
  {
    data_slice <-
      tibble::tibble(
        component = base::c(
          "Abiotic",
          "Associations",
          "Spatial",
          "Abiotic&Associations",
          "Abiotic&Spatial",
          "Associations&Spatial",
          "Abiotic&Associations&Spatial"
        ),
        R2_clamped = base::c(0.1, 0.2, 0.3, 0.04, 0.06, 0.08, 0.09)
      )

    result <-
      .allocate_shapley_variance_components(
        data_slice = data_slice,
        group_keys = tibble::tibble(age = 100)
      )

    expected <-
      tibble::tibble(
        component = base::c("Abiotic", "Associations", "Spatial"),
        R2_Nagelkerke_adjusted = base::c(0.18, 0.29, 0.40)
      )

    testthat::expect_equal(result, expected, tolerance = 1e-12)
  }
)

testthat::test_that(
  ".allocate_shapley_variance_components() treats absent fractions as zero",
  {
    data_slice <-
      tibble::tibble(
        component = "Abiotic",
        R2_clamped = 0.25
      )

    result <-
      .allocate_shapley_variance_components(
        data_slice = data_slice,
        group_keys = tibble::tibble(age = 100)
      )

    testthat::expect_identical(
      dplyr::pull(result, "R2_Nagelkerke_adjusted"),
      base::c(0.25, 0, 0)
    )
  }
)
