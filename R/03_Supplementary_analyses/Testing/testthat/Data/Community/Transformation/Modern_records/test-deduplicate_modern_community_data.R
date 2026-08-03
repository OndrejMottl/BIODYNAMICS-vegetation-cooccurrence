testthat::test_that(
  "deduplicate_modern_community_data() validates inputs",
  {
    data_community <- tibble::tibble(dataset_name = "a")
    data_coords <- tibble::tibble(dataset_name = "a")

    testthat::expect_error(
      deduplicate_modern_community_data(
        data_source = data_community,
        data_coordinates = data_coords
      ),
      regexp = "sample_name"
    )
  }
)


testthat::test_that(
  "deduplicate_modern_community_data() returns input without exact dups",
  {
    data_community <- tibble::tibble(
      dataset_name = c("site_a", "site_a", "site_b", "site_b"),
      sample_name = c("s1", "s1", "s1", "s1"),
      age = c(0, 0, 0, 0),
      taxon = c("Abies", "Betula", "Abies", "Betula"),
      pollen_count = c(1, 2, 1, 3)
    )
    data_coords <- tibble::tibble(
      dataset_name = c("site_a", "site_b"),
      coord_long = c(10, 10),
      coord_lat = c(50, 50)
    )

    res <- deduplicate_modern_community_data(
      data_source = data_community,
      data_coordinates = data_coords
    )

    testthat::expect_named(
      res,
      c("data_community", "data_dropped_records")
    )
    testthat::expect_equal(
      purrr::pluck(res, "data_community"),
      data_community
    )
    testthat::expect_equal(
      base::nrow(purrr::pluck(res, "data_dropped_records")),
      0L
    )
  }
)


testthat::test_that(
  "deduplicate_modern_community_data() keeps a single record",
  {
    data_community <- tibble::tibble(
      dataset_name = c("site_a", "site_a"),
      sample_name = c("s1", "s1"),
      age = c(0, 0),
      taxon = c("Abies", "Betula"),
      pollen_count = c(1, 2)
    )
    data_coords <- tibble::tibble(
      dataset_name = "site_a",
      coord_long = 10,
      coord_lat = 50
    )

    res <- deduplicate_modern_community_data(
      data_source = data_community,
      data_coordinates = data_coords
    )

    testthat::expect_equal(
      purrr::pluck(res, "data_community"),
      data_community
    )
    testthat::expect_equal(
      base::nrow(purrr::pluck(res, "data_dropped_records")),
      0L
    )
  }
)


testthat::test_that(
  "deduplicate_modern_community_data() drops exact duplicate records",
  {
    data_community <- tibble::tibble(
      dataset_name = c("site_b", "site_b", "site_a", "site_a", "site_c"),
      sample_name = c("s1", "s1", "s1", "s1", "s1"),
      age = c(0, 0, 0, 0, 0),
      taxon = c("Betula", "Abies", "Abies", "Betula", "Abies"),
      pollen_count = c(2, 1, 1, 2, 5)
    )
    data_coords <- tibble::tibble(
      dataset_name = c("site_a", "site_b", "site_c"),
      coord_long = c(10, 10, 11),
      coord_lat = c(50, 50, 51)
    )

    res <- deduplicate_modern_community_data(
      data_source = data_community,
      data_coordinates = data_coords
    )

    data_kept <- purrr::pluck(res, "data_community")
    data_dropped <- purrr::pluck(res, "data_dropped_records")

    testthat::expect_equal(base::nrow(data_kept), 3L)
    testthat::expect_false(
      "site_b" %in% dplyr::pull(data_kept, dataset_name)
    )
    testthat::expect_equal(
      dplyr::pull(data_dropped, dropped_dataset_name),
      "site_b"
    )
    testthat::expect_equal(
      dplyr::pull(data_dropped, kept_dataset_name),
      "site_a"
    )
  }
)
