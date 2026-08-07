testthat::test_that(
  "load_config() loads a complete named configuration",
  {
    path_config <-
      withr::local_tempfile(
        fileext = ".yml",
        lines = base::c(
          "default:",
          "  target_store: default",
          "profile_main:",
          "  target_store: profile_store"
        )
      )

    list_config <-
      load_config(
        config_id = "profile_main",
        file = path_config
      )

    testthat::expect_equal(
      list_config[["target_store"]],
      "profile_store"
    )
  }
)

testthat::test_that(
  "load_config() validates its public arguments",
  {
    path_config <-
      withr::local_tempfile(
        fileext = ".yml",
        lines = base::c(
          "default:",
          "  target_store: default"
        )
      )

    testthat::expect_error(
      load_config(
        config_id = "",
        file = path_config
      ),
      regexp = "config_id"
    )
    testthat::expect_error(
      load_config(
        config_id = "default",
        file = base::tempfile(fileext = ".yml")
      ),
      regexp = "readable YAML"
    )
  }
)
