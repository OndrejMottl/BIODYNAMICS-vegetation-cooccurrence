#' @title Run a Main Analysis Stage
#' @description
#' Runs an ordered table of main-analysis component scripts in isolated R
#' subprocesses, streams their output into live logs, and records statuses.
#' @param stage_id
#' Non-empty identifier for the numbered main-analysis stage.
#' @param data_components
#' Data frame with unique `component_id` and `script_path` columns. Optional
#' list-columns `arguments` and `environment` supply subprocess arguments and
#' environment variables.
#' @param run_id
#' Non-empty identifier shared by all component batches in one stage run.
#' @param continue_on_error
#' Logical scalar. If `TRUE`, all independent components are attempted before
#' the stage fails. If `FALSE`, execution stops after the first failure.
#' @param next_stage_script
#' Optional project-relative path printed after a successful stage.
#' @param runner_function
#' Injectable subprocess runner. Defaults to [processx::run()].
#' @param log_root
#' Directory under which stage logs and status CSV files are written.
#' @param verbose
#' Logical. If `TRUE` (default), progress messages are printed to the console.
#' @return
#' Tibble with one row per attempted component and its exit status and log.
#' @export
run_main_analysis_stage <- function(
    stage_id = NULL,
    data_components = NULL,
    run_id = NULL,
    continue_on_error = FALSE,
    next_stage_script = NULL,
    runner_function = processx::run,
    log_root = here::here("Data", "Temp", "Main_analysis_execution"),
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.character(stage_id),
    base::length(stage_id) == 1L,
    !base::is.na(stage_id),
    base::nzchar(stage_id),
    msg = "`stage_id` must be one non-empty string."
  )
  assertthat::assert_that(
    base::is.data.frame(data_components),
    base::all(
      base::c("component_id", "script_path") %in%
        base::colnames(data_components)
    ),
    msg = paste(
      "`data_components` requires `component_id` and `script_path`",
      "columns."
    )
  )
  assertthat::assert_that(
    base::nrow(data_components) > 0L,
    base::all(!base::is.na(data_components[["component_id"]])),
    base::all(base::nzchar(data_components[["component_id"]])),
    !base::any(base::duplicated(data_components[["component_id"]])),
    msg = "Component identifiers must be unique non-empty strings."
  )
  assertthat::assert_that(
    base::all(!base::is.na(data_components[["script_path"]])),
    base::all(base::nzchar(data_components[["script_path"]])),
    msg = "Component script paths must be non-empty strings."
  )
  assertthat::assert_that(
    base::is.character(run_id),
    base::length(run_id) == 1L,
    !base::is.na(run_id),
    base::nzchar(run_id),
    msg = "`run_id` must be one non-empty string."
  )
  assertthat::assert_that(
    assertthat::is.flag(continue_on_error),
    assertthat::is.flag(verbose),
    base::is.function(runner_function),
    msg = "Stage controls and runner function are invalid."
  )

  n_components <- base::nrow(data_components)
  list_empty_values <-
    base::rep(base::list(base::character()), n_components)
  data_components_validated <-
    data_components |>
    dplyr::mutate(
      arguments = if (
        "arguments" %in% base::colnames(data_components)
      ) {
        .data[["arguments"]]
      } else {
        list_empty_values
      },
      environment = if (
        "environment" %in% base::colnames(data_components)
      ) {
        .data[["environment"]]
      } else {
        list_empty_values
      }
    )

  path_run <-
    fs::path(log_root, stage_id, run_id)
  fs::dir_create(path_run)
  file_status <-
    fs::path(path_run, "component_status.csv")
  data_status_existing <-
    if (
      base::file.exists(file_status)
    ) {
      readr::read_csv(file_status, show_col_types = FALSE)
    } else {
      tibble::tibble()
    }
  list_status <- base::list()

  for (
    index_component in base::seq_len(n_components)
  ) {
    component_id <-
      data_components_validated[["component_id"]][[index_component]]
    script_path <-
      data_components_validated[["script_path"]][[index_component]]
    vec_arguments <-
      data_components_validated[["arguments"]][[index_component]]
    vec_environment <-
      data_components_validated[["environment"]][[index_component]]
    assertthat::assert_that(
      base::is.character(vec_arguments),
      base::is.character(vec_environment),
      base::length(vec_environment) == 0L ||
        (
          !base::is.null(base::names(vec_environment)) &&
            base::all(base::nzchar(base::names(vec_environment)))
        ),
      msg = paste(
        "Component arguments must be character vectors and component",
        "environment overrides must be named character vectors."
      )
    )
    vec_subprocess_environment <-
      if (
        base::length(vec_environment) == 0L
      ) {
        NULL
      } else {
        vec_inherited_environment <- base::Sys.getenv()
        vec_inherited_environment[base::names(vec_environment)] <-
          vec_environment
        vec_inherited_environment
      }
    recovery_command <-
      base::paste(
        base::c("Rscript", script_path, vec_arguments),
        collapse = " "
      )
    file_log <-
      fs::path(path_run, stringr::str_c(component_id, ".log"))
    time_started <-
      base::Sys.time()

    if (
      verbose
    ) {
      cli::cli_inform(
        base::c(
          "i" = "Running stage component {.field {component_id}}.",
          " " = "Log: {.path {file_log}}"
        )
      )
    }

    readr::write_lines(
      base::c(
        stringr::str_glue("Component: {component_id}"),
        stringr::str_glue("Script: {script_path}"),
        stringr::str_glue("Started: {time_started}"),
        ""
      ),
      file_log
    )
    flag_stdout_logged <- FALSE
    flag_stderr_logged <- FALSE

    list_run <-
      base::tryCatch(
        runner_function(
          command = base::file.path(base::R.home("bin"), "Rscript"),
          args = base::c(script_path, vec_arguments),
          env = vec_subprocess_environment,
          error_on_status = FALSE,
          echo = verbose,
          echo_cmd = verbose,
          stdout_callback = function(chunk, process) {
            flag_stdout_logged <<- TRUE
            base::cat(chunk, file = file_log, append = TRUE)
            return(base::invisible(NULL))
          },
          stderr_callback = function(chunk, process) {
            flag_stderr_logged <<- TRUE
            base::cat(chunk, file = file_log, append = TRUE)
            return(base::invisible(NULL))
          },
          encoding = "UTF-8"
        ),
        error = function(error_condition) {
          base::list(
            status = 1L,
            stdout = "",
            stderr = base::conditionMessage(error_condition)
          )
        }
      )
    status_code <-
      base::as.integer(purrr::pluck(list_run, "status", .default = 1L))
    text_stdout <-
      purrr::pluck(list_run, "stdout", .default = "")
    text_stderr <-
      purrr::pluck(list_run, "stderr", .default = "")
    if (
      !flag_stdout_logged && base::nzchar(text_stdout)
    ) {
      readr::write_lines(text_stdout, file_log, append = TRUE)
    }
    if (
      !flag_stderr_logged && base::nzchar(text_stderr)
    ) {
      readr::write_lines(text_stderr, file_log, append = TRUE)
    }

    component_status <-
      if (
        status_code == 0L
      ) {
        "ok"
      } else {
        "error"
      }
    list_status[[base::length(list_status) + 1L]] <-
      tibble::tibble(
        stage_id = stage_id,
        run_id = run_id,
        component_id = component_id,
        script_path = script_path,
        component_status = component_status,
        exit_status = status_code,
        started_at = base::format(time_started, tz = "UTC", usetz = TRUE),
        finished_at = base::format(
          base::Sys.time(),
          tz = "UTC",
          usetz = TRUE
        ),
        log_path = base::as.character(file_log),
        recovery_command = recovery_command
      )
    data_status <-
      dplyr::bind_rows(
        data_status_existing,
        purrr::list_rbind(list_status)
      ) |>
      dplyr::distinct(.data[["component_id"]], .keep_all = TRUE)
    readr::write_csv(data_status, file_status, na = "NA")

    if (
      status_code != 0L && !continue_on_error
    ) {
      break
    }
  }

  data_status <-
    dplyr::bind_rows(
      data_status_existing,
      purrr::list_rbind(list_status)
    ) |>
    dplyr::distinct(.data[["component_id"]], .keep_all = TRUE)
  if (
    base::any(data_status[["component_status"]] == "error")
  ) {
    vec_failed <-
      data_status |>
      dplyr::filter(.data[["component_status"]] == "error") |>
      dplyr::pull("component_id")
    vec_recovery_commands <-
      data_status |>
      dplyr::filter(.data[["component_status"]] == "error") |>
      dplyr::pull("recovery_command") |>
      base::unique()
    cli::cli_abort(
      base::c(
        "Main-analysis stage {.field {stage_id}} failed.",
        "x" = stringr::str_glue(
          "Failed components: ",
          "{stringr::str_c(vec_failed, collapse = ', ')}"
        ),
        "i" = "Prerequisite status and errors: {.path {file_status}}",
        "i" = "Component logs are beside the status CSV.",
        "i" = paste(
          "Recovery:",
          stringr::str_c(vec_recovery_commands, collapse = " ; ")
        )
      )
    )
  }

  if (
    verbose && !base::is.null(next_stage_script)
  ) {
    cli::cli_inform(
      base::c(
        "v" = "Main-analysis stage {.field {stage_id}} completed.",
        "i" = "Next: Rscript {.path {next_stage_script}}"
      )
    )
  }

  return(data_status)
}
