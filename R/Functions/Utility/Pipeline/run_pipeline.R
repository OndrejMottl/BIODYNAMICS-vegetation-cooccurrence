#' @title Run Pipeline
#' @description
#' Executes a targets pipeline from a specified script and saves progress
#' visualization. Rejects profiles not authorized for the runner.
#' @param sel_script
#' Path to the pipeline script to execute (relative to project root).
#' @param store_suffix
#' Optional character string appended as a sub-directory between the
#' config-derived target store root and the pipeline name.
#' When `NULL` (default) the path is
#' `{target_store}/{pipeline_name}/` — identical to the original
#' behaviour. When set, the path becomes
#' `{target_store}/{store_suffix}/{pipeline_name}/`.
#' Useful when iterating over many spatial units that share one config
#' but each need an isolated store (e.g. `store_suffix = "eu_r01"`).
#' @param target_names
#' Optional character vector of target names to build. `NULL` builds the
#' complete pipeline.
#' @param level_separation
#' Numeric value controlling the vertical separation between levels in the
#' progress visualization network graph. Default is 100.
#' @param flag_validate_profile_selection
#' Logical controlling validation of the active profile role and status.
#' Disable only for isolated tests that inject all configuration behavior.
#' @param vec_allowed_profile_roles
#' Profile roles authorized by this runner. Defaults to production roles
#' `c("main", "smoke")`.
#' @param vec_allowed_profile_statuses
#' Profile statuses authorized by this runner. Defaults to `"active"`.
#' @param fresh_run
#' Logical indicating whether to destroy the existing target store before
#' running the pipeline, forcing all targets to be re-computed from
#' scratch. When `TRUE`, calls
#' `targets::tar_destroy(destroy = "all", store = ...)` prior to
#' `targets::tar_make()`. Default is `FALSE`.
#' @param plot_progress
#' Logical indicating whether to save a progress visualisation after the
#' pipeline completes. Default is TRUE.
#' @param prebuild_interpolation
#' Logical indicating whether to prebuild `data_community_interpolated`
#' using parallel dynamic branches before running the complete pipeline.
#' The worker count is read from
#' `data_processing$n_interpolation_workers`. Default is `FALSE`.
#' @param callr_function
#' Function used by [targets::tar_make()] to launch the pipeline process.
#' Defaults to [callr::r()]. Supply `NULL` only for small graphs that are safe
#' to execute in the current orchestration process.
#' @return
#' No return value. Function is called for side effects: executes the
#' targets pipeline and saves progress visualization to the documentation
#' folder.
#' @details
#' The function constructs pipeline-specific target store paths based on
#' the script name and active configuration. When `fresh_run = TRUE`,
#' the target store is destroyed with
#' `targets::tar_destroy(destroy = "all")` before execution so that every
#' target is rebuilt from scratch. It uses `targets::tar_make()` to
#' execute the pipeline and then calls `save_progress_visualisation()` to
#' generate a network visualization of the pipeline status. When
#' `prebuild_interpolation = TRUE`, the function first executes only
#' `data_community_interpolated` with the `crew_mori` preprocessing
#' backend. Once that call returns, the complete pipeline is executed
#' with [targets::tar_make()]. Thus downstream GPU-dependent model
#' targets remain sequentially scheduled.
#' @seealso
#'   [save_progress_visualisation()],
#'   [targets::tar_make()],
#'   [crew::crew_controller_local()]
#' @export
run_pipeline <- function(
    sel_script,
    store_suffix = NULL,
    target_names = NULL,
    level_separation = 100,
    flag_validate_profile_selection = TRUE,
    vec_allowed_profile_roles = base::c("main", "smoke"),
    vec_allowed_profile_statuses = "active",
    plot_progress = TRUE,
    fresh_run = FALSE,
    prebuild_interpolation = FALSE,
    callr_function = callr::r) {
  assertthat::assert_that(
    is.character(sel_script),
    length(sel_script) == 1,
    msg = paste(
      "sel_script must be a single string specifying the path",
      "to the pipeline script."
    )
  )
  assertthat::assert_that(
    file.exists(sel_script),
    msg = paste(
      "The specified script does not exist:", sel_script, "\n",
      "Please provide a valid path relative to the project root."
    )
  )

  assertthat::assert_that(
    is.null(store_suffix) ||
      (
        is.character(store_suffix) && length(store_suffix) == 1
      ),
    msg = "store_suffix must be NULL or a single string."
  )

  assertthat::assert_that(
    base::is.null(target_names) ||
      (
        base::is.character(target_names) &&
          base::length(target_names) > 0L &&
          base::all(base::nzchar(target_names))
      ),
    msg = "target_names must be NULL or non-empty target names."
  )

  assertthat::assert_that(
    is.numeric(level_separation) &&
      length(level_separation) == 1 &&
      level_separation >= 0,
    msg = "level_separation must be a non-negative number."
  )

  assertthat::assert_that(
    assertthat::is.flag(flag_validate_profile_selection),
    msg = paste(
      "flag_validate_profile_selection must be a single logical value",
      "(TRUE or FALSE)."
    )
  )

  assertthat::assert_that(
    assertthat::is.flag(plot_progress),
    msg = "plot_progress must be a single logical value (TRUE or FALSE)."
  )

  assertthat::assert_that(
    assertthat::is.flag(fresh_run),
    msg = "fresh_run must be a single logical value (TRUE or FALSE)."
  )

  assertthat::assert_that(
    assertthat::is.flag(prebuild_interpolation),
    msg = paste(
      "prebuild_interpolation must be a single logical value",
      "(TRUE or FALSE)."
    )
  )

  assertthat::assert_that(
    base::is.null(callr_function) || base::is.function(callr_function),
    msg = "callr_function must be NULL or a function."
  )

  if (
    isTRUE(flag_validate_profile_selection)
  ) {
    validate_config_profile_selection(
      vec_allowed_roles = vec_allowed_profile_roles,
      vec_allowed_statuses = vec_allowed_profile_statuses
    )
  }

  sel_script_path <-
    here::here(sel_script)

  sel_pipeline_name <-
    stringr::str_replace(
      string = basename(sel_script_path),
      pattern = ".R$",
      replacement = ""
    )

  sel_store_path <-
    if (
      is.null(store_suffix)
    ) {
      paste0(
        load_active_config_value("target_store"), "/",
        sel_pipeline_name, "/"
      )
    } else {
      {
        paste0(
          load_active_config_value("target_store"), "/",
          store_suffix, "/",
          sel_pipeline_name, "/"
        )
      } |>
        here::here()
    }

  # Optionally wipe the store so all targets are rebuilt from scratch.
  # TAR_ASK is set to "false" for the duration of tar_destroy() to
  #   suppress the interactive confirmation prompt, allowing agents and
  #   unattended scripts to run without user input.
  if (
    isTRUE(fresh_run)
  ) {
    withr::with_envvar(
      new = c(TAR_ASK = "false"),
      code = targets::tar_destroy(
        destroy = "all",
        store = sel_store_path
      )
    )
  }

  # Run the pipeline. Capture failures only long enough to save the
  # progress visualisation below, then rethrow so unattended runs fail.
  tar_error <- NULL
  prebuild_error <- NULL

  if (
    isTRUE(prebuild_interpolation)
  ) {
    interpolation_workers <-
      load_active_config_value("data_processing") |>
      purrr::chuck("n_interpolation_workers")

    assertthat::assert_that(
      base::is.numeric(interpolation_workers) &&
        base::length(interpolation_workers) == 1L &&
        base::is.finite(interpolation_workers) &&
        interpolation_workers >= 1L &&
        interpolation_workers == base::as.integer(interpolation_workers),
      msg = paste(
        "data_processing$n_interpolation_workers must be a",
        "single positive integer."
      )
    )

    interpolation_workers <-
      base::as.integer(interpolation_workers)

    tryCatch(
      withr::with_envvar(
        new = base::c(
          BIODYNAMICS_PREPROCESSING_WORKER = "true",
          BIODYNAMICS_PREPROCESSING_BACKEND = "crew_mori",
          BIODYNAMICS_PREPROCESSING_WORKERS =
            base::as.character(interpolation_workers)
        ),
        code = {
          data_prebuild_target_meta <-
            tryCatch(
              suppressWarnings(
                targets::tar_meta(
                  fields = tidyselect::any_of(
                    base::c("name", "error")
                  ),
                  store = sel_store_path,
                  complete_only = FALSE
                )
              ),
              error = function(err) {
                tibble::tibble(
                  name = base::character(),
                  error = base::character()
                )
              }
            )

          if (
            !"error" %in% base::colnames(data_prebuild_target_meta)
          ) {
            data_prebuild_target_meta[["error"]] <- NA_character_
          }

          vec_prebuild_target_name <- data_prebuild_target_meta[["name"]]
          vec_prebuild_error <- data_prebuild_target_meta[["error"]]

          vec_shared_target_names <-
            base::c(
              "data_community_proportions_shared",
              "data_age_uncertainty_shared"
            )

          vec_shared_targets_to_refresh <-
            base::intersect(
              vec_shared_target_names,
              vec_prebuild_target_name
            )

          if (
            base::length(vec_shared_targets_to_refresh) > 0L
          ) {
            targets::tar_invalidate(
              names = tidyselect::all_of(
                vec_shared_targets_to_refresh
              ),
              store = sel_store_path
            )
          }

          flag_prebuild_interpolation_target <-
            stringr::str_detect(
              string = vec_prebuild_target_name,
              pattern = stringr::str_c(
                "^(",
                "data_community_proportions_shared",
                "|data_age_uncertainty_shared",
                "|data_community_interpolated_dataset",
                "|data_community_interpolated",
                ")"
              )
            )

          flag_prebuild_target_errored <-
            !base::is.na(vec_prebuild_error) &
            base::nzchar(vec_prebuild_error)

          vec_errored_prebuild_targets <-
            vec_prebuild_target_name[
              flag_prebuild_interpolation_target &
                flag_prebuild_target_errored
            ]

          if (
            base::length(vec_errored_prebuild_targets) > 0L
          ) {
            vec_targets_to_invalidate <-
              base::unique(
                base::c(
                  vec_errored_prebuild_targets,
                  "data_community_interpolated"
                )
              )

            targets::tar_invalidate(
              names = tidyselect::any_of(
                vec_targets_to_invalidate
              ),
              store = sel_store_path
            )
          }

          base::tryCatch(
            targets::tar_make(
              names = tidyselect::all_of(
                "data_community_interpolated"
              ),
              script = sel_script_path,
              store = sel_store_path,
              reporter = "verbose",
              callr_function = NULL
            ),
            finally = targets::tar_unblock_process(
              store = sel_store_path
            )
          )
        }
      ),
      error = function(err) {
        prebuild_error <<- err
      }
    )

    if (
      !base::is.null(prebuild_error)
    ) {
      warning(
        paste(
          "Interpolation prebuild failed and will be skipped.",
          "Continuing with full tar_make().",
          "Prebuild error:",
          conditionMessage(prebuild_error)
        ),
        call. = FALSE
      )
    }
  }

  if (
    base::is.null(tar_error)
  ) {
    data_target_errors_before <-
      targets::tar_meta(
        fields = tidyselect::any_of(
          base::c("name", "error", "time")
        ),
        store = sel_store_path,
        complete_only = FALSE
      )

    if (
      !"time" %in% base::colnames(data_target_errors_before)
    ) {
      data_target_errors_before[["time"]] <-
        base::rep(
          base::as.POSIXct(NA),
          base::nrow(data_target_errors_before)
        )
    }

    tryCatch(
      if (
        base::is.null(target_names)
      ) {
        targets::tar_make(
          script = sel_script_path,
          store = sel_store_path,
          reporter = "verbose",
          callr_function = callr_function
        )
      } else {
        targets::tar_make(
          names = target_names,
          script = sel_script_path,
          store = sel_store_path,
          reporter = "verbose",
          callr_function = callr_function
        )
      },
      error = function(err) {
        tar_error <<- err
      }
    )

    data_target_errors_after <-
      targets::tar_meta(
        fields = tidyselect::any_of(
          base::c("name", "error", "time")
        ),
        store = sel_store_path,
        complete_only = FALSE
      )

    if (
      !"time" %in% base::colnames(data_target_errors_after)
    ) {
      data_target_errors_after[["time"]] <-
        base::rep(
          base::as.POSIXct(NA),
          base::nrow(data_target_errors_after)
        )
    }

    data_new_target_errors <-
      get_new_targets_errors(
        data_errors_before = data_target_errors_before,
        data_errors_after = data_target_errors_after
      )

    if (
      base::is.null(tar_error) &&
        base::nrow(data_new_target_errors) > 0L
    ) {
      first_error <-
        data_new_target_errors[1L, , drop = FALSE]

      tar_error <-
        base::simpleError(
          stringr::str_glue(
            "{base::nrow(data_new_target_errors)} target(s) errored; ",
            "first error in '{first_error[['name']][[1L]]}': ",
            "{first_error[['error']][[1L]]}"
          )
        )
    }
  }

  if (
    isTRUE(plot_progress)
  ) {
    save_progress_visualisation(
      sel_script = sel_script_path,
      sel_store = sel_store_path,
      level_separation = level_separation
    )
  }

  if (
    !base::is.null(tar_error)
  ) {
    base::stop(tar_error)
  }
}
