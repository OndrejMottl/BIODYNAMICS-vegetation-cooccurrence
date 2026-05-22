write_test_spatial_grid <- function(path) {
  readr::write_csv(
    x = tibble::tibble(
      scale = c("continental", "regional", "local"),
      scale_id = c("europe", "eu_r001", "eu_r001_l001")
    ),
    file = path
  )
}

testthat::test_that(
  "build_spatial_model_store_index builds expected store paths",
  {
    path_grid <-
      base::tempfile(fileext = ".csv")
    write_test_spatial_grid(path_grid)

    res <-
      build_spatial_model_store_index(
        data_source = "modern",
        scales = c("continental", "regional"),
        path_spatial_grid = path_grid
      )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_named(
      res,
      c(
        "data_source",
        "scale",
        "scale_id",
        "pipeline_name",
        "store_path",
        "store_exists"
      )
    )
    testthat::expect_true(
      base::all(res$data_source == "modern")
    )
    testthat::expect_true(
      base::all(res$pipeline_name == "pipeline_modern_spatial_resolution")
    )
    testthat::expect_true(
      base::all(stringr::str_detect(res$store_path, "modern_spatial_"))
    )
  }
)
