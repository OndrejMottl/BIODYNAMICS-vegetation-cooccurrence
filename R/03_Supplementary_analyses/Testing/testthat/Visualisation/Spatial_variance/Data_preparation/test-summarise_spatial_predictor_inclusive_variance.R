testthat::test_that(
  "predictor-inclusive summaries retain every domain and group",
  {
    data_plot <-
      tidyr::expand_grid(
        scale = base::c("local", "regional"),
        resolution_label = "Genus",
        component = base::c("Abiotic", "Associations", "Spatial"),
        scale_id = base::c("unit_a", "unit_b", "unit_c")
      ) |>
      dplyr::mutate(
        component_label = dplyr::recode(
          .data$component,
          Abiotic = "Climate",
          Associations = "Biotic co-occurrence"
        ),
        component_total_percentage = dplyr::case_when(
          .data$scale_id == "unit_a" ~ 10,
          .data$scale_id == "unit_b" ~ 20,
          .default = 30
        )
      )

    res <-
      summarise_spatial_predictor_inclusive_variance(data_plot)

    testthat::expect_equal(base::nrow(res), 6L)
    testthat::expect_equal(
      base::unique(dplyr::pull(res, n_units)),
      3L
    )
    testthat::expect_equal(
      base::unique(dplyr::pull(res, median)),
      20
    )
    testthat::expect_equal(
      base::unique(dplyr::pull(res, lwr_95)),
      10.5
    )
    testthat::expect_equal(
      base::unique(dplyr::pull(res, upr_95)),
      29.5
    )
  }
)

testthat::test_that(
  "predictor-inclusive summaries ignore missing values but count units",
  {
    data_plot <-
      tibble::tibble(
        scale = "local",
        resolution_label = "Genus",
        component = "Abiotic",
        component_label = "Climate",
        scale_id = base::c("unit_a", "unit_b"),
        component_total_percentage = base::c(40, NA_real_)
      )

    res <-
      summarise_spatial_predictor_inclusive_variance(data_plot)

    testthat::expect_equal(dplyr::pull(res, n_units), 2L)
    testthat::expect_equal(dplyr::pull(res, median), 40)
    testthat::expect_equal(dplyr::pull(res, lwr_95), 40)
    testthat::expect_equal(dplyr::pull(res, upr_95), 40)
  }
)

testthat::test_that(
  "predictor-inclusive summaries validate required columns",
  {
    testthat::expect_error(
      summarise_spatial_predictor_inclusive_variance(
        tibble::tibble(scale = "local")
      ),
      regexp = "must contain columns"
    )
  }
)
