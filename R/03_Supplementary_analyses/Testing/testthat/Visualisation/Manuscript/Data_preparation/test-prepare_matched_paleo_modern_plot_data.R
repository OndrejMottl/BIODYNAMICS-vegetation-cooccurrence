testthat::test_that(
  "prepare_matched_paleo_modern_plot_data() keeps finite matched pairs",
  {
    data_unit <-
      tibble::tibble(
        scale = base::c("local", "local"),
        scale_id = base::c("a", "a"),
        comparison_id = base::c("genus", "genus"),
        comparison_resolution = base::c("Genus", "Genus"),
        component = base::c("Associations", "Abiotic"),
        R2_Nagelkerke_percentage_paleo = base::c(20, 40),
        R2_Nagelkerke_percentage_modern = base::c(30, 35),
        R2_delta_modern_minus_paleo = base::c(10, -5)
      )
    data_coverage <-
      tibble::tibble(
        scale = "local",
        comparison_id = "genus",
        comparison_resolution = "Genus",
        n_paleo_units = 3L,
        n_modern_units = 2L,
        n_matched_units = 2L,
        n_paleo_unmatched = 1L,
        n_modern_unmatched = 0L
      )

    res <-
      prepare_matched_paleo_modern_plot_data(
        data_unit,
        data_coverage
      )

    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_equal(
      dplyr::pull(res, .data$n_matched_units),
      2L
    )
    testthat::expect_equal(
      dplyr::pull(res, .data$n_paleo_unmatched),
      1L
    )
    testthat::expect_s3_class(
      dplyr::pull(res, .data$scale),
      "factor"
    )
  }
)

testthat::test_that(
  "prepare_matched_paleo_modern_plot_data() requires coverage",
  {
    data_unit <-
      tibble::tibble(
        scale = "local",
        scale_id = "a",
        comparison_id = "genus",
        comparison_resolution = "Genus",
        component = "Associations",
        R2_Nagelkerke_percentage_paleo = 20,
        R2_Nagelkerke_percentage_modern = 30,
        R2_delta_modern_minus_paleo = 10
      )
    data_coverage <-
      tibble::tibble(
        scale = "regional",
        comparison_id = "genus",
        comparison_resolution = "Genus",
        n_paleo_units = 1L,
        n_modern_units = 1L,
        n_matched_units = 1L,
        n_paleo_unmatched = 0L,
        n_modern_unmatched = 0L
      )

    testthat::expect_error(
      prepare_matched_paleo_modern_plot_data(
        data_unit,
        data_coverage
      ),
      "coverage evidence"
    )
  }
)
