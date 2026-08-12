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
#' @return
#' Invisible `NULL`.
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
    vec_allowed_profile_statuses = "active") {
  vec_store_suffixes <-
    if (
      base::is.null(unit_store_suffixes)
    ) {
      NA_character_
    } else {
      unit_store_suffixes
    }

  purrr::walk(
    vec_store_suffixes,
    .f = function(store_suffix) {
      list_arguments <-
        base::list(
          sel_script = unit_pipeline,
          target_names = tuning_target_names,
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

      withr::with_envvar(
        new = base::c(
          SJSMD_TUNING_MAX_ROUND = base::as.character(round_id)
        ),
        code = rlang::exec(
          .fn = run_pipeline_function,
          !!!list_arguments
        )
      )
    }
  )

  return(base::invisible(NULL))
}
