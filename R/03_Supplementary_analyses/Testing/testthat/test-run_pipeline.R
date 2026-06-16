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

testthat::test_that(
  "run_pipeline() validates check_default_config is logical",
  {
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
  }
)

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

testthat::test_that("run_pipeline() validates prebuild_interpolation", {
  tmp_script <-
    withr::local_tempfile(fileext = ".R")

  base::writeLines("list()", tmp_script)

  testthat::expect_error(
    run_pipeline(
      sel_script = tmp_script,
      prebuild_interpolation = "yes"
    ),
    regexp = "prebuild_interpolation"
  )
})

testthat::test_that("run_pipeline() prebuilds then runs full build", {
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

  target_name_expression <- NULL
  flag_prebuild_lightweight <- FALSE
  flag_prebuild_crew_mori <- FALSE
  flag_meta_crew_mori <- FALSE
  flag_full_backend_clean <- FALSE
  n_prebuild_workers_env <- NULL
  vec_build_order <- base::character()

  testthat::local_mocked_bindings(
    tar_make_future = function(...) {
      base::stop("tar_make_future() should not be used")
    },
    tar_meta = function(...) {
      flag_meta_crew_mori <<-
        base::identical(
          base::Sys.getenv("BIODYNAMICS_PREPROCESSING_BACKEND"),
          "crew_mori"
        )

      tibble::tibble(
        name = base::c(
          "data_community_interpolated_dataset_branch_a",
          "data_community_interpolated"
        ),
        error = base::c(NA_character_, NA_character_)
      )
    },
    tar_invalidate = function(...) {
      base::stop("tar_invalidate() should not be used")
    },
    tar_make = function(names, ...) {
      if (
        base::identical(
          base::Sys.getenv("BIODYNAMICS_PREPROCESSING_BACKEND"),
          "crew_mori"
        )
      ) {
        target_name_expression <<-
          stringr::str_c(
            base::deparse(base::substitute(names)),
            collapse = ""
          )
        flag_prebuild_lightweight <<-
          base::identical(
            base::Sys.getenv("BIODYNAMICS_PREPROCESSING_WORKER"),
            "true"
          )
        flag_prebuild_crew_mori <<- TRUE
        n_prebuild_workers_env <<-
          base::Sys.getenv("BIODYNAMICS_PREPROCESSING_WORKERS")
        vec_build_order <<-
          base::c(vec_build_order, "prebuild")
      } else {
        flag_full_backend_clean <<-
          !base::nzchar(
            base::Sys.getenv("BIODYNAMICS_PREPROCESSING_BACKEND")
          )
        vec_build_order <<-
          base::c(vec_build_order, "full")
      }

      base::invisible(NULL)
    },
    .package = "targets"
  )

  run_pipeline(
    sel_script = tmp_script,
    check_default_config = FALSE,
    plot_progress = FALSE,
    prebuild_interpolation = TRUE
  )

  testthat::expect_match(
    target_name_expression,
    "data_community_interpolated"
  )

  testthat::expect_equal(
    vec_build_order,
    base::c("prebuild", "full")
  )

  testthat::expect_true(flag_prebuild_lightweight)
  testthat::expect_true(flag_prebuild_crew_mori)
  testthat::expect_true(flag_meta_crew_mori)
  testthat::expect_true(flag_full_backend_clean)

  testthat::expect_equal(
    base::as.integer(n_prebuild_workers_env),
    purrr::chuck(
      get_active_config("data_processing"),
      "n_interpolation_workers"
    )
  )
})

testthat::test_that("run_pipeline() repairs errored prebuild targets", {
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

  vec_invalidated_names <- NULL
  vec_build_order <- base::character()

  testthat::local_mocked_bindings(
    tar_make_future = function(...) {
      base::stop("tar_make_future() should not be used")
    },
    tar_meta = function(...) {
      tibble::tibble(
        name = base::c(
          "data_community_interpolated_dataset_branch_a",
          "data_community_interpolated_dataset_branch_b",
          "data_community_interpolated",
          "data_model"
        ),
        error = base::c(
          "branch failed",
          NA_character_,
          NA_character_,
          "model failed"
        )
      )
    },
    tar_invalidate = function(names, ...) {
      vec_invalidated_names <<-
        base::get(
          x = "vec_targets_to_invalidate",
          envir = parent.frame()
        )
      vec_build_order <<-
        base::c(vec_build_order, "invalidate")
      base::invisible(NULL)
    },
    tar_make = function(...) {
      if (
        base::identical(
          base::Sys.getenv("BIODYNAMICS_PREPROCESSING_BACKEND"),
          "crew_mori"
        )
      ) {
        vec_build_order <<-
          base::c(vec_build_order, "prebuild")
      } else {
        vec_build_order <<-
          base::c(vec_build_order, "full")
      }

      base::invisible(NULL)
    },
    .package = "targets"
  )

  run_pipeline(
    sel_script = tmp_script,
    check_default_config = FALSE,
    plot_progress = FALSE,
    prebuild_interpolation = TRUE
  )

  testthat::expect_equal(
    vec_build_order,
    base::c("invalidate", "prebuild", "full")
  )

  testthat::expect_true(
    "data_community_interpolated_dataset_branch_a" %in%
      vec_invalidated_names
  )

  testthat::expect_true(
    "data_community_interpolated" %in% vec_invalidated_names
  )

  testthat::expect_false(
    "data_model" %in% vec_invalidated_names
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


