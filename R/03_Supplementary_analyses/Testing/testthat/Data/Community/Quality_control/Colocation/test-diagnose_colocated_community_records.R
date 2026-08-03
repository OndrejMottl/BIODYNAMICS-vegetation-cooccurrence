testthat::test_that(
  "diagnose_colocated_community_records() returns zero rows without colocations",
  {
    data_community <-
      tibble::tibble(
        dataset_name = c("bien_a", "splot_a"),
        sample_name = c("s1", "s1"),
        age = c(0, 0),
        taxon = c("Abies", "Abies"),
        pollen_count = c(10, 11)
      )

    data_coordinates <-
      tibble::tibble(
        dataset_name = c("bien_a", "splot_a"),
        coord_long = c(10, 11),
        coord_lat = c(50, 51)
      )

    res_colocation_diagnostics <-
      diagnose_colocated_community_records(
        data_community = data_community,
        data_coordinates = data_coordinates
      )

    testthat::expect_s3_class(res_colocation_diagnostics, "tbl_df")
    testthat::expect_equal(base::nrow(res_colocation_diagnostics), 0L)
  }
)


testthat::test_that(
  "diagnose_colocated_community_records() reports same-prefix and cross-db flags",
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

    data_coordinates <-
      tibble::tibble(
        dataset_name = c("bien_a", "bien_b", "bien_c", "splot_c"),
        coord_long = c(10, 10, 12, 12),
        coord_lat = c(50, 50, 52, 52)
      )

    res_colocation_diagnostics <-
      diagnose_colocated_community_records(
        data_community = data_community,
        data_coordinates = data_coordinates
      )

    data_community_same_prefix <-
      res_colocation_diagnostics |>
      dplyr::filter(coord_long == 10, coord_lat == 50, age == 0)

    testthat::expect_true(
      dplyr::pull(data_community_same_prefix, flag_same_prefix_eligible)
    )

    data_community_cross_database <-
      res_colocation_diagnostics |>
      dplyr::filter(coord_long == 12, coord_lat == 52, age == 0)

    testthat::expect_true(
      dplyr::pull(
        data_community_cross_database,
        flag_cross_database_bien_splot
      )
    )
    testthat::expect_true(
      dplyr::pull(
        data_community_cross_database,
        flag_community_signatures_differ
      )
    )
  }
)


testthat::test_that(
  "diagnose_colocated_community_records() aborts on missing coordinates",
  {
    data_community <-
      tibble::tibble(
        dataset_name = "bien_a",
        sample_name = "s1",
        age = 0,
        taxon = "Abies",
        pollen_count = 10
      )

    data_coordinates <-
      tibble::tibble(
        dataset_name = "bien_other",
        coord_long = 10,
        coord_lat = 50
      )

    testthat::expect_error(
      diagnose_colocated_community_records(
        data_community = data_community,
        data_coordinates = data_coordinates
      ),
      regexp = "Missing coordinates"
    )
  }
)
