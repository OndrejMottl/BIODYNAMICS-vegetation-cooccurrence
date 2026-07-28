testthat::test_that(
  "aggregate_colocated_community_records() validates required abiotic columns",
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
        dataset_name = "bien_a",
        coord_long = 10,
        coord_lat = 50
      )

    data_abiotic <-
      tibble::tibble(dataset_name = "bien_a")

    testthat::expect_error(
      aggregate_colocated_community_records(
        data_source = data_community,
        data_coordinates = data_coords,
        data_abiotic_long = data_abiotic
      ),
      regexp = "abiotic_variable_name"
    )
  }
)


testthat::test_that(
  "aggregate_colocated_community_records() leaves data unchanged when no coloc",
  {
    data_community <-
      tibble::tibble(
        dataset_name = c("bien_a", "splot_a"),
        sample_name = c("s1", "s1"),
        age = c(0, 0),
        taxon = c("Abies", "Abies"),
        pollen_count = c(10, 20)
      )

    data_coords <-
      tibble::tibble(
        dataset_name = c("bien_a", "splot_a"),
        coord_long = c(10, 11),
        coord_lat = c(50, 51)
      ) |>
      tibble::column_to_rownames("dataset_name")

    data_abiotic <-
      tibble::tibble(
        dataset_name = c("bien_a", "splot_a"),
        age = c(0, 0),
        abiotic_variable_name = c("temp", "temp"),
        abiotic_value = c(1, 2)
      )

    res <-
      aggregate_colocated_community_records(
        data_source = data_community,
        data_coordinates = data_coords,
        data_abiotic_long = data_abiotic
      )

    testthat::expect_equal(
      purrr::pluck(res, "data_community_analysis"),
      data_community
    )
    testthat::expect_equal(
      purrr::pluck(res, "data_abiotic_analysis"),
      data_abiotic
    )
    testthat::expect_equal(
      base::nrow(purrr::pluck(res, "data_aggregation_map")),
      0L
    )
  }
)


testthat::test_that(
  "aggregate_colocated_community_records() aggregates same-prefix colocations",
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
        pollen_count = c(10, 20, 30, NA_real_, 5, 6, 50, 60)
      )

    data_coords <-
      tibble::tibble(
        dataset_name = c("bien_a", "bien_b", "bien_c", "splot_c"),
        coord_long = c(10, 10, 12, 12),
        coord_lat = c(50, 50, 52, 52)
      ) |>
      tibble::column_to_rownames("dataset_name")

    data_abiotic <-
      tibble::tibble(
        dataset_name = c("bien_a", "bien_a", "bien_b", "bien_b", "bien_c", "splot_c"),
        age = c(0, 0, 0, 0, 0, 0),
        abiotic_variable_name = c("temp", "prec", "temp", "prec", "temp", "temp"),
        abiotic_value = c(1, 11, 3, NA_real_, 8, 9)
      )

    res <-
      aggregate_colocated_community_records(
        data_source = data_community,
        data_coordinates = data_coords,
        data_abiotic_long = data_abiotic
      )

    data_map <-
      purrr::pluck(res, "data_aggregation_map")

    testthat::expect_equal(
      base::unique(dplyr::pull(data_map, synthetic_dataset_name)),
      "bien_agg_000001"
    )

    data_community_analysis <-
      purrr::pluck(res, "data_community_analysis")

    data_bien_agg <-
      data_community_analysis |>
      dplyr::filter(dataset_name == "bien_agg_000001") |>
      dplyr::arrange(taxon)

    testthat::expect_equal(
      dplyr::pull(data_bien_agg, pollen_count),
      c(20, 20)
    )

    data_abiotic_analysis <-
      purrr::pluck(res, "data_abiotic_analysis") |>
      dplyr::filter(dataset_name == "bien_agg_000001") |>
      dplyr::arrange(abiotic_variable_name)

    testthat::expect_equal(
      dplyr::pull(data_abiotic_analysis, abiotic_value),
      c(11, 2)
    )

    data_coords_analysis <-
      purrr::pluck(res, "data_coords_analysis") |>
      tibble::rownames_to_column("dataset_name")

    testthat::expect_true(
      "bien_agg_000001" %in% dplyr::pull(data_coords_analysis, dataset_name)
    )

    data_cross <-
      purrr::pluck(res, "data_cross_database_colocations")

    testthat::expect_equal(base::nrow(data_cross), 1L)

    testthat::expect_true(
      base::all(
        c("bien_c", "splot_c") %in%
          dplyr::pull(data_community_analysis, dataset_name)
      )
    )
  }
)
