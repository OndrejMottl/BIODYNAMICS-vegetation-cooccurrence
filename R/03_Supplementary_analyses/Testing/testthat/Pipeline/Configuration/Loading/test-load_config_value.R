testthat::test_that(
  "load_config_value() loads a nested named configuration value",
  {
    path_config <-
      withr::local_tempfile(
        fileext = ".yml",
        lines = base::c(
          "default:",
          "  target_store: default",
          "profile_main:",
          "  nested:",
          "    target_store: profile_store"
        )
      )

    target_store <-
      load_config_value(
        config_id = "profile_main",
        value = base::c("nested", "target_store"),
        file = path_config
      )

    testthat::expect_equal(
      target_store,
      "profile_store"
    )
  }
)

testthat::test_that(
  "load_config_value() validates its public arguments",
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
      load_config_value(
        config_id = "",
        value = "target_store",
        file = path_config
      ),
      regexp = "config_id"
    )
    testthat::expect_error(
      load_config_value(
        config_id = "default",
        value = base::character(),
        file = path_config
      ),
      regexp = "value"
    )
    testthat::expect_error(
      load_config_value(
        config_id = "default",
        value = "target_store",
        file = base::tempfile(fileext = ".yml")
      ),
      regexp = "readable YAML"
    )
  }
)
