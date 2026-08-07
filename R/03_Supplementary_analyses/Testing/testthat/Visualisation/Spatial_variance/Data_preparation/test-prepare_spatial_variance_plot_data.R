testthat::test_that(
  "prepare_spatial_variance_plot_data() labels data",
  {
    data_unit <-
      tibble::tibble(
        scale = base::c("local", "regional"),
        resolution_id = base::c("genus", "functional_type"),
        component = base::c("Associations", "Abiotic"),
        R2_Nagelkerke_adjusted = base::c(0.2, 0.3)
      )

    res_data <-
      prepare_spatial_variance_plot_data(
        data_unit = data_unit,
        vec_scale_levels = base::c("regional", "local"),
        vec_resolution_labels = base::c(
          "genus" = "Genus",
          "functional_type" = "Functional type"
        )
      )

    testthat::expect_s3_class(res_data, "tbl_df")
    testthat::expect_equal(
      base::as.character(dplyr::pull(res_data, scale)),
      base::c("local", "regional")
    )
    testthat::expect_equal(
      base::as.character(dplyr::pull(res_data, resolution_label)),
      base::c("Genus", "Functional type")
    )
    testthat::expect_equal(
      base::levels(dplyr::pull(res_data, resolution_label)),
      base::c("Genus", "Functional type")
    )
    testthat::expect_equal(
      dplyr::pull(res_data, component_label),
      base::c("Biotic co-occurrence", "Abiotic")
    )
    testthat::expect_equal(
      dplyr::pull(res_data, component_total_percentage),
      base::c(0.2, 0.3)
    )
  }
)

testthat::test_that(
  "prepare_spatial_variance_plot_data() scales only when requested",
  {
    data_unit <-
      tibble::tibble(
        scale = base::c("local", "regional"),
        resolution_id = base::c("genus", "functional_type"),
        component = base::c("Associations", "Abiotic"),
        R2_Nagelkerke_adjusted = base::c(0.2, 0.3)
      )

    res_data <-
      prepare_spatial_variance_plot_data(
        data_unit = data_unit,
        vec_scale_levels = base::c("regional", "local"),
        vec_resolution_labels = base::c(
          "genus" = "Genus",
          "functional_type" = "Functional type"
        ),
        scale_source_to_percentage = TRUE
      )

    testthat::expect_equal(
      dplyr::pull(res_data, component_total_percentage),
      base::c(20, 30)
    )
  }
)

testthat::test_that(
  "prepare_spatial_variance_plot_data() validates inputs",
  {
    testthat::expect_error(
      prepare_spatial_variance_plot_data(
        data_unit = tibble::tibble(scale = "local"),
        vec_scale_levels = "local",
        vec_resolution_labels = base::c("genus" = "Genus")
      ),
      regexp = "data_unit"
    )

    testthat::expect_error(
      prepare_spatial_variance_plot_data(
        data_unit = tibble::tibble(),
        vec_scale_levels = base::character(),
        vec_resolution_labels = base::c("genus" = "Genus")
      ),
      regexp = "vec_scale_levels"
    )

    testthat::expect_error(
      prepare_spatial_variance_plot_data(
        data_unit = tibble::tibble(
          scale = "local",
          resolution_id = "genus",
          component = "Abiotic",
          R2_Nagelkerke_adjusted = 0.2
        ),
        vec_scale_levels = "local",
        vec_resolution_labels = base::c("genus" = "Genus"),
        scale_source_to_percentage = NA
      ),
      regexp = "scale_source_to_percentage"
    )
  }
)

testthat::test_that(
  "prepare_spatial_variance_plot_data() flags grouped sums above 100",
  {
    data_unit <-
      tibble::tibble(
        scale = base::c("local", "local", "local"),
        scale_id = base::c("local_01", "local_01", "local_01"),
        resolution_id = base::c("genus", "genus", "genus"),
        component = base::c("Abiotic", "Spatial", "Associations"),
        R2_Nagelkerke_percentage = base::c(60, 30, 20)
      )

    testthat::expect_error(
      prepare_spatial_variance_plot_data(
        data_unit = data_unit,
        vec_scale_levels = "local",
        vec_resolution_labels = base::c("genus" = "Genus"),
        percentage_source_column = "R2_Nagelkerke_percentage",
        sum_over_100_action = "error"
      ),
      regexp = "exceed 100"
    )

    testthat::expect_warning(
      prepare_spatial_variance_plot_data(
        data_unit = data_unit,
        vec_scale_levels = "local",
        vec_resolution_labels = base::c("genus" = "Genus"),
        percentage_source_column = "R2_Nagelkerke_percentage",
        sum_over_100_action = "warning"
      ),
      regexp = "exceed 100"
    )
  }
)

testthat::test_that(
  "prepare_spatial_variance_plot_data() accepts pre-scaled percentage",
  {
    data_unit <-
      tibble::tibble(
        scale = base::c("local", "regional"),
        resolution_id = base::c("genus", "functional_type"),
        component = base::c("Associations", "Abiotic"),
        R2_Nagelkerke_percentage = base::c(44.5, 55.5)
      )

    res_data <-
      prepare_spatial_variance_plot_data(
        data_unit = data_unit,
        vec_scale_levels = base::c("regional", "local"),
        vec_resolution_labels = base::c(
          "genus" = "Genus",
          "functional_type" = "Functional type"
        ),
        percentage_source_column = "R2_Nagelkerke_percentage",
        scale_source_to_percentage = FALSE
      )

    testthat::expect_equal(
      dplyr::pull(res_data, component_total_percentage),
      base::c(44.5, 55.5)
    )
  }
)
