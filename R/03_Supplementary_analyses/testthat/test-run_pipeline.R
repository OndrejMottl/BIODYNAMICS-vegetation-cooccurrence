testthat::test_that("run_pipeline errors when default config is active", {
  # Force default config active
  old_config <-
    Sys.getenv("R_CONFIG_ACTIVE")

  Sys.setenv(R_CONFIG_ACTIVE = "")

  on.exit(
    Sys.setenv(R_CONFIG_ACTIVE = old_config),
    add = TRUE
  )

  # When R_CONFIG_ACTIVE is empty, config::is_active("default") is TRUE
  testthat::expect_error(
    run_pipeline(
      sel_script = "R/02_Main_analyses/pipeline_basic.R",
      check_default_config = TRUE
    )
  )
})

testthat::test_that("run_pipeline check_default_config FALSE bypasses guard", {
  # Force default config active
  old_config <-
    Sys.getenv("R_CONFIG_ACTIVE")

  Sys.setenv(R_CONFIG_ACTIVE = "")

  on.exit(
    Sys.setenv(R_CONFIG_ACTIVE = old_config),
    add = TRUE
  )

  # With check_default_config = FALSE the default-config guard is skipped.
  # The function may succeed or fail later for other reasons, but it must NOT
  #   throw the default-config error message specifically.
  default_config_guard_fired <- FALSE

  tryCatch(
    run_pipeline(
      sel_script = "R/02_Main_analyses/pipeline_basic.R",
      check_default_config = FALSE
    ),
    error = function(e) {
      if (
        stringr::str_detect(
          string = base::conditionMessage(e),
          pattern = "default config is active"
        )
      ) {
        default_config_guard_fired <<- TRUE
      }
    }
  )

  testthat::expect_false(default_config_guard_fired)
})

testthat::test_that("run_pipeline accepts store_suffix argument", {
  # Confirm function signature includes store_suffix without error.
  # No R_CONFIG_ACTIVE set so the default-config guard fires,
  #   but we verify the argument is accepted before that check.
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
        sel_script = "R/02_Main_analyses/pipeline_basic.R",
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
