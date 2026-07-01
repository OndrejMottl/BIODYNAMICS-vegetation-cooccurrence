testthat::test_that(
  "make_cross_validation_location_table() preserves whole locations",
  {
    data_sample_ids <-
      tibble::tibble(
        dataset_name = base::c("core_b", "core_a", "core_b", "core_c"),
        age = base::c(0, 0, 500, 0)
      )

    data_coords_projected <-
      base::data.frame(
        coord_x_km = base::c(10, 20, 30, 40),
        coord_y_km = base::c(50, 60, 70, 80),
        row.names = base::c("core_a", "core_b", "core_c", "unused")
      )

    data_locations <-
      make_cross_validation_location_table(
        data_sample_ids = data_sample_ids,
        data_coords_projected = data_coords_projected
      )

    testthat::expect_s3_class(data_locations, "tbl_df")
    testthat::expect_named(
      data_locations,
      base::c(
        "location_id",
        "coord_x_km",
        "coord_y_km",
        "n_samples",
        "row_indices"
      )
    )
    testthat::expect_equal(
      dplyr::pull(data_locations, location_id),
      base::c("core_b", "core_a", "core_c")
    )
    testthat::expect_equal(
      dplyr::pull(data_locations, coord_x_km),
      base::c(20, 10, 30)
    )
    testthat::expect_equal(
      dplyr::pull(data_locations, n_samples),
      base::c(2L, 1L, 1L)
    )
    testthat::expect_equal(
      dplyr::pull(data_locations, row_indices),
      base::list(base::c(1L, 3L), 2L, 4L)
    )
  }
)

testthat::test_that(
  "make_cross_validation_location_table() supports modern plots",
  {
    data_sample_ids <-
      tibble::tibble(plot_id = base::c("plot_1", "plot_2", "plot_3"))

    data_coords_projected <-
      base::data.frame(
        coord_x_km = base::c(1, 2, 3),
        coord_y_km = base::c(4, 5, 6),
        row.names = dplyr::pull(data_sample_ids, plot_id)
      )

    data_locations <-
      make_cross_validation_location_table(
        data_sample_ids = data_sample_ids,
        data_coords_projected = data_coords_projected,
        location_column = "plot_id"
      )

    testthat::expect_equal(
      dplyr::pull(data_locations, n_samples),
      base::rep(1L, 3L)
    )
    testthat::expect_equal(
      dplyr::pull(data_locations, row_indices),
      base::list(1L, 2L, 3L)
    )
  }
)

testthat::test_that(
  "make_cross_validation_location_table() validates alignment",
  {
    data_sample_ids <-
      tibble::tibble(dataset_name = base::c("core_a", "core_missing"))

    data_coords_projected <-
      base::data.frame(
        coord_x_km = 10,
        coord_y_km = 20,
        row.names = "core_a"
      )

    testthat::expect_error(
      make_cross_validation_location_table(
        data_sample_ids = data_sample_ids,
        data_coords_projected = data_coords_projected
      ),
      "exactly one projected coordinate"
    )

    data_coords_non_finite <-
      base::data.frame(
        coord_x_km = base::c(10, Inf),
        coord_y_km = base::c(20, 30),
        row.names = base::c("core_a", "core_missing")
      )

    testthat::expect_error(
      make_cross_validation_location_table(
        data_sample_ids = data_sample_ids,
        data_coords_projected = data_coords_non_finite
      ),
      "finite projected coordinates"
    )
  }
)

testthat::test_that(
  "make_cross_validation_location_table() validates arguments",
  {
    data_sample_ids <-
      tibble::tibble(dataset_name = "core_a")

    data_coords_projected <-
      base::data.frame(
        coord_x_km = 10,
        coord_y_km = 20,
        row.names = "core_a"
      )

    testthat::expect_error(
      make_cross_validation_location_table(
        data_sample_ids = base::c("core_a"),
        data_coords_projected = data_coords_projected
      ),
      "data_sample_ids"
    )

    testthat::expect_error(
      make_cross_validation_location_table(
        data_sample_ids = data_sample_ids,
        data_coords_projected = data_coords_projected,
        location_column = "missing"
      ),
      "location_column"
    )
  }
)
