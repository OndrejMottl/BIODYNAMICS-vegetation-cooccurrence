testthat::test_that(
  ".lookup_jsdm_variance_component() returns the first matching value",
  {
    data_slice <-
      tibble::tibble(
        component = base::c("Abiotic", "Abiotic", "Spatial"),
        R2_clamped = base::c(0.4, 0.8, 0.2)
      )

    testthat::expect_identical(
      .lookup_jsdm_variance_component(
        data_slice = data_slice,
        component_name = "Abiotic"
      ),
      0.4
    )
  }
)

testthat::test_that(
  ".lookup_jsdm_variance_component() returns zero for a missing component",
  {
    data_slice <-
      tibble::tibble(
        component = "Abiotic",
        R2_clamped = 0.4
      )

    testthat::expect_identical(
      .lookup_jsdm_variance_component(
        data_slice = data_slice,
        component_name = "Spatial"
      ),
      0
    )
  }
)
