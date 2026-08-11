#' @title Combine sjSDM Tuning Work Items
#' @description
#' Combines granular candidate/fold results into the established tuning table
#' and fold-organized compact prediction cache.
#' @param list_work_item_results
#' List of results from [run_sjsdm_tuning_work_item()].
#' @return
#' Named list with `data_tuning` and `list_prediction_cache`, matching the rich
#' return contract of [run_sjsdm_tuning_candidates()].
#' @export
aggregate_sjsdm_tuning_work_items <- function(
    list_work_item_results = NULL) {
  assertthat::assert_that(
    base::is.list(list_work_item_results),
    msg = "list_work_item_results must be a list."
  )

  flag_all_results_empty <-
    base::length(list_work_item_results) > 0L &&
    list_work_item_results |>
      purrr::map_lgl(
        ~ base::is.list(.x) &&
          base::is.data.frame(.x[["data_tuning"]]) &&
          base::nrow(.x[["data_tuning"]]) == 0L
      ) |>
      base::all()

  if (
    base::length(list_work_item_results) == 0L ||
      flag_all_results_empty
  ) {
    return(build_sjsdm_empty_tuning_result())
  }

  flag_valid_results <-
    list_work_item_results |>
    purrr::map_lgl(
      ~ base::is.list(.x) &&
        base::all(
          base::c(
            "work_item_id",
            "data_tuning",
            "list_prediction_cache"
          ) %in% base::names(.x)
        )
    ) |>
    base::all()

  assertthat::assert_that(
    flag_valid_results,
    msg = "A tuning work-item result is incomplete."
  )

  vec_work_item_ids <-
    purrr::map_chr(list_work_item_results, "work_item_id")

  if (
    base::any(base::duplicated(vec_work_item_ids))
  ) {
    cli::cli_abort("Tuning work-item identities must be unique.")
  }

  data_tuning <-
    list_work_item_results |>
    purrr::map("data_tuning") |>
    purrr::list_rbind() |>
    dplyr::arrange(
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["candidate_id"]]
    )

  list_cache_records <-
    purrr::map(list_work_item_results, "list_prediction_cache")

  data_cache_index <-
    tibble::tibble(
      cache_index = base::seq_along(list_cache_records),
      repeat_id = list_cache_records |>
        purrr::map_int(
          ~ .x[["list_fold_context"]][["repeat_id"]]
        ),
      fold_id = list_cache_records |>
        purrr::map_int(
          ~ .x[["list_fold_context"]][["fold_id"]]
        )
    )

  list_prediction_cache <-
    data_cache_index |>
    dplyr::group_by(.data[["repeat_id"]], .data[["fold_id"]]) |>
    dplyr::group_split() |>
    purrr::map(
      .f = function(data_fold_index) {
        vec_indices <-
          data_fold_index[["cache_index"]]

        list_fold_records <-
          list_cache_records[vec_indices]

        list_reference <-
          list_fold_records[[1L]]

        list_candidate_predictions <-
          list_fold_records |>
          purrr::map("list_candidate_predictions") |>
          purrr::list_flatten() |>
          purrr::keep(~ !base::is.null(.x))

        if (
          base::length(list_candidate_predictions) > 0L
        ) {
          vec_candidate_ids <-
            purrr::map_chr(
              list_candidate_predictions,
              "candidate_id"
            )

          list_candidate_predictions <-
            list_candidate_predictions[
              base::order(vec_candidate_ids)
            ]
        }

        return(
          base::list(
            list_fold_context =
              list_reference[["list_fold_context"]],
            list_prepared_fold =
              list_reference[["list_prepared_fold"]],
            preparation_seconds =
              list_reference[["preparation_seconds"]],
            list_candidate_predictions =
              list_candidate_predictions
          )
        )
      }
    )

  res <-
    base::list(
      data_tuning = data_tuning,
      list_prediction_cache = list_prediction_cache
    )

  return(res)
}
