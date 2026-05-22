testthat::test_that(
  "detect_colocated_community_records() returns zero rows without colocations",
  {
    data_community <-
      tibble::tibble(
        dataset_name = c("bien_a", "splot_a"),
        sample_name = c("s1", "s1"),
        age = c(0, 0),
        taxon = c("Abies", "Abies"),
        pollen_count = c(10, 11)
      )

    data_coords <-
      tibble::tibble(
        dataset_name = c("bien_a", "splot_a"),
        coord_long = c(10, 11),
        coord_lat = c(50, 51)
      )

    res <-
      detect_colocated_community_records(
        data_source = data_community,
        data_coordinates = data_coords
      )

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(base::nrow(res), 0L)
  }
)


testthat::test_that(
  "detect_colocated_community_records() reports same-prefix and cross-db flags",
  {
    data_community <-
      tibble::tibble(
        dataset_name = c(
          "bien_a",
          "bien_a",
          "bien_b",
          "bien_b",
          "bien_c",
          "bien_c",
          "splot_c",
          "splot_c"
        ),
        sample_name = c("s1", "s1", "s1", "s1", "s1", "s1", "s1", "s1"),
        age = 0,
        taxon = c(
          "Abies",
          "Betula",
          "Abies",
          "Betula",
          "Abies",
          "Betula",
          "Abies",
          "Betula"
        ),
        pollen_count = c(10, 20, 15, 25, 5, 6, 30, 40)
      )

    data_coords <-
      tibble::tibble(
        dataset_name = c("bien_a", "bien_b", "bien_c", "splot_c"),
        coord_long = c(10, 10, 12, 12),
        coord_lat = c(50, 50, 52, 52)
      )

    res <-
      detect_colocated_community_records(
        data_source = data_community,
        data_coordinates = data_coords
      )

    data_same_prefix <-
      res |>
      dplyr::filter(coord_long == 10, coord_lat == 50, age == 0)

    testthat::expect_true(
      dplyr::pull(data_same_prefix, flag_same_prefix_eligible)
    )

    data_cross_database <-
      res |>
      dplyr::filter(coord_long == 12, coord_lat == 52, age == 0)

    testthat::expect_true(
      dplyr::pull(data_cross_database, flag_cross_database_bien_splot)
    )
    testthat::expect_true(
      dplyr::pull(data_cross_database, flag_community_signatures_differ)
    )
  }
)


testthat::test_that(
  "detect_colocated_community_records() aborts on missing coordinates",
  {
    data_community <-
      tibble::tibble(
        dataset_name = "bien_a",
        sample_name = "s1",
        age = 0,
        taxon = "Abies",
        pollen_count = 10
      )

    data_coords <-
      tibble::tibble(
        dataset_name = "bien_other",
        coord_long = 10,
        coord_lat = 50
      )

    testthat::expect_error(
      detect_colocated_community_records(
        data_source = data_community,
        data_coordinates = data_coords
      ),
      regexp = "Missing coordinates"
    )
  }
)
