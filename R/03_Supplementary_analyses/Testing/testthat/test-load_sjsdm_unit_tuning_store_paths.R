testthat::test_that(
  "load_sjsdm_unit_tuning_store_paths() keeps existing stores",
  {
    path_root <-
      withr::local_tempdir()
    path_store <-
      base::file.path(path_root, "unit")
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

testthat::test_that(
  "load_sjsdm_unit_tuning_store_paths() filters failed units",
  {
    path_root <- withr::local_tempdir()
    vec_stores <-
      base::file.path(
        path_root,
        base::c("unit_a", "unit_b"),
        "pipeline"
      )
    fs::dir_create(vec_stores)

    res <-
      withr::with_envvar(
        new = base::c(SJSMD_TUNING_UNIT_SUFFIXES = "unit_b"),
        code = load_sjsdm_unit_tuning_store_paths(
          list_tuning_context = base::list(
            pipeline_name = "pipeline",
            nested_unit_stores = TRUE
          ),
          target_store = path_root
        )
      )

    testthat::expect_identical(
      fs::path_norm(base::unname(res)),
      fs::path_norm(vec_stores[[2L]])
    )
  }
)
