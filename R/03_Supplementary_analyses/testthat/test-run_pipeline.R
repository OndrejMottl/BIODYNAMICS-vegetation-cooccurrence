testthat::test_that("run_pipeline() errors when default config is active", {
  tmp_script <-
    withr::local_tempfile(fileext = ".R")

  base::writeLines("list()", tmp_script)

  old_config <-
    Sys.getenv("R_CONFIG_ACTIVE")

  Sys.setenv(R_CONFIG_ACTIVE = "")

  on.exit(
    Sys.setenv(R_CONFIG_ACTIVE = old_config),
    add = TRUE
  )

  testthat::expect_error(
    run_pipeline(
      sel_script = tmp_script,
      check_default_config = TRUE
    )
  )
})

testthat::test_that("run_pipeline() bypasses config guard when disabled", {
  tmp_script <-
    withr::local_tempfile(fileext = ".R")

  base::writeLines("list()", tmp_script)

  old_config <-
    Sys.getenv("R_CONFIG_ACTIVE")

  Sys.setenv(R_CONFIG_ACTIVE = "")

  on.exit(
    Sys.setenv(R_CONFIG_ACTIVE = old_config),
    add = TRUE
  )

  # Mock targets::tar_make to prevent actual pipeline execution
  #   and avoid creating files in the project root under the default store
  testthat::local_mocked_bindings(
    tar_make = function(...) invisible(NULL),
    .package = "targets"
  )

  flag_default_config_guard_fired <- FALSE

  tryCatch(
    run_pipeline(
      sel_script = tmp_script,
      check_default_config = FALSE,
      plot_progress = FALSE
    ),
    error = function(e) {
      if (
        stringr::str_detect(
          string = base::conditionMessage(e),
          pattern = "default config is active"
        )
      ) {
        flag_default_config_guard_fired <<- TRUE
      }
    }
  )

  testthat::expect_false(flag_default_config_guard_fired)
})

testthat::test_that("run_pipeline() accepts store_suffix argument", {
  tmp_script <-
    withr::local_tempfile(fileext = ".R")

  base::writeLines("list()", tmp_script)

  old_config <-
    Sys.getenv("R_CONFIG_ACTIVE")

  Sys.setenv(R_CONFIG_ACTIVE = "")

  on.exit(
    Sys.setenv(R_CONFIG_ACTIVE = old_config),
    add = TRUE
  )

  err <-
    tryCatch(
      run_pipeline(
        sel_script = tmp_script,
        store_suffix = "eu_r01",
        check_default_config = TRUE
      ),
      error = function(e) e
    )

  # Error should be the default-config guard, not an "unused argument" error
  testthat::expect_true(
    stringr::str_detect(
      string = base::conditionMessage(err),
      pattern = "default config is active"
    )
  )
})

testthat::test_that("run_pipeline() validates sel_script is a single string", {
  testthat::expect_error(
    run_pipeline(
      sel_script = 123
    )
  )

  testthat::expect_error(
    run_pipeline(
      sel_script = NULL
    )
  )

  testthat::expect_error(
    run_pipeline(
      sel_script = c("path_a.R", "path_b.R")
    )
  )
})

testthat::test_that("run_pipeline() errors when script file does not exist", {
  testthat::expect_error(
    run_pipeline(
      sel_script = "non_existent_pipeline.R"
    )
  )
})

testthat::test_that("run_pipeline() validates store_suffix argument", {
  tmp_script <-
    withr::local_tempfile(fileext = ".R")

  base::writeLines("list()", tmp_script)

  testthat::expect_error(
    run_pipeline(
      sel_script = tmp_script,
      store_suffix = c("a", "b")
    )
  )

  testthat::expect_error(
    run_pipeline(
      sel_script = tmp_script,
      store_suffix = 123
    )
  )
})

testthat::test_that("run_pipeline() validates level_separation argument", {
  tmp_script <-
    withr::local_tempfile(fileext = ".R")

  base::writeLines("list()", tmp_script)

  testthat::expect_error(
    run_pipeline(
      sel_script = tmp_script,
      level_separation = -1
    )
  )

  testthat::expect_error(
    run_pipeline(
      sel_script = tmp_script,
      level_separation = "fast"
    )
  )
})

testthat::test_that("run_pipeline() validates plot_progress is logical", {
  tmp_script <-
    withr::local_tempfile(fileext = ".R")

  base::writeLines("list()", tmp_script)

  testthat::expect_error(
    run_pipeline(
      sel_script = tmp_script,
      plot_progress = "yes"
    )
  )

  testthat::expect_error(
    run_pipeline(
      sel_script = tmp_script,
      plot_progress = 1L
    )
  )
})

testthat::test_that("run_pipeline() validates check_default_config is logical", {
  tmp_script <-
    withr::local_tempfile(fileext = ".R")

  base::writeLines("list()", tmp_script)

  testthat::expect_error(
    run_pipeline(
      sel_script = tmp_script,
      check_default_config = "yes"
    )
  )

  testthat::expect_error(
    run_pipeline(
      sel_script = tmp_script,
      check_default_config = 1L
    )
  )
})

testthat::test_that("run_pipeline() validates fresh_run is logical", {
  tmp_script <-
    withr::local_tempfile(fileext = ".R")

  base::writeLines("list()", tmp_script)

  testthat::expect_error(
    run_pipeline(
      sel_script = tmp_script,
      fresh_run = "yes"
    )
  )

  testthat::expect_error(
    run_pipeline(
      sel_script = tmp_script,
      fresh_run = 1L
    )
  )
})

testthat::test_that("run_pipeline() calls tar_destroy when fresh_run = TRUE", {
  tmp_script <-
    withr::local_tempfile(fileext = ".R")

  base::writeLines("list()", tmp_script)

  old_config <-
    Sys.getenv("R_CONFIG_ACTIVE")

  Sys.setenv(R_CONFIG_ACTIVE = "")

  on.exit(
    Sys.setenv(R_CONFIG_ACTIVE = old_config),
    add = TRUE
  )

  flag_destroy_called <- FALSE

  testthat::local_mocked_bindings(
    tar_destroy = function(destroy, store, ...) {
      flag_destroy_called <<- TRUE
      invisible(NULL)
    },
    tar_make = function(...) invisible(NULL),
    .package = "targets"
  )

  run_pipeline(
    sel_script = tmp_script,
    check_default_config = FALSE,
    plot_progress = FALSE,
    fresh_run = TRUE
  )

  testthat::expect_true(flag_destroy_called)
})

testthat::test_that("run_pipeline() skips tar_destroy when fresh_run = FALSE", {
  tmp_script <-
    withr::local_tempfile(fileext = ".R")

  base::writeLines("list()", tmp_script)

  old_config <-
    Sys.getenv("R_CONFIG_ACTIVE")

  Sys.setenv(R_CONFIG_ACTIVE = "")

  on.exit(
    Sys.setenv(R_CONFIG_ACTIVE = old_config),
    add = TRUE
  )

  flag_destroy_called <- FALSE

  testthat::local_mocked_bindings(
    tar_destroy = function(destroy, store, ...) {
      flag_destroy_called <<- TRUE
      invisible(NULL)
    },
    tar_make = function(...) invisible(NULL),
    .package = "targets"
  )

  run_pipeline(
    sel_script = tmp_script,
    check_default_config = FALSE,
    plot_progress = FALSE,
    fresh_run = FALSE
  )

  testthat::expect_false(flag_destroy_called)
})


