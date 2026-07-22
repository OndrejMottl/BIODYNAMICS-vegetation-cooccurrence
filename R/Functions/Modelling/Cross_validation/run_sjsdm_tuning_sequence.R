#' @title Run the Shared sjSDM Tuning Sequence
#' @description
#' Orchestrates isolated unit and tier stores for exhaustive or staged tuning.
#' Staged execution alternates one cumulative unit round with one tier-wide
#' survivor target, then publishes the existing final tier artifact.
#' @param unit_pipeline
#' Character scalar path to the unit pipeline script.
#' @param tuning_target_names
#' Non-empty character vector of public unit tuning-summary targets.
#' @param unit_store_suffixes
#' Optional character vector of isolated spatial-unit store suffixes. `NULL`
#' runs one non-nested unit store, as used by temporal mapped pipelines.
#' @param prebuild_interpolation
#' Logical forwarded to [run_pipeline()] for unit executions.
#' @param fresh_run
#' Logical. When true, destroys unit stores on their first round and the tier
#' store before its first aggregation. Later rounds always resume.
#' @param tuning_strategy
#' Character scalar, `"exhaustive"` or `"staged"`.
#' @param n_rounds
#' Positive integer configured repeat/tuning-round count.
#' @param run_pipeline_function
#' Injectable pipeline runner. Defaults to [run_pipeline()].
#' @return
#' Invisible `NULL`. Pipeline stores contain the durable results.
#' @export
run_sjsdm_tuning_sequence <- function(
    unit_pipeline = NULL,
    tuning_target_names = NULL,
    unit_store_suffixes = NULL,
    prebuild_interpolation = FALSE,
    fresh_run = FALSE,
    tuning_strategy = NULL,
    n_rounds = NULL,
    run_pipeline_function = run_pipeline) {
  assertthat::assert_that(
    base::is.character(unit_pipeline),
    base::length(unit_pipeline) == 1L,
    !base::is.na(unit_pipeline),
    base::nzchar(unit_pipeline),
    msg = "unit_pipeline must be one non-empty path."
  )

  assertthat::assert_that(
    base::is.character(tuning_target_names),
    base::length(tuning_target_names) > 0L,
    base::all(!base::is.na(tuning_target_names)),
    base::all(base::nzchar(tuning_target_names)),
    msg = "tuning_target_names must contain non-empty target names."
  )

  assertthat::assert_that(
    base::is.null(unit_store_suffixes) ||
      (
        base::is.character(unit_store_suffixes) &&
          base::length(unit_store_suffixes) > 0L &&
          base::all(!base::is.na(unit_store_suffixes)) &&
          base::all(base::nzchar(unit_store_suffixes))
      ),
    msg = "unit_store_suffixes must be NULL or non-empty strings."
  )

  assertthat::assert_that(
    base::is.logical(prebuild_interpolation),
    base::length(prebuild_interpolation) == 1L,
    !base::is.na(prebuild_interpolation),
    msg = "prebuild_interpolation must be one logical value."
  )

  assertthat::assert_that(
    base::is.logical(fresh_run),
    base::length(fresh_run) == 1L,
    !base::is.na(fresh_run),
    msg = "fresh_run must be one logical value."
  )

  assertthat::assert_that(
    base::is.character(tuning_strategy),
    base::length(tuning_strategy) == 1L,
    tuning_strategy %in% base::c("exhaustive", "staged"),
    msg = "tuning_strategy must be exhaustive or staged."
  )

  flag_valid_round_count <-
    base::is.numeric(n_rounds) &&
    base::length(n_rounds) == 1L &&
    base::is.finite(n_rounds) &&
    n_rounds >= 1L &&
    n_rounds == base::as.integer(n_rounds)

  assertthat::assert_that(
    flag_valid_round_count,
    msg = "n_rounds must be one positive integer."
  )

  assertthat::assert_that(
    base::is.function(run_pipeline_function),
    msg = "run_pipeline_function must be a function."
  )
  n_rounds <-
    base::as.integer(n_rounds)

  if (
    tuning_strategy == "staged" && n_rounds != 3L
  ) {
    cli::cli_abort(
      "Staged orchestration currently requires exactly three rounds."
    )
  }

  vec_round_ids <-
    if (
      tuning_strategy == "staged"
    ) {
      base::seq_len(n_rounds)
    } else {
      1L
    }

  for (round_id in vec_round_ids) {
    fresh_round <-
      fresh_run && round_id == 1L
    prebuild_round <-
      prebuild_interpolation && round_id == 1L
    final_round <-
      round_id == base::max(vec_round_ids)

    if (
      base::is.null(unit_store_suffixes)
    ) {
      withr::with_envvar(
        new = base::c(
          SJSMD_TUNING_MAX_ROUND = base::as.character(round_id)
        ),
        code = run_pipeline_function(
          sel_script = unit_pipeline,
          target_names = tuning_target_names,
          prebuild_interpolation = prebuild_round,
          fresh_run = fresh_round,
          plot_progress = FALSE
        )
      )
    } else {
      for (store_suffix in unit_store_suffixes) {
        withr::with_envvar(
          new = base::c(
            SJSMD_TUNING_MAX_ROUND = base::as.character(round_id)
          ),
          code = run_pipeline_function(
            sel_script = unit_pipeline,
            store_suffix = store_suffix,
            target_names = tuning_target_names,
            prebuild_interpolation = prebuild_round,
            fresh_run = fresh_round,
            plot_progress = FALSE
          )
        )
      }
    }

    if (
      tuning_strategy == "exhaustive"
    ) {
      run_pipeline_function(
        sel_script = "R/Pipelines/pipeline_sjsdm_tier_tuning.R",
        fresh_run = fresh_round,
        plot_progress = final_round,
        callr_function = NULL
      )
    } else {
      tier_target_name <-
        if (
          round_id < n_rounds
        ) {
          stringr::str_glue(
            "data_sjsdm_tier_survivor_decisions_round_{round_id}"
          ) |>
            base::as.character()
        } else {
          "data_sjsdm_tier_regularization_artifacts"
        }

      run_pipeline_function(
        sel_script = "R/Pipelines/pipeline_sjsdm_tier_tuning.R",
        target_names = tier_target_name,
        fresh_run = fresh_round,
        plot_progress = final_round,
        callr_function = NULL
      )
    }
  }

  return(base::invisible(NULL))
}
