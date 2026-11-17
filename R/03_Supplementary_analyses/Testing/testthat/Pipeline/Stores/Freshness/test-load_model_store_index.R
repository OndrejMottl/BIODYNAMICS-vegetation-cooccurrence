write_test_store_index_inputs <- function() {
  dir_root <-
    base::tempfile(pattern = "store-index-")
  base::dir.create(dir_root)

  file_config <-
    base::file.path(dir_root, "config.yml")
  base::writeLines(
    text = base::c(
      "default:",
      "  target_store: default",
      "  _profile:",
      "    role: base",
      "    status: active",
      "    pipeline: ~",
      "project_spatial:",
      "  target_store: Data/targets/paleo_spatial_local",
      "  _profile:",
      "    role: main",
      "    status: active",
      "    pipeline: paleo_spatial",
      "project_temporal:",
      "  target_store: Data/targets/paleo_temporal_europe",
      "  _profile:",
      "    role: main",
      "    status: active",
      "    pipeline: paleo_temporal",
      "project_reference:",
      "  target_store: Data/targets/reference",
      "  _profile:",
      "    role: reference",
      "    status: active",
      "    pipeline: paleo_spatial"
    ),
    con = file_config
  )

  file_grid <-
    base::file.path(dir_root, "spatial_grid.csv")
  readr::write_csv(
    x = tibble::tibble(
      scale_id = base::c("eu_r001_l001", "eu_r001", "europe"),
      scale = base::c("local", "regional", "continental")
    ),
    file = file_grid
  )

  base::dir.create(
    base::file.path(
      dir_root,
      "Data/targets/paleo_temporal_europe/pipeline_paleo_temporal"
    ),
    recursive = TRUE
  )

  return(
    base::list(
      dir_root = dir_root,
      file_config = file_config,
      file_grid = file_grid
    )
  )
}

testthat::test_that(
  "load_model_store_index() lists main active model stores",
  {
    list_inputs <-
      write_test_store_index_inputs()

    res <-
      load_model_store_index(
        path_store_root = list_inputs[["dir_root"]],
        file_config = list_inputs[["file_config"]],
        path_spatial_grid = list_inputs[["file_grid"]]
      )

    testthat::expect_setequal(
      res[["profile_id"]],
      base::c("project_spatial", "project_temporal")
    )
    testthat::expect_setequal(
      res[["store_path_relative"]],
      base::c(
        stringr::str_c(
          "Data/targets/paleo_spatial_local/eu_r001_l001/",
          "pipeline_paleo_spatial_resolution"
        ),
        "Data/targets/paleo_spatial_local/pipeline_sjsdm_tier_tuning",
        stringr::str_c(
          "Data/targets/paleo_spatial_local/",
          "pipeline_sjsdm_common_regularization_sensitivity"
        ),
        "Data/targets/paleo_temporal_europe/pipeline_paleo_temporal",
        "Data/targets/paleo_temporal_europe/pipeline_sjsdm_tier_tuning"
      )
    )
    testthat::expect_equal(
      res[["store_exists"]][res[["store_kind"]] == "temporal"],
      TRUE
    )
    testthat::expect_equal(
      res[["scale_id"]][res[["store_kind"]] == "spatial_unit"],
      "eu_r001_l001"
    )
    testthat::expect_equal(
      res[["pipeline_script"]][res[["store_kind"]] == "spatial_unit"],
      "R/Pipelines/pipeline_paleo_spatial_resolution.R"
    )
  }
)

testthat::test_that(
  "load_model_store_index() honours an explicit profile selection",
  {
    list_inputs <-
      write_test_store_index_inputs()

    res <-
      load_model_store_index(
        vec_profile_ids = "project_temporal",
        path_store_root = list_inputs[["dir_root"]],
        file_config = list_inputs[["file_config"]],
        path_spatial_grid = list_inputs[["file_grid"]]
      )

    testthat::expect_setequal(
      res[["store_kind"]],
      base::c("temporal", "tier_tuning")
    )
  }
)

testthat::test_that(
  "load_model_store_index() validates its arguments",
  {
    testthat::expect_error(
      load_model_store_index(vec_profile_ids = character()),
      "vec_profile_ids"
    )
    testthat::expect_error(
      load_model_store_index(file_config = "no_such_config.yml"),
      "file_config"
    )
  }
)
