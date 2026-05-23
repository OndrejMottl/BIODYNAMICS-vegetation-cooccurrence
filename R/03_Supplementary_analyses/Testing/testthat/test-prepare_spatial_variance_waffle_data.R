testthat::test_that(
  "prepare_spatial_variance_waffle_data() assigns tile positions",
  {
    data_plot <-
      tibble::tibble(
        scale = base::factor(base::rep("local", 3)),
        resolution_label = base::rep("Genus", 3),
        component = base::rep("Associations", 3),
        continent_id = base::c("europe", "asia", "america"),
        R2_Nagelkerke_percentage = base::c(30, 10, 20)
      )

    res_data <-
      prepare_spatial_variance_waffle_data(
        data_plot = data_plot,
        n_waffle_rows = 2L
      )

    testthat::expect_equal(
      dplyr::pull(res_data, R2_Nagelkerke_percentage),
      base::c(10, 20, 30)
    )
    testthat::expect_equal(
      dplyr::pull(res_data, tile_col),
      base::c(1L, 1L, 2L)
    )
    testthat::expect_equal(
      dplyr::pull(res_data, tile_row),
      base::c(1L, 2L, 1L)
    )
    testthat::expect_true("point_colour" %in% base::colnames(res_data))
  }
)

testthat::test_that(
  "prepare_spatial_variance_waffle_data() validates inputs",
  {
    testthat::expect_error(
      prepare_spatial_variance_waffle_data(
        data_plot = tibble::tibble(),
        n_waffle_rows = 5
      ),
      regexp = "n_waffle_rows"
    )
  }
)
