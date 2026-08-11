testthat::test_that(
  "load_sjsdm_unit_tuning_store_paths() keeps existing stores",
  {
    path_root <- withr::local_tempdir()
    path_store <- base::file.path(path_root, "unit")
    fs::dir_create(path_store)
    res <-
      load_sjsdm_unit_tuning_store_paths(
        list_tuning_context = base::list(
          pipeline_name = "unit",
          nested_unit_stores = FALSE
        ),
        target_store = path_root
      )
    testthat::expect_identical(res, path_store)
  }
)
