#' @title Run One sjSDM Unit Tuning Round
#' @description
#' Runs one cumulative tuning round across isolated unit stores while
#' preserving the round environment variable and first-round semantics.
#' @param round_id,unit_pipeline,tuning_target_names,unit_store_suffixes
#' Round identifier and unit execution inputs.
#' @param prebuild_round,fresh_round
#' First-round interpolation and store-reset flags.
#' @param run_pipeline_function
#' Injectable pipeline runner.
#' @param vec_allowed_profile_roles,vec_allowed_profile_statuses
#' Allowed profile metadata forwarded to the runner.
#' @param unit_target_names
#' Optional named list of per-unit target requests from verified preparation.
#' Empty requests are expected infeasible and never sent to the runner.
#' @param verbose Logical controlling unit messages.
#' @return
#' Tibble with one row per unit and its pipeline status and error message.
#' @export
run_sjsdm_tuning_unit_round <- function(
    round_id = NULL,
    unit_pipeline = NULL,
    tuning_target_names = NULL,
    unit_store_suffixes = NULL,
    prebuild_round = FALSE,
    fresh_round = FALSE,
    run_pipeline_function = run_pipeline,
    vec_allowed_profile_roles = base::c("main", "smoke"),
    vec_allowed_profile_statuses = "active",
    unit_target_names = NULL,
    verbose = TRUE) {
  assertthat::assert_that(assertthat::is.flag(verbose),
    base::is.null(unit_target_names) || (
      base::is.list(unit_target_names) &&
        base::all(unit_store_suffixes %in% base::names(unit_target_names))
    ), msg = "Per-unit tuning requests must cover every requested store.")
  vec_store_suffixes <-
    if (
      base::is.null(unit_store_suffixes)
    ) {
      NA_character_
    } else {
      unit_store_suffixes
    }

  res <-
    purrr::map(
    vec_store_suffixes,
    .f = function(store_suffix) {
      vec_unit_targets <-
        if (
          base::is.null(unit_target_names)
        ) {
          tuning_target_names
        } else {
          unit_target_names[[store_suffix]]
        }
      if (
        base::length(vec_unit_targets) == 0L
      ) {
        return(tibble::tibble(store_suffix = store_suffix,
          pipeline_status = "expected_infeasible",
          error_message = NA_character_))
      }
      list_arguments <-
        base::list(
          sel_script = unit_pipeline,
          target_names = vec_unit_targets,
          prebuild_interpolation = prebuild_round,
          fresh_run = fresh_round,
          vec_allowed_profile_roles = vec_allowed_profile_roles,
          vec_allowed_profile_statuses =
            vec_allowed_profile_statuses,
          plot_progress = FALSE
        )

      if (
        !base::is.na(store_suffix)
      ) {
        list_arguments[["store_suffix"]] <- store_suffix
      }

      error_message <- NA_character_
      error_class <- "error"
      run_unit <-
        purrr::possibly(
          .f = function() {
            base::tryCatch(
              expr = withr::with_envvar(
                new = base::c(
                  SJSMD_TUNING_MAX_ROUND =
                    base::as.character(round_id)
                ),
                code = rlang::exec(
                  .fn = run_pipeline_function,
                  !!!list_arguments
                )
              ),
              error = function(error_condition) {
                error_class <<-
                  if (
                    base::inherits(error_condition,
                      "sjsdm_unit_expected_infeasible")
                  ) {
                    "expected_infeasible"
                  } else {
                    "error"
                  }
                error_message <<-
                  base::conditionMessage(error_condition)
                base::stop(error_condition)
              }
            )
            TRUE
          },
          otherwise = FALSE,
          quiet = TRUE
        )

      flag_success <- run_unit()
      pipeline_status <-
        if (
          flag_success
        ) {
          "ok"
        } else {
          error_class
        }

      if (
        verbose && !flag_success
      ) {
        cli::cli_inform(
          base::c(
            "!" = stringr::str_glue(
              "Skipping failed tuning unit {store_suffix}."
            ),
            "x" = "{error_message}",
            "i" = "Tuning will continue with the next unit."
          )
        )
      }

      tibble::tibble(
        store_suffix = store_suffix,
        pipeline_status = pipeline_status,
        error_message = error_message
      )
    }
  ) |>
    purrr::list_rbind()

  return(res)
}
