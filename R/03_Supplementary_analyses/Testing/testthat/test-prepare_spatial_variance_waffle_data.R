testthat::test_that(
  "prepare_spatial_variance_waffle_data() assigns tile positions",
  {
    data_plot <-
      tibble::tibble(
        scale = base::factor(base::rep("local", 6)),
        resolution_label = base::rep("Genus", 6),
        scale_id = base::c(
          "local_01",
          "local_01",
          "local_01",
          "local_02",
          "local_02",
          "local_02"
        ),
        component = base::c(
          "Abiotic",
          "Spatial",
          "Associations",
          "Abiotic",
          "Spatial",
          "Associations"
        ),
        continent_id = base::c(
          "europe",
          "europe",
          "europe",
          "asia",
          "asia",
          "asia"
        ),
        component_total_percentage = base::c(50, 40, 10, 10, 60, 30),
        R2_Nagelkerke_percentage = base::c(50, 40, 10, 10, 60, 30)
      )

    vec_component_colours <-
      base::c(
        "Abiotic" = "#D95F02",
        "Spatial" = "#7570B3",
        "Associations" = "#1B9E77"
      )

    res_data <-
      prepare_spatial_variance_waffle_data(
        data_plot = data_plot,
        vec_component_colours = vec_component_colours,
        n_waffle_rows = 2L
      )

    testthat::expect_equal(
      dplyr::pull(res_data, R2_Nagelkerke_percentage),
      base::c(10, 30)
    )
    testthat::expect_equal(
      dplyr::pull(res_data, tile_col),
      base::c(1L, 1L)
    )
    testthat::expect_equal(
      dplyr::pull(res_data, tile_row),
      base::c(1L, 2L)
    )
    testthat::expect_true(
      "tile_fill_colour" %in% base::colnames(res_data)
    )
    testthat::expect_true("point_colour" %in% base::colnames(res_data))
  }
)

testthat::test_that(
  "prepare_spatial_variance_waffle_data() validates malformed input",
  {
    data_plot_missing_component <-
      tibble::tibble(
        scale = base::factor(base::rep("local", 2)),
        resolution_label = base::rep("Genus", 2),
        scale_id = base::rep("local_01", 2),
        component = base::c("Abiotic", "Associations"),
        continent_id = base::rep("europe", 2),
        component_total_percentage = base::c(60, 40),
        R2_Nagelkerke_percentage = base::c(60, 40)
      )

    vec_component_colours <-
      base::c(
        "Abiotic" = "#D95F02",
        "Spatial" = "#7570B3",
        "Associations" = "#1B9E77"
      )

    testthat::expect_error(
      prepare_spatial_variance_waffle_data(
        data_plot = data_plot_missing_component,
        vec_component_colours = vec_component_colours,
        n_waffle_rows = 5L
      ),
      regexp = "Required components"
    )
  }
)

testthat::test_that(
  "plot prep output chains to waffle prep for adjusted-default mode",
  {
    data_unit <-
      tibble::tibble(
        scale = base::rep("local", 6),
        scale_id = base::c(
          "local_01",
          "local_01",
          "local_01",
          "local_02",
          "local_02",
          "local_02"
        ),
        resolution_id = base::rep("genus", 6),
        component = base::c(
          "Abiotic",
          "Spatial",
          "Associations",
          "Abiotic",
          "Spatial",
          "Associations"
        ),
        continent_id = base::c(
          "europe",
          "europe",
          "europe",
          "asia",
          "asia",
          "asia"
        ),
        R2_Nagelkerke_adjusted = base::c(0.5, 0.3, 0.2, 0.3, 0.3, 0.4),
        R2_Nagelkerke_percentage = base::c(50, 30, 20, 30, 30, 40)
      )

    data_plot <-
      prepare_spatial_variance_plot_data(
        data_unit = data_unit,
        vec_scale_levels = base::c("local"),
        vec_resolution_labels = base::c("genus" = "Genus")
      )

    res_data <-
      prepare_spatial_variance_waffle_data(
        data_plot = data_plot,
        vec_component_colours = base::c(
          "Abiotic" = "#D95F02",
          "Spatial" = "#7570B3",
          "Associations" = "#1B9E77"
        )
      )

    testthat::expect_equal(base::nrow(res_data), 2L)
    testthat::expect_true(
      "tile_fill_colour" %in% base::colnames(res_data)
    )
  }
)

testthat::test_that(
  "plot prep output chains to waffle prep for pre-scaled mode",
  {
    data_unit <-
      tibble::tibble(
        scale = base::rep("local", 6),
        scale_id = base::c(
          "local_01",
          "local_01",
          "local_01",
          "local_02",
          "local_02",
          "local_02"
        ),
        resolution_id = base::rep("genus", 6),
        component = base::c(
          "Abiotic",
          "Spatial",
          "Associations",
          "Abiotic",
          "Spatial",
          "Associations"
        ),
        continent_id = base::c(
          "europe",
          "europe",
          "europe",
          "asia",
          "asia",
          "asia"
        ),
        R2_Nagelkerke_percentage = base::c(45, 35, 20, 30, 30, 40)
      )

    data_plot <-
      prepare_spatial_variance_plot_data(
        data_unit = data_unit,
        vec_scale_levels = base::c("local"),
        vec_resolution_labels = base::c("genus" = "Genus"),
        percentage_source_column = "R2_Nagelkerke_percentage",
        scale_source_to_percentage = FALSE
      )

    res_data <-
      prepare_spatial_variance_waffle_data(
        data_plot = data_plot,
        vec_component_colours = base::c(
          "Abiotic" = "#D95F02",
          "Spatial" = "#7570B3",
          "Associations" = "#1B9E77"
        )
      )

    testthat::expect_equal(base::nrow(res_data), 2L)
    testthat::expect_true(
      "tile_fill_colour" %in% base::colnames(res_data)
    )
  }
)

testthat::test_that(
  "ranking_column controls deterministic within-panel ordering",
  {
    data_plot <-
      tibble::tibble(
        scale = base::factor(base::rep("local", 6)),
        resolution_label = base::rep("Genus", 6),
        scale_id = base::c(
          "local_01",
          "local_01",
          "local_01",
          "local_02",
          "local_02",
          "local_02"
        ),
        component = base::c(
          "Abiotic",
          "Spatial",
          "Associations",
          "Abiotic",
          "Spatial",
          "Associations"
        ),
        continent_id = base::c(
          "europe",
          "europe",
          "europe",
          "asia",
          "asia",
          "asia"
        ),
        component_total_percentage = base::c(50, 40, 10, 10, 60, 30),
        score_for_order = base::c(1, 1, 1, 2, 2, 2)
      )

    vec_component_colours <-
      base::c(
        "Abiotic" = "#D95F02",
        "Spatial" = "#7570B3",
        "Associations" = "#1B9E77"
      )

    res_data <-
      prepare_spatial_variance_waffle_data(
        data_plot = data_plot,
        vec_component_colours = vec_component_colours,
        ranking_column = "score_for_order"
      )

    testthat::expect_equal(
      dplyr::pull(res_data, scale_id),
      base::c("local_01", "local_02")
    )
  }
)

testthat::test_that(
  "prepare_spatial_variance_waffle_data() validates n_waffle_rows",
  {
    data_plot <-
      tibble::tibble(
        scale = base::factor(base::rep("local", 6)),
        resolution_label = base::rep("Genus", 6),
        scale_id = base::c(
          "local_01",
          "local_01",
          "local_01",
          "local_02",
          "local_02",
          "local_02"
        ),
        component = base::c(
          "Abiotic",
          "Spatial",
          "Associations",
          "Abiotic",
          "Spatial",
          "Associations"
        ),
        continent_id = base::c(
          "europe",
          "europe",
          "europe",
          "asia",
          "asia",
          "asia"
        ),
        component_total_percentage = base::c(50, 40, 10, 10, 60, 30)
      )

    vec_component_colours <-
      base::c(
        "Abiotic" = "#D95F02",
        "Spatial" = "#7570B3",
        "Associations" = "#1B9E77"
      )

    testthat::expect_error(
      prepare_spatial_variance_waffle_data(
        data_plot = data_plot,
        vec_component_colours = vec_component_colours,
        n_waffle_rows = 0L
      ),
      regexp = "positive integer"
    )

    testthat::expect_error(
      prepare_spatial_variance_waffle_data(
        data_plot = data_plot,
        vec_component_colours = vec_component_colours,
        n_waffle_rows = -1L
      ),
      regexp = "positive integer"
    )

    testthat::expect_error(
      prepare_spatial_variance_waffle_data(
        data_plot = data_plot,
        vec_component_colours = vec_component_colours,
        n_waffle_rows = 2
      ),
      regexp = "positive integer"
    )
  }
)

testthat::test_that(
  "prepare_spatial_variance_waffle_data() validates required component colours",
  {
    data_plot <-
      tibble::tibble(
        scale = base::factor(base::rep("local", 4)),
        resolution_label = base::rep("Genus", 4),
        scale_id = base::c(
          "local_01",
          "local_01",
          "local_01",
          "local_01"
        ),
        component = base::c(
          "Abiotic",
          "Spatial",
          "Associations",
          "Residual"
        ),
        continent_id = base::rep("europe", 4),
        component_total_percentage = base::c(50, 40, 10, 5)
      )

    vec_component_colours <-
      base::c(
        "Abiotic" = "#D95F02",
        "Spatial" = "#7570B3",
        "Associations" = "#1B9E77"
      )

    testthat::expect_error(
      prepare_spatial_variance_waffle_data(
        data_plot = data_plot,
        vec_component_colours = vec_component_colours,
        vec_required_components = base::c(
          "Abiotic",
          "Spatial",
          "Residual"
        ),
        anchor_component = "Residual"
      ),
      regexp = "Missing component colours"
    )
  }
)

testthat::test_that(
  "custom required component set works without Associations rows",
  {
    data_plot <-
      tibble::tibble(
        scale = base::factor(base::rep("local", 6)),
        resolution_label = base::rep("Genus", 6),
        scale_id = base::c(
          "local_01",
          "local_01",
          "local_01",
          "local_02",
          "local_02",
          "local_02"
        ),
        component = base::c(
          "Abiotic",
          "Spatial",
          "Residual",
          "Abiotic",
          "Spatial",
          "Residual"
        ),
        continent_id = base::c(
          "europe",
          "europe",
          "europe",
          "asia",
          "asia",
          "asia"
        ),
        component_total_percentage = base::c(50, 35, 15, 20, 40, 40)
      )

    res_data <-
      prepare_spatial_variance_waffle_data(
        data_plot = data_plot,
        vec_component_colours = base::c(
          "Abiotic" = "#D95F02",
          "Spatial" = "#7570B3",
          "Residual" = "#1B9E77"
        ),
        vec_required_components = base::c(
          "Abiotic",
          "Spatial",
          "Residual"
        ),
        anchor_component = "Residual"
      )

    testthat::expect_equal(base::nrow(res_data), 2L)
    testthat::expect_true(
      "tile_fill_colour" %in% base::colnames(res_data)
    )
  }
)
