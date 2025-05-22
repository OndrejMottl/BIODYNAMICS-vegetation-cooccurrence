testthat::test_that("check_and_prepare_data_for_fit() returns correct class", {
  data_community_example <-
    data.frame(
      row_name = c("dataset1__500", "dataset2__1000", "dataset3__1500"),
      species1 = c(1, 2, 3),
      species2 = c(4, 5, 6)
    ) %>%
    tibble::column_to_rownames("row_name")

  data_abiotic_example <-
    data.frame(
      row_name = c("dataset0__0", "dataset1__500", "dataset2__1000"),
      abiotic1 = c(5, 6, 7),
      abiotic2 = c(8, 9, 10)
    ) %>%
    tibble::column_to_rownames("row_name")

  data_coords_example <-
    data.frame(
      row_name = c("dataset0", "dataset1", "dataset2", "dataset3"),
      coord_long = c(9, 10, 11, 12),
      coord_lat = c(12, 13, 14, 15)
    ) %>%
    tibble::column_to_rownames("row_name")

  result <-
    check_and_prepare_data_for_fit(
      data_community = data_community_example,
      data_abiotic = data_abiotic_example,
      data_coords = data_coords_example
    )

  testthat::expect_equal(class(result), "list")
})

testthat::test_that("check_and_prepare_data_for_fit() returns correct data", {
  data_community_example <-
    data.frame(
      row_name = c("dataset1__500", "dataset2__1000", "dataset3__1500"),
      species1 = c(1, 2, 3),
      species2 = c(4, 5, 6)
    ) %>%
    tibble::column_to_rownames("row_name")

  data_abiotic_example <-
    data.frame(
      row_name = c("dataset0__0", "dataset1__500", "dataset2__1000"),
      abiotic1 = c(5, 6, 7),
      abiotic2 = c(8, 9, 10)
    ) %>%
    tibble::column_to_rownames("row_name")

  data_coords_example <-
    data.frame(
      row_name = c("dataset0", "dataset1", "dataset2", "dataset3"),
      coord_long = c(9, 10, 11, 12),
      coord_lat = c(12, 13, 14, 15)
    ) %>%
    tibble::column_to_rownames("row_name")

  result <-
    check_and_prepare_data_for_fit(
      data_community = data_community_example,
      data_abiotic = data_abiotic_example,
      data_coords = data_coords_example
    )

  expected_result <-
    list(
      data_community_to_fit = data.frame(
        row_name = c("dataset1__500", "dataset2__1000"),
        species1 = c(1, 2),
        species2 = c(4, 5)
      ) %>%
        tibble::column_to_rownames("row_name"),
      data_abiotic_to_fit = data.frame(
        row_name = c("dataset1__500", "dataset2__1000"),
        abiotic1 = c(6, 7),
        abiotic2 = c(9, 10)
      ) %>%
        tibble::column_to_rownames("row_name"),
      data_ages_to_fit = data.frame(
        row_name = c("500", "1000"),
        age = c(500, 1000)
      ) %>%
        tibble::column_to_rownames("row_name"),
      data_coords_to_fit = data.frame(
        row_name = c("dataset1", "dataset2"),
        coord_long = c(10, 11),
        coord_lat = c(13, 14)
      ) %>%
        tibble::column_to_rownames("row_name")
    )

  testthat::expect_equal(result, expected_result)
})


testthat::test_that("check_and_prepare_data_for_fit() subset ages", {
  data_community_example <-
    data.frame(
      row_name = c("dataset1__500", "dataset2__1000", "dataset3__1500"),
      species1 = c(1, 2, 3),
      species2 = c(4, 5, 6)
    ) %>%
    tibble::column_to_rownames("row_name")

  data_abiotic_example <-
    data.frame(
      row_name = c("dataset0__0", "dataset1__500", "dataset2__1000"),
      abiotic1 = c(5, 6, 7),
      abiotic2 = c(8, 9, 10)
    ) %>%
    tibble::column_to_rownames("row_name")

  data_coords_example <-
    data.frame(
      row_name = c("dataset0", "dataset1", "dataset2", "dataset3"),
      coord_long = c(9, 10, 11, 12),
      coord_lat = c(12, 13, 14, 15)
    ) %>%
    tibble::column_to_rownames("row_name")

  result <-
    check_and_prepare_data_for_fit(
      data_community = data_community_example,
      data_abiotic = data_abiotic_example,
      data_coords = data_coords_example,
      subset_age = 500
    )

  expected_result <-
    list(
      data_community_to_fit = data.frame(
        row_name = c("dataset1__500"),
        species1 = c(1),
        species2 = c(4)
      ) %>%
        tibble::column_to_rownames("row_name"),
      data_abiotic_to_fit = data.frame(
        row_name = c("dataset1__500"),
        abiotic1 = c(6),
        abiotic2 = c(9)
      ) %>%
        tibble::column_to_rownames("row_name"),
      data_ages_to_fit = data.frame(
        row_name = c("500"),
        age = c(500)
      ) %>%
        tibble::column_to_rownames("row_name"),
      data_coords_to_fit = data.frame(
        row_name = c("dataset1"),
        coord_long = c(10),
        coord_lat = c(13)
      ) %>%
        tibble::column_to_rownames("row_name")
    )

  testthat::expect_equal(result, expected_result)
})

testthat::test_that("check_and_prepare_data_for_fit() handles invalid input", {
  data_community_example <-
    data.frame(
      row_name = c("dataset1__500", "dataset2__1000", "dataset3__1500"),
      species1 = c(1, 2, 3),
      species2 = c(4, 5, 6)
    ) %>%
    tibble::column_to_rownames("row_name")

  data_abiotic_example <-
    data.frame(
      row_name = c("dataset0__0", "dataset1__500", "dataset2__1000"),
      abiotic1 = c(5, 6, 7),
      abiotic2 = c(8, 9, 10)
    ) %>%
    tibble::column_to_rownames("row_name")

  data_coords_example <-
    data.frame(
      row_name = c("dataset0", "dataset1", "dataset2", "dataset3"),
      coord_long = c(9, 10, 11, 12),
      coord_lat = c(12, 13, 14, 15)
    ) %>%
    tibble::column_to_rownames("row_name")


  testthat::expect_error(
    check_and_prepare_data_for_fit(
      data_community = NULL,
      data_abiotic = data_abiotic_example,
      data_coords = data_coords_example
    )
  )

  testthat::expect_error(
    check_and_prepare_data_for_fit(
      data_community = 123,
      data_abiotic = data_abiotic_example,
      data_coords = data_coords_example
    )
  )

  testthat::expect_error(
    check_and_prepare_data_for_fit(
      data_community = "invalid",
      data_abiotic = data_abiotic_example,
      data_coords = data_coords_example
    )
  )

  testthat::expect_error(
    check_and_prepare_data_for_fit(
      data_community = data_community_example,
      data_abiotic = NULL,
      data_coords = data_coords_example
    )
  )

  testthat::expect_error(
    check_and_prepare_data_for_fit(
      data_community = data_community_example,
      data_abiotic = 123,
      data_coords = data_coords_example
    )
  )

  testthat::expect_error(
    check_and_prepare_data_for_fit(
      data_community = data_community_example,
      data_abiotic = "invalid",
      data_coords = data_coords_example
    )
  )

  testthat::expect_error(
    check_and_prepare_data_for_fit(
      data_community = data_community_example,
      data_abiotic = data_abiotic_example,
      data_coords = NULL
    )
  )

  testthat::expect_error(
    check_and_prepare_data_for_fit(
      data_community = data_community_example,
      data_abiotic = data_abiotic_example,
      data_coords = 123
    )
  )

  testthat::expect_error(
    check_and_prepare_data_for_fit(
      data_community = data_community_example,
      data_abiotic = data_abiotic_example,
      data_coords = "invalid"
    )
  )

  testthat::expect_error(
    check_and_prepare_data_for_fit(
      data_community = data_community_example,
      data_abiotic = data_abiotic_example,
      data_coords = data_coords_example,
      subset_age = "invalid"
    )
  )
})
