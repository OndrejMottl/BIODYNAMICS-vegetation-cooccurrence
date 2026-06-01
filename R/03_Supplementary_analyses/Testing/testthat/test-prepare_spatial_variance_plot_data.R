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
  }
)
