testthat::test_that(
  "resolve_pipeline_store_path() preserves the pipeline store layout",
  {
    testthat::expect_equal(
      resolve_pipeline_store_path(
        pipeline_script = "R/Pipelines/pipeline_paleo_core.R",
        target_store = "Data/targets/cz_paleo"
      ),
      here::here("Data/targets/cz_paleo", "pipeline_paleo_core")
    )

    testthat::expect_equal(
      resolve_pipeline_store_path(
        pipeline_script =
          "R/Pipelines/pipeline_paleo_spatial_resolution.R",
        target_store = "Data/targets/paleo_spatial_continental",
        store_suffix = "europe"
      ),
      here::here(
        "Data/targets/paleo_spatial_continental",
        "europe",
        "pipeline_paleo_spatial_resolution"
      )
    )
  }
)

testthat::test_that(
  "resolve_pipeline_store_path() validates its path components",
  {
    testthat::expect_error(
      resolve_pipeline_store_path(
        pipeline_script = "pipeline.R",
        target_store = "targets",
        store_suffix = ""
      ),
      "store_suffix"
    )
  }
)
