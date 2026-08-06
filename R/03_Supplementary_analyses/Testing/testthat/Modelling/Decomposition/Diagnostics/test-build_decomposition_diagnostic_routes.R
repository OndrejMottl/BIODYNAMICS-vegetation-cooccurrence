testthat::test_that(
  "build_decomposition_diagnostic_routes() returns core routes",
  {
    res <-
      build_decomposition_diagnostic_routes()

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(base::nrow(res), 4L)
    testthat::expect_equal(
      res |>
        dplyr::pull(route_id),
      c(
        "pooled_spatiotemporal_age",
        "pooled_spatiotemporal_no_age",
        "pooled_spatial_age",
        "temporal_best_slice"
      )
    )
  }
)

testthat::test_that(
  "build_decomposition_diagnostic_routes() defines route settings",
  {
    res <-
      build_decomposition_diagnostic_routes()

    data_temporal <-
      res |>
      dplyr::filter(.data[["route_id"]] == "temporal_best_slice")

    testthat::expect_equal(
      data_temporal |>
        dplyr::pull(sample_mode),
      "temporal_best_slice"
    )
    testthat::expect_equal(
      data_temporal |>
        dplyr::pull(spatial_mode),
      "spatial"
    )
    testthat::expect_false(
      data_temporal |>
        dplyr::pull(use_age)
    )
    testthat::expect_equal(
      data_temporal |>
        dplyr::pull(age_formula_mode),
      "none"
    )
  }
)

testthat::test_that(
  "build_decomposition_diagnostic_routes() keeps legacy age modes",
  {
    res <-
      build_decomposition_diagnostic_routes()

    testthat::expect_equal(
      res |>
        dplyr::pull(age_formula_mode),
      c(
        "interaction",
        "none",
        "interaction",
        "none"
      )
    )
  }
)
