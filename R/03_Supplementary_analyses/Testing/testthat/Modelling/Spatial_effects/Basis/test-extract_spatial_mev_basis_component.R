testthat::test_that(
  "extract_spatial_mev_basis_component() preserves disabled NULL",
  {
    testthat::expect_null(
      extract_spatial_mev_basis_component(
        list_spatial_mev_basis = NULL,
        component_name = "data_mev"
      )
    )
  }
)

testthat::test_that(
  "extract_spatial_mev_basis_component() extracts explicit state",
  {
    data_mev <-
      base::data.frame(mev_1 = c(0.1, 0.2))

    res <-
      extract_spatial_mev_basis_component(
        list_spatial_mev_basis = base::list(
          data_mev = data_mev,
          data_provenance = tibble::tibble(method = "exact")
        ),
        component_name = "data_mev"
      )

    testthat::expect_identical(res, data_mev)
  }
)
