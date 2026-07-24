#' @title Collect sjSDM Tuning Stage Timings
#' @description
#' Converts compact fold prediction caches into a long timing table for fold
#' preparation, fitting, prediction, and scoring stages.
#' @param list_prediction_cache
#' Fold caches returned by [run_sjsdm_tuning_candidates()] when prediction
#' caching is enabled.
#' @return
#' Long tibble with repeat, fold, optional candidate, stage, elapsed seconds,
#' and execution status.
#' @examples
#' \dontrun{
#' collect_sjsdm_tuning_timings(list_sjsdm_tuning_prediction_cache)
#' }
#' @export
collect_sjsdm_tuning_timings <- function(list_prediction_cache = NULL) {
  assertthat::assert_that(
    base::is.list(list_prediction_cache),
    msg = "list_prediction_cache must be a list."
  )

  if (
    base::length(list_prediction_cache) == 0L
  ) {
    return(
      tibble::tibble(
        repeat_id = base::integer(),
        fold_id = base::integer(),
        candidate_id = base::character(),
        stage = base::character(),
        elapsed_seconds = base::numeric(),
        execution_status = base::character()
      )
    )
  }

  res <-
    list_prediction_cache |>
    purrr::map(
      .f = ~ {
        list_context <-
          .x[["list_fold_context"]]

        data_preparation <-
          tibble::tibble(
            repeat_id = list_context[["repeat_id"]],
            fold_id = list_context[["fold_id"]],
            candidate_id = NA_character_,
            stage = "preparation",
            elapsed_seconds = .x[["preparation_seconds"]],
            execution_status = dplyr::if_else(
              base::is.null(.x[["list_prepared_fold"]]),
              "error",
              "ok"
            )
          )

        data_candidates <-
          .x[["list_candidate_predictions"]] |>
          purrr::map(
            .f = ~ tibble::tibble(
              repeat_id = list_context[["repeat_id"]],
              fold_id = list_context[["fold_id"]],
              candidate_id = .x[["candidate_id"]],
              stage = base::c("fit", "prediction", "scoring"),
              elapsed_seconds = base::c(
                .x[["fit_seconds"]],
                .x[["prediction_seconds"]],
                .x[["scoring_seconds"]]
              ),
              execution_status = .x[["fit_status"]]
            )
          ) |>
          purrr::list_rbind()

        return(
          dplyr::bind_rows(data_preparation, data_candidates)
        )
      }
    ) |>
    purrr::list_rbind() |>
    dplyr::arrange(
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["candidate_id"]],
      .data[["stage"]]
    )

  return(res)
}
