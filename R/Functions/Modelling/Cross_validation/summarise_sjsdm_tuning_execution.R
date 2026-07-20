#' @title Summarise sjSDM Tuning Execution
#' @description
#' Records the shared tuning strategy, executed fit count, prepared-fold count,
#' and selected-candidate refits avoided through probability reuse.
#' @param data_tuning
#' Fold-level tuning table from [run_sjsdm_tuning_candidates()].
#' @param data_schedule
#' Validated schedule from [build_sjsdm_tuning_schedule()].
#' @param data_work_items
#' Optional work-item table from [build_sjsdm_tuning_work_items()].
#' @return
#' One-row execution-provenance tibble containing strategy identifiers, fit
#' counts, prediction source, and fit-reduction fraction relative to the former
#' unconditional selected-candidate refit path.
#' @examples
#' \dontrun{
#' summarise_sjsdm_tuning_execution(
#'   data_tuning = data_sjsdm_tuning_candidates,
#'   data_schedule = data_sjsdm_tuning_schedule
#' )
#' }
#' @export
summarise_sjsdm_tuning_execution <- function(
    data_tuning = NULL,
    data_schedule = NULL,
    data_work_items = NULL) {
  vec_tuning_columns <-
    base::c("repeat_id", "fold_id", "candidate_id", "fit_status")

  vec_schedule_columns <-
    base::c(
      "tuning_strategy",
      "strategy_version",
      "round_id",
      "repeat_id",
      "n_candidates_entering",
      "n_candidates_surviving"
    )

  assertthat::assert_that(
    base::is.data.frame(data_tuning),
    base::all(vec_tuning_columns %in% base::colnames(data_tuning)),
    msg = "data_tuning is missing execution-provenance columns."
  )

  assertthat::assert_that(
    base::is.data.frame(data_schedule),
    base::nrow(data_schedule) > 0L,
    base::all(vec_schedule_columns %in% base::colnames(data_schedule)),
    msg = "data_schedule is missing tuning-schedule columns."
  )

  if (
    !base::is.null(data_work_items)
  ) {
    assertthat::assert_that(
      base::is.data.frame(data_work_items),
      base::all(
        base::c(
          "work_item_id",
          "repeat_id",
          "fold_id",
          "candidate_id"
        ) %in% base::colnames(data_work_items)
      ),
      !base::any(
        base::duplicated(data_work_items[["work_item_id"]])
      ),
      msg = "data_work_items has invalid execution identities."
    )
  }

  n_work_items_materialized <-
    if (
      base::is.null(data_work_items)
    ) {
      base::nrow(data_tuning)
    } else {
      base::nrow(data_work_items)
    }

  if (
    base::nrow(data_tuning) == 0L
  ) {
    return(
      tibble::tibble(
        tuning_strategy = data_schedule[["tuning_strategy"]][[1L]],
        tuning_strategy_version =
          data_schedule[["strategy_version"]][[1L]],
        evaluation_prediction_source = "tuning_prediction_cache",
        work_item_identity_version = "sjsdm_cv_work_item_v1",
        restart_boundary = "repeat_fold_candidate",
        n_rounds = base::nrow(data_schedule),
        n_work_items_materialized =
          base::as.integer(n_work_items_materialized),
        n_fold_preparations = 0L,
        n_fits_executed = 0L,
        n_successful_fits = 0L,
        n_selected_refits_reused = 0L,
        n_fits_exhaustive = 0L,
        n_fits_historical = 0L,
        fit_reduction_fraction = NA_real_
      )
    )
  }

  data_repeat_execution <-
    data_tuning |>
    dplyr::group_by(.data[["repeat_id"]]) |>
    dplyr::summarise(
      n_folds = dplyr::n_distinct(.data[["fold_id"]]),
      n_candidates_executed =
        dplyr::n_distinct(.data[["candidate_id"]]),
      .groups = "drop"
    ) |>
    dplyr::left_join(
      data_schedule |>
        dplyr::select("repeat_id", "n_candidates_entering"),
      by = dplyr::join_by(repeat_id),
      relationship = "one-to-one"
    )

  flag_schedule_matches <-
    base::nrow(data_repeat_execution) == base::nrow(data_schedule) &&
    base::all(
      data_repeat_execution[["n_candidates_executed"]] ==
        data_repeat_execution[["n_candidates_entering"]]
    )

  if (
    !flag_schedule_matches
  ) {
    cli::cli_abort("Executed candidates do not match the tuning schedule.")
  }

  n_candidates_initial <-
    base::max(data_schedule[["n_candidates_entering"]])

  n_fold_partitions <-
    base::sum(data_repeat_execution[["n_folds"]])

  n_fits_exhaustive <-
    base::sum(
      data_repeat_execution[["n_folds"]] * n_candidates_initial
    )

  n_fits_executed <-
    base::nrow(data_tuning)

  n_fits_historical <-
    n_fits_exhaustive + n_fold_partitions

  res <-
    tibble::tibble(
      tuning_strategy = data_schedule[["tuning_strategy"]][[1L]],
      tuning_strategy_version =
        data_schedule[["strategy_version"]][[1L]],
      evaluation_prediction_source = "tuning_prediction_cache",
      work_item_identity_version = "sjsdm_cv_work_item_v1",
      restart_boundary = "repeat_fold_candidate",
      n_rounds = base::nrow(data_schedule),
      n_work_items_materialized =
        base::as.integer(n_work_items_materialized),
      n_fold_preparations = base::as.integer(n_fold_partitions),
      n_fits_executed = base::as.integer(n_fits_executed),
      n_successful_fits = base::sum(data_tuning[["fit_status"]] == "ok"),
      n_selected_refits_reused = base::as.integer(n_fold_partitions),
      n_fits_exhaustive = base::as.integer(n_fits_exhaustive),
      n_fits_historical = base::as.integer(n_fits_historical),
      fit_reduction_fraction =
        (n_fits_historical - n_fits_executed) /
        n_fits_historical
    )

  return(res)
}
