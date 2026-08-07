testthat::test_that(
  "build_schematic_node_box() returns one-row geometry tibble",
  {
    res <-
      build_schematic_node_box(
        id = "a",
        label = "A",
        x = 10,
        y = 20,
        width = 4,
        height = 6,
        colour = "#ffffff"
      )

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_identical(base::nrow(res), 1L)
    testthat::expect_equal(dplyr::pull(res, xmin), 8)
    testthat::expect_equal(dplyr::pull(res, xmax), 12)
    testthat::expect_equal(dplyr::pull(res, ymin), 17)
    testthat::expect_equal(dplyr::pull(res, ymax), 23)
  }
)

testthat::test_that(
  "build_schematic_node_box() validates positive width and height",
  {
    testthat::expect_error(
      build_schematic_node_box(
        id = "a",
        label = "A",
        x = 10,
        y = 20,
        width = 0,
        height = 6,
        colour = "#ffffff"
      ),
      regexp = "positive"
    )
  }
)
