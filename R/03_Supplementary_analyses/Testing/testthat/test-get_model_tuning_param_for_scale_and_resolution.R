write_scalar_model_config <- function(path,
                                      include_model_tuning_id = TRUE) {
  model_tuning_line <-
    if (
      include_model_tuning_id
    ) {
      "    model_tuning_id: paleo_spatial\n"
    } else {
      ""
    }

  writeLines(
    text = c(
      "default:",
      "  data_processing:",
      "    taxonomic_resolution: genus",
      "  model_fitting:",
      model_tuning_line,
      "    n_iter: 400",
      "    n_step_size: null",
      "    n_sampling: 100",
      "    n_samples_anova: 500",
      "    n_early_stopping: null"
    ),
    con = path
  )
}

write_scalar_tuning_file <- function(dir) {
  readr::write_csv(
    x = tibble::tibble(
      scale_id = c("europe", "eu_r001"),
      n_iter = c(400L, 1600L),
      n_step_size = c(NA_integer_, 32L),
      n_sampling = c(100L, 250L),
      n_samples_anova = c(500L, 500L),
      n_early_stopping = c(NA_integer_, 0L)
    ),
    file = base::file.path(
      dir,
      "model_tuning_paleo_spatial_genus.csv"
    )
  )
}

testthat::test_that(
  "get_model_tuning_param_for_scale_and_resolution returns one spatial value",
  {
    temp_dir <- withr::local_tempdir()
    path_config <- base::file.path(temp_dir, "config.yml")
    write_scalar_model_config(path_config)
    write_scalar_tuning_file(temp_dir)

    withr::local_envvar(R_CONFIG_ACTIVE = "default")

    res <-
      get_model_tuning_param_for_scale_and_resolution(
        param_id = "n_iter",
        scale_id = "eu_r001",
        config_file = path_config,
        dir = temp_dir
      )

    testthat::expect_equal(res, 1600L)
  }
)

testthat::test_that(
  "get_model_tuning_param_for_scale_and_resolution preserves optional NULL",
  {
    temp_dir <- withr::local_tempdir()
    path_config <- base::file.path(temp_dir, "config.yml")
    write_scalar_model_config(path_config)
    write_scalar_tuning_file(temp_dir)

    withr::local_envvar(R_CONFIG_ACTIVE = "default")

    res <-
      get_model_tuning_param_for_scale_and_resolution(
        param_id = "n_step_size",
        scale_id = "europe",
        config_file = path_config,
        dir = temp_dir
      )

    testthat::expect_null(res)
  }
)

testthat::test_that(
  "get_model_tuning_param_for_scale_and_resolution falls back to config",
  {
    temp_dir <- withr::local_tempdir()
    path_config <- base::file.path(temp_dir, "config.yml")
    write_scalar_model_config(
      path = path_config,
      include_model_tuning_id = FALSE
    )

    withr::local_envvar(R_CONFIG_ACTIVE = "default")

    res <-
      get_model_tuning_param_for_scale_and_resolution(
        param_id = "n_sampling",
        scale_id = NULL,
        config_file = path_config,
        dir = temp_dir
      )

    testthat::expect_equal(res, 100L)
  }
)

testthat::test_that(
  "get_model_tuning_param_for_scale_and_resolution errors on unknown param",
  {
    temp_dir <- withr::local_tempdir()
    path_config <- base::file.path(temp_dir, "config.yml")
    write_scalar_model_config(path_config)

    withr::local_envvar(R_CONFIG_ACTIVE = "default")

    testthat::expect_error(
      get_model_tuning_param_for_scale_and_resolution(
        param_id = "n_unknown",
        scale_id = NULL,
        config_file = path_config,
        dir = temp_dir
      ),
      regexp = "param_id"
    )
  }
)
