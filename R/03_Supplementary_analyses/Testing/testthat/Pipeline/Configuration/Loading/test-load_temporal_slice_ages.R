write_test_slice_config <- function(vec_lines) {
  file_config <-
    base::tempfile(fileext = ".yml")
  base::writeLines(text = vec_lines, con = file_config)
  return(file_config)
}

testthat::test_that(
  "load_temporal_slice_ages() builds slices inside the window",
  {
    file_config <-
      write_test_slice_config(
        base::c(
          "default:",
          "  data_processing:",
          "    time_step: 500",
          "project_test:",
          "  vegvault_data:",
          "    age_lim: !expr c(0, 20e3)",
          "  temporal_slices:",
          "    age_window: !expr c(0, 1500)"
        )
      )

    res <-
      load_temporal_slice_ages(
        config_id = "project_test",
        file = file_config
      )

    testthat::expect_equal(res[["age"]], base::c(0, 500, 1000, 1500))
    testthat::expect_equal(
      res[["age_name"]],
      stringr::str_c("timeslice_", base::c(0, 500, 1000, 1500))
    )
  }
)

testthat::test_that(
  "load_temporal_slice_ages() requires the window",
  {
    file_config <-
      write_test_slice_config(
        base::c(
          "default:",
          "  data_processing:",
          "    time_step: 500",
          "project_test:",
          "  vegvault_data:",
          "    age_lim: !expr c(0, 20e3)"
        )
      )

    testthat::expect_error(
      load_temporal_slice_ages(
        config_id = "project_test",
        file = file_config
      ),
      class = "temporal_slice_window_missing"
    )
  }
)

testthat::test_that(
  "load_temporal_slice_ages() validates the window and step",
  {
    file_config <-
      write_test_slice_config(
        base::c(
          "default:",
          "  data_processing:",
          "    time_step: 500",
          "project_test:",
          "  temporal_slices:",
          "    age_window: !expr c(1000, 0)"
        )
      )

    testthat::expect_error(
      load_temporal_slice_ages(
        config_id = "project_test",
        file = file_config
      ),
      "two increasing ages"
    )
    testthat::expect_error(
      load_temporal_slice_ages(config_id = ""),
      "profile identifier"
    )
  }
)

testthat::test_that(
  "load_temporal_slice_ages() leaves excluded slices out",
  {
    file_config <-
      write_test_slice_config(
        base::c(
          "default:",
          "  data_processing:",
          "    time_step: 500",
          "project_test:",
          "  temporal_slices:",
          "    age_window: !expr c(0, 1000)",
          "    excluded_ages: !expr c(0)"
        )
      )

    res <-
      load_temporal_slice_ages(
        config_id = "project_test",
        file = file_config
      )
    res_all <-
      load_temporal_slice_ages(
        config_id = "project_test",
        file = file_config,
        flag_modelled_only = FALSE
      )

    testthat::expect_equal(res[["age"]], base::c(500, 1000))
    testthat::expect_equal(res_all[["age"]], base::c(0, 500, 1000))
    testthat::expect_equal(
      res_all[["flag_modelled"]],
      base::c(FALSE, TRUE, TRUE)
    )
  }
)

testthat::test_that(
  "load_temporal_slice_ages() rejects exclusions outside the window",
  {
    file_config <-
      write_test_slice_config(
        base::c(
          "default:",
          "  data_processing:",
          "    time_step: 500",
          "project_test:",
          "  temporal_slices:",
          "    age_window: !expr c(0, 1000)",
          "    excluded_ages: !expr c(250)"
        )
      )

    testthat::expect_error(
      load_temporal_slice_ages(
        config_id = "project_test",
        file = file_config
      ),
      "inside the window"
    )
  }
)
