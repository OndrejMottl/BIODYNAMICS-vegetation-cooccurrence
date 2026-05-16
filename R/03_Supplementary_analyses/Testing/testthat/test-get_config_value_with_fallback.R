testthat::test_that(
  "get_config_value_with_fallback() rejects invalid config_section",
  {
    path_temp <-
      base::tempfile(fileext = ".yml")

    active_config_original <-
      base::Sys.getenv("R_CONFIG_ACTIVE", unset = NA_character_)

    base::on.exit(
      expr = {
        if (
          base::is.na(active_config_original)
        ) {
          base::Sys.unsetenv("R_CONFIG_ACTIVE")
        } else {
          base::Sys.setenv(R_CONFIG_ACTIVE = active_config_original)
        }

        base::unlink(path_temp)
      },
      add = TRUE
    )

    yaml::write_yaml(
      x = base::list(
        default = base::list(
          data_processing = base::list(
            min_n_samples = 5
          )
        ),
        project_traits_reference = base::list(
          data_processing = base::list(
            ft_groups_min = 10
          )
        )
      ),
      file = path_temp
    )

    base::Sys.setenv(R_CONFIG_ACTIVE = "default")

    testthat::expect_error(
      get_config_value_with_fallback(
        config_section = base::c("data_processing", "other"),
        config_key = "min_n_samples",
        fallback_config = "project_traits_reference",
        file = path_temp
      ),
      regexp = "config_section"
    )

    testthat::expect_error(
      get_config_value_with_fallback(
        config_section = "",
        config_key = "min_n_samples",
        fallback_config = "project_traits_reference",
        file = path_temp
      ),
      regexp = "config_section"
    )
  }
)

testthat::test_that(
  "get_config_value_with_fallback() rejects invalid config_key",
  {
    path_temp <-
      base::tempfile(fileext = ".yml")

    active_config_original <-
      base::Sys.getenv("R_CONFIG_ACTIVE", unset = NA_character_)

    base::on.exit(
      expr = {
        if (
          base::is.na(active_config_original)
        ) {
          base::Sys.unsetenv("R_CONFIG_ACTIVE")
        } else {
          base::Sys.setenv(R_CONFIG_ACTIVE = active_config_original)
        }

        base::unlink(path_temp)
      },
      add = TRUE
    )

    yaml::write_yaml(
      x = base::list(
        default = base::list(
          data_processing = base::list(
            min_n_samples = 5
          )
        ),
        project_traits_reference = base::list(
          data_processing = base::list(
            ft_groups_min = 10
          )
        )
      ),
      file = path_temp
    )

    base::Sys.setenv(R_CONFIG_ACTIVE = "default")

    testthat::expect_error(
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = base::c("min_n_samples", "min_n_taxa"),
        fallback_config = "project_traits_reference",
        file = path_temp
      ),
      regexp = "config_key"
    )

    testthat::expect_error(
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "",
        fallback_config = "project_traits_reference",
        file = path_temp
      ),
      regexp = "config_key"
    )
  }
)

testthat::test_that(
  "get_config_value_with_fallback() rejects invalid fallback_config",
  {
    path_temp <-
      base::tempfile(fileext = ".yml")

    active_config_original <-
      base::Sys.getenv("R_CONFIG_ACTIVE", unset = NA_character_)

    base::on.exit(
      expr = {
        if (
          base::is.na(active_config_original)
        ) {
          base::Sys.unsetenv("R_CONFIG_ACTIVE")
        } else {
          base::Sys.setenv(R_CONFIG_ACTIVE = active_config_original)
        }

        base::unlink(path_temp)
      },
      add = TRUE
    )

    yaml::write_yaml(
      x = base::list(
        default = base::list(
          data_processing = base::list(
            min_n_samples = 5
          )
        ),
        project_traits_reference = base::list(
          data_processing = base::list(
            ft_groups_min = 10
          )
        )
      ),
      file = path_temp
    )

    base::Sys.setenv(R_CONFIG_ACTIVE = "default")

    testthat::expect_error(
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "min_n_samples",
        fallback_config = base::c("default", "project_traits_reference"),
        file = path_temp
      ),
      regexp = "fallback_config"
    )

    testthat::expect_error(
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "min_n_samples",
        fallback_config = "",
        file = path_temp
      ),
      regexp = "fallback_config"
    )
  }
)

testthat::test_that(
  "get_config_value_with_fallback() rejects unreadable non-YAML files",
  {
    path_missing <-
      base::tempfile(fileext = ".yml")

    path_wrong_ext <-
      base::tempfile(fileext = ".txt")

    active_config_original <-
      base::Sys.getenv("R_CONFIG_ACTIVE", unset = NA_character_)

    base::on.exit(
      expr = {
        if (
          base::is.na(active_config_original)
        ) {
          base::Sys.unsetenv("R_CONFIG_ACTIVE")
        } else {
          base::Sys.setenv(R_CONFIG_ACTIVE = active_config_original)
        }

        base::unlink(path_wrong_ext)
      },
      add = TRUE
    )

    base::writeLines("default: {}", con = path_wrong_ext)
    base::Sys.setenv(R_CONFIG_ACTIVE = "default")

    testthat::expect_error(
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "min_n_samples",
        fallback_config = "project_traits_reference",
        file = path_missing
      ),
      regexp = "file"
    )

    testthat::expect_error(
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "min_n_samples",
        fallback_config = "project_traits_reference",
        file = path_wrong_ext
      ),
      regexp = "file"
    )

    testthat::expect_error(
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "min_n_samples",
        fallback_config = "project_traits_reference",
        file = NA_character_
      ),
      regexp = "file"
    )

    testthat::expect_error(
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "min_n_samples",
        fallback_config = "project_traits_reference",
        file = 1
      ),
      regexp = "file"
    )
  }
)

testthat::test_that(
  "get_config_value_with_fallback() reads active config values",
  {
    path_temp <-
      base::tempfile(fileext = ".yml")

    active_config_original <-
      base::Sys.getenv("R_CONFIG_ACTIVE", unset = NA_character_)

    base::on.exit(
      expr = {
        if (
          base::is.na(active_config_original)
        ) {
          base::Sys.unsetenv("R_CONFIG_ACTIVE")
        } else {
          base::Sys.setenv(R_CONFIG_ACTIVE = active_config_original)
        }

        base::unlink(path_temp)
      },
      add = TRUE
    )

    yaml::write_yaml(
      x = base::list(
        default = base::list(
          data_processing = base::list(
            min_n_samples = 5
          )
        ),
        project_cz_paleo = base::list(
          data_processing = base::list(
            min_n_samples = 10
          )
        ),
        project_traits_reference = base::list(
          data_processing = base::list(
            ft_groups_min = 10
          )
        )
      ),
      file = path_temp
    )

    base::Sys.setenv(R_CONFIG_ACTIVE = "project_cz_paleo")

    value_config <-
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "min_n_samples",
        fallback_config = "default",
        file = path_temp
      )

    testthat::expect_true(base::is.numeric(value_config))
    testthat::expect_equal(value_config, 10)
  }
)

testthat::test_that(
  "get_config_value_with_fallback() uses default when active is unset",
  {
    path_temp <-
      base::tempfile(fileext = ".yml")

    active_config_original <-
      base::Sys.getenv("R_CONFIG_ACTIVE", unset = NA_character_)

    base::on.exit(
      expr = {
        if (
          base::is.na(active_config_original)
        ) {
          base::Sys.unsetenv("R_CONFIG_ACTIVE")
        } else {
          base::Sys.setenv(R_CONFIG_ACTIVE = active_config_original)
        }

        base::unlink(path_temp)
      },
      add = TRUE
    )

    yaml::write_yaml(
      x = base::list(
        default = base::list(
          data_processing = base::list(
            min_n_samples = 5
          )
        ),
        project_traits_reference = base::list(
          data_processing = base::list(
            ft_groups_min = 10
          )
        )
      ),
      file = path_temp
    )

    base::Sys.unsetenv("R_CONFIG_ACTIVE")

    value_config <-
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "min_n_samples",
        fallback_config = "project_traits_reference",
        file = path_temp
      )

    testthat::expect_equal(value_config, 5)
  }
)

testthat::test_that(
  "get_config_value_with_fallback() uses the named fallback config",
  {
    path_temp <-
      base::tempfile(fileext = ".yml")

    active_config_original <-
      base::Sys.getenv("R_CONFIG_ACTIVE", unset = NA_character_)

    base::on.exit(
      expr = {
        if (
          base::is.na(active_config_original)
        ) {
          base::Sys.unsetenv("R_CONFIG_ACTIVE")
        } else {
          base::Sys.setenv(R_CONFIG_ACTIVE = active_config_original)
        }

        base::unlink(path_temp)
      },
      add = TRUE
    )

    yaml::write_yaml(
      x = base::list(
        default = base::list(
          data_processing = base::list(
            min_n_samples = 5
          )
        ),
        project_cz_paleo = base::list(
          data_processing = base::list(
            min_n_samples = 10
          )
        ),
        project_traits_reference = base::list(
          data_processing = base::list(
            ft_groups_min = 12,
            ft_method = "ward.D2"
          )
        )
      ),
      file = path_temp
    )

    base::Sys.setenv(R_CONFIG_ACTIVE = "project_cz_paleo")

    value_groups <-
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "ft_groups_min",
        fallback_config = "project_traits_reference",
        file = path_temp
      )

    value_method <-
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "ft_method",
        fallback_config = "project_traits_reference",
        file = path_temp
      )

    testthat::expect_equal(value_groups, 12)
    testthat::expect_equal(value_method, "ward.D2")
  }
)

testthat::test_that(
  "get_config_value_with_fallback() prefers fallback over default",
  {
    path_temp <-
      base::tempfile(fileext = ".yml")

    active_config_original <-
      base::Sys.getenv("R_CONFIG_ACTIVE", unset = NA_character_)

    base::on.exit(
      expr = {
        if (
          base::is.na(active_config_original)
        ) {
          base::Sys.unsetenv("R_CONFIG_ACTIVE")
        } else {
          base::Sys.setenv(R_CONFIG_ACTIVE = active_config_original)
        }

        base::unlink(path_temp)
      },
      add = TRUE
    )

    yaml::write_yaml(
      x = base::list(
        default = base::list(
          data_processing = base::list(
            ft_groups_min = 3
          )
        ),
        project_cz_paleo = base::list(
          data_processing = base::list(
            min_n_samples = 10
          )
        ),
        project_traits_reference = base::list(
          data_processing = base::list(
            ft_groups_min = 12
          )
        )
      ),
      file = path_temp
    )

    base::Sys.setenv(R_CONFIG_ACTIVE = "project_cz_paleo")

    value_config <-
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "ft_groups_min",
        fallback_config = "project_traits_reference",
        file = path_temp
      )

    testthat::expect_equal(value_config, 12)
  }
)

testthat::test_that(
  "get_config_value_with_fallback() prefers active over fallback",
  {
    path_temp <-
      base::tempfile(fileext = ".yml")

    active_config_original <-
      base::Sys.getenv("R_CONFIG_ACTIVE", unset = NA_character_)

    base::on.exit(
      expr = {
        if (
          base::is.na(active_config_original)
        ) {
          base::Sys.unsetenv("R_CONFIG_ACTIVE")
        } else {
          base::Sys.setenv(R_CONFIG_ACTIVE = active_config_original)
        }

        base::unlink(path_temp)
      },
      add = TRUE
    )

    yaml::write_yaml(
      x = base::list(
        default = base::list(
          data_processing = base::list(
            ft_groups_min = 3
          )
        ),
        project_cz_paleo = base::list(
          data_processing = base::list(
            ft_groups_min = 8
          )
        ),
        project_traits_reference = base::list(
          data_processing = base::list(
            ft_groups_min = 12
          )
        )
      ),
      file = path_temp
    )

    base::Sys.setenv(R_CONFIG_ACTIVE = "project_cz_paleo")

    value_config <-
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "ft_groups_min",
        fallback_config = "project_traits_reference",
        file = path_temp
      )

    testthat::expect_equal(value_config, 8)
  }
)

testthat::test_that(
  "get_config_value_with_fallback() errors when key is missing",
  {
    path_temp <-
      base::tempfile(fileext = ".yml")

    active_config_original <-
      base::Sys.getenv("R_CONFIG_ACTIVE", unset = NA_character_)

    base::on.exit(
      expr = {
        if (
          base::is.na(active_config_original)
        ) {
          base::Sys.unsetenv("R_CONFIG_ACTIVE")
        } else {
          base::Sys.setenv(R_CONFIG_ACTIVE = active_config_original)
        }

        base::unlink(path_temp)
      },
      add = TRUE
    )

    yaml::write_yaml(
      x = base::list(
        default = base::list(
          data_processing = base::list(
            min_n_samples = 5
          )
        ),
        project_cz_paleo = base::list(
          data_processing = base::list(
            min_n_taxa = 10
          )
        ),
        project_traits_reference = base::list(
          data_processing = base::list(
            ft_groups_min = 10
          )
        )
      ),
      file = path_temp
    )

    base::Sys.setenv(R_CONFIG_ACTIVE = "project_cz_paleo")

    testthat::expect_error(
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "ft_method",
        fallback_config = "project_traits_reference",
        file = path_temp
      ),
      regexp = "ft_method"
    )
  }
)

testthat::test_that(
  "get_config_value_with_fallback() errors on unknown fallback config",
  {
    path_temp <-
      base::tempfile(fileext = ".yml")

    active_config_original <-
      base::Sys.getenv("R_CONFIG_ACTIVE", unset = NA_character_)

    base::on.exit(
      expr = {
        if (
          base::is.na(active_config_original)
        ) {
          base::Sys.unsetenv("R_CONFIG_ACTIVE")
        } else {
          base::Sys.setenv(R_CONFIG_ACTIVE = active_config_original)
        }

        base::unlink(path_temp)
      },
      add = TRUE
    )

    yaml::write_yaml(
      x = base::list(
        default = base::list(
          data_processing = base::list(
            min_n_samples = 5
          )
        )
      ),
      file = path_temp
    )

    base::Sys.setenv(R_CONFIG_ACTIVE = "default")

    testthat::expect_error(
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "ft_groups_min",
        fallback_config = "project_traits_reference",
        file = path_temp
      ),
      regexp = "Fallback config"
    )
  }
)

testthat::test_that(
  "get_config_value_with_fallback() errors on unknown active config",
  {
    path_temp <-
      base::tempfile(fileext = ".yml")

    active_config_original <-
      base::Sys.getenv("R_CONFIG_ACTIVE", unset = NA_character_)

    base::on.exit(
      expr = {
        if (
          base::is.na(active_config_original)
        ) {
          base::Sys.unsetenv("R_CONFIG_ACTIVE")
        } else {
          base::Sys.setenv(R_CONFIG_ACTIVE = active_config_original)
        }

        base::unlink(path_temp)
      },
      add = TRUE
    )

    yaml::write_yaml(
      x = base::list(
        default = base::list(
          data_processing = base::list(
            min_n_samples = 5
          )
        ),
        project_traits_reference = base::list(
          data_processing = base::list(
            ft_groups_min = 10
          )
        )
      ),
      file = path_temp
    )

    base::Sys.setenv(R_CONFIG_ACTIVE = "project_missing")

    testthat::expect_error(
      get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "min_n_samples",
        fallback_config = "default",
        file = path_temp
      ),
      regexp = "Active config"
    )
  }
)