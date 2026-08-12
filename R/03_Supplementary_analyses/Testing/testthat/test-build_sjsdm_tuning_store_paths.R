testthat::test_that(
  "build_sjsdm_tuning_store_paths() resolves isolated stores",
  {
    res <-
      build_sjsdm_tuning_store_paths(
        unit_pipeline = "R/Pipelines/unit.R",
        unit_store_suffixes = base::c("a", "b"),
        target_store = "targets_root"
      )
    testthat::expect_identical(
      res,
      base::file.path("targets_root", base::c("a", "b"), "unit")
    )
  }
)
