#' @title Aggregate sjSDM Tuning Fit Attempts
#' @description
#' Extracts and combines candidate attempt provenance from the compact tuning
#' prediction cache.
#' @param list_prediction_cache
#' Fold-organized prediction cache from
#' [aggregate_sjsdm_tuning_work_items()].
#' @return
#' Attempt-level tibble ordered by repeat, fold, candidate, and attempt.
#' @examples
#' aggregate_sjsdm_tuning_fit_attempts(base::list())
#' @export
aggregate_sjsdm_tuning_fit_attempts <- function(
    list_prediction_cache = NULL) {
  assertthat::assert_that(
    base::is.list(list_prediction_cache),
    msg = "list_prediction_cache must be a list."
  )

  data_empty <-
    tibble::tibble(
      candidate_id = base::character(),
      repeat_id = base::integer(),
      fold_id = base::integer(),
      attempt = base::integer(),
      n_iter_budget = base::integer(),
      n_sampling = base::integer(),
      epochs_run = base::integer(),
      linear_trend_slope = base::numeric(),
      median_diff = base::numeric(),
      converged = base::logical(),
      early_stopping_triggered = base::logical(),
      runtime_seconds = base::numeric(),
      fit_seed = base::integer(),
      fit_status = base::character(),
      error_message = base::character()
    )

  if (
    base::length(list_prediction_cache) == 0L
  ) {
    return(data_empty)
  }

  list_attempts <-
    list_prediction_cache |>
    purrr::map("list_candidate_predictions") |>
    purrr::list_flatten() |>
    purrr::map("data_fit_attempts") |>
    purrr::keep(~ base::is.data.frame(.x) && base::nrow(.x) > 0L)

  if (
    base::length(list_attempts) == 0L
  ) {
    return(data_empty)
  }

  res <-
    list_attempts |>
    purrr::list_rbind() |>
    dplyr::arrange(
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["candidate_id"]],
      .data[["attempt"]]
    )

  return(res)
}
