testthat::test_that(
  "run_main_analysis_stage() records ordered successful components",
  {
    path_log_root <-
      withr::local_tempdir()
    data_components <-
      tibble::tibble(
        component_id = base::c("first", "second"),
        script_path = base::c("first.R", "second.R")
      )
    vec_calls <- base::character()
    runner_function <- function(...) {
      list_arguments <-
        base::list(...)
      vec_calls <<-
        base::c(vec_calls, list_arguments[["args"]][[1L]])
      base::list(
        status = 0L,
        stdout = "completed",
        stderr = ""
      )
    }

    data_result <-
      run_main_analysis_stage(
        stage_id = "01_preparation",
        data_components = data_components,
        run_id = "test_run",
        runner_function = runner_function,
        log_root = path_log_root,
        verbose = FALSE
      )

    testthat::expect_equal(vec_calls, data_components[["script_path"]])
    testthat::expect_equal(data_result[["component_status"]],
                           base::rep("ok", 2L))
    testthat::expect_true(
      base::all(base::file.exists(data_result[["log_path"]]))
    )
    testthat::expect_true(
      base::file.exists(
        base::file.path(
          path_log_root,
          "01_preparation",
          "test_run",
          "component_status.csv"
        )
      )
    )
  }
)

testthat::test_that(
  "run_main_analysis_stage() continues independent work before failing",
  {
    path_log_root <-
      withr::local_tempdir()
    data_components <-
      tibble::tibble(
        component_id = base::c("failed", "completed"),
        script_path = base::c("failed.R", "completed.R")
      )
    n_calls <- 0L
    runner_function <- function(...) {
      n_calls <<- n_calls + 1L
      base::list(
        status = base::ifelse(n_calls == 1L, 1L, 0L),
        stdout = "output",
        stderr = "error"
      )
    }

    testthat::expect_error(
      run_main_analysis_stage(
        stage_id = "02_model_calibration",
        data_components = data_components,
        run_id = "test_run",
        continue_on_error = TRUE,
        runner_function = runner_function,
        log_root = path_log_root,
        verbose = FALSE
      ),
      "failed"
    )
    testthat::expect_equal(n_calls, 2L)
    data_status <-
      readr::read_csv(
        base::file.path(
          path_log_root,
          "02_model_calibration",
          "test_run",
          "component_status.csv"
        ),
        show_col_types = FALSE
      )
    testthat::expect_equal(
      data_status[["component_status"]],
      base::c("error", "ok")
    )
    testthat::expect_equal(
      data_status[["recovery_command"]],
      base::c(
        "Rscript failed.R",
        "Rscript completed.R"
      )
    )
  }
)

testthat::test_that(
  "run_main_analysis_stage() validates its component contract",
  {
    testthat::expect_error(
      run_main_analysis_stage(
        stage_id = "01_preparation",
        data_components = tibble::tibble(script_path = "one.R"),
        run_id = "test_run",
        verbose = FALSE
      ),
      "component_id"
    )
    testthat::expect_error(
      run_main_analysis_stage(
        stage_id = "01_preparation",
        data_components = tibble::tibble(
          component_id = base::c("same", "same"),
          script_path = base::c("one.R", "two.R")
        ),
        run_id = "test_run",
        verbose = FALSE
      ),
      "unique"
    )
  }
)

testthat::test_that(
  "run_main_analysis_stage() preserves the subprocess environment",
  {
    path_log_root <- withr::local_tempdir()
    path_component <-
      base::file.path(path_log_root, "check_environment.R")
    base::writeLines(
      base::c(
        'stopifnot(Sys.getenv("MAIN_STAGE_PARENT") == "inherited")',
        'stopifnot(nzchar(Sys.getenv("PATH")))',
        'if (.Platform$OS.type == "windows") {',
        '  stopifnot(nzchar(Sys.getenv("COMSPEC")))',
        '}',
        'stopifnot(Sys.getenv("MAIN_STAGE_COMPONENT") == "component")'
      ),
      con = path_component,
      useBytes = TRUE
    )
    withr::local_envvar(MAIN_STAGE_PARENT = "inherited")
    data_components <-
      tibble::tibble(
        component_id = "environment_check",
        script_path = path_component,
        environment = base::list(
          base::c(MAIN_STAGE_COMPONENT = "component")
        )
      )

    data_result <-
      run_main_analysis_stage(
        stage_id = "01_preparation",
        data_components = data_components,
        run_id = "environment_test",
        log_root = path_log_root,
        verbose = FALSE
      )

    testthat::expect_equal(data_result[["component_status"]], "ok")
  }
)

testthat::test_that(
  "run_main_analysis_stage() writes subprocess output to its live log",
  {
    path_log_root <- withr::local_tempdir()
    path_expected_log <-
      base::file.path(
        path_log_root,
        "01_preparation",
        "live_log_test",
        "component.log"
      )
    runner_function <- function(...) {
      list_arguments <- base::list(...)
      testthat::expect_true(base::file.exists(path_expected_log))
      list_arguments[["stdout_callback"]](
        "live stdout\n",
        NULL
      )
      list_arguments[["stderr_callback"]](
        "live stderr\n",
        NULL
      )
      testthat::expect_true(
        stringr::str_detect(
          base::paste(
            base::readLines(path_expected_log),
            collapse = "\n"
          ),
          stringr::regex(
            "live stdout.*live stderr",
            dotall = TRUE
          )
        )
      )
      base::list(
        status = 0L,
        stdout = "live stdout",
        stderr = "live stderr"
      )
    }

    run_main_analysis_stage(
      stage_id = "01_preparation",
      data_components = tibble::tibble(
        component_id = "component",
        script_path = "component.R"
      ),
      run_id = "live_log_test",
      runner_function = runner_function,
      log_root = path_log_root,
      verbose = FALSE
    )

    log_text <-
      base::paste(base::readLines(path_expected_log), collapse = "\n")
    testthat::expect_identical(
      stringr::str_count(log_text, "live stdout"),
      1L
    )
    testthat::expect_identical(
      stringr::str_count(log_text, "live stderr"),
      1L
    )
  }
)
