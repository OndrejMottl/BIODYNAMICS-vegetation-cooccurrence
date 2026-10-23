testthat::test_that(
  "predictor-inclusive manuscript plot exposes domains and overlap note",
  {
    data_plot <-
      tidyr::expand_grid(
        scale = base::factor(
          base::c("continental", "regional", "local"),
          levels = base::c("continental", "regional", "local")
        ),
        scale_id = base::c("unit_a", "unit_b"),
        resolution_label = base::factor(
          base::c("Genus", "Family", "Functional type"),
          levels = base::c("Genus", "Family", "Functional type")
        ),
        component = base::c("Abiotic", "Associations", "Spatial")
      ) |>
      dplyr::mutate(
        component_label = base::factor(
          dplyr::recode(
            .data$component,
            Abiotic = "Climate",
            Associations = "Biotic co-occurrence"
          ),
          levels = base::c(
            "Climate",
            "Biotic co-occurrence",
            "Spatial"
          )
        ),
        component_total_percentage = 50,
        continent_id = "europe"
      )
    data_summary <-
      data_plot |>
      dplyr::distinct(
        .data$scale,
        .data$resolution_label,
        .data$component,
        .data$component_label
      ) |>
      dplyr::mutate(
        n_units = 2L,
        median = 50,
        lwr_95 = 45,
        upr_95 = 55
      )

    res_plot <-
      plot_manuscript_predictor_inclusive_variance(
        data_plot = data_plot,
        data_summary = data_summary
      )

    testthat::expect_s3_class(res_plot, "ggplot")
    testthat::expect_match(
      res_plot |>
        purrr::chuck("labels") |>
        purrr::chuck("caption"),
      "domain percentages overlap"
    )
    testthat::expect_equal(
      base::levels(dplyr::pull(data_plot, component_label)),
      base::c("Climate", "Biotic co-occurrence", "Spatial")
    )
    vec_limits <-
      res_plot[["scales"]][["scales"]][[1L]][["limits"]]
    testthat::expect_equal(vec_limits, base::c(0, 100))
  }
)

testthat::test_that(
  "predictor-inclusive manuscript plot validates percentage bounds",
  {
    data_plot <-
      tibble::tibble(
        scale = "local",
        scale_id = "unit_a",
        resolution_label = "Genus",
        component = "Abiotic",
        component_label = "Climate",
        component_total_percentage = 120,
        continent_id = "europe"
      )
    data_summary <-
      tibble::tibble(
        scale = "local",
        resolution_label = "Genus",
        component = "Abiotic",
        component_label = "Climate",
        n_units = 1L,
        median = 120,
        lwr_95 = 120,
        upr_95 = 120
      )

    testthat::expect_error(
      plot_manuscript_predictor_inclusive_variance(
        data_plot = data_plot,
        data_summary = data_summary
      ),
      regexp = "bounds"
    )
  }
)
