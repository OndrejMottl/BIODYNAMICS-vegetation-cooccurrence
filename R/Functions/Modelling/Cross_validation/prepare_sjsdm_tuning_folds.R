#' @title Prepare sjSDM Tuning Folds
#' @description
#' Prepares every repeat/fold partition exactly once for reuse by granular
#' candidate work items.
#' @param data_assignments
#' Cross-validation assignments accepted by
#' [run_sjsdm_tuning_candidates()].
#' @param prepare_fold_function
#' Injectable preparation function documented by
#' [run_sjsdm_tuning_candidates()].
#' @return
#' List with one keyed entry per fold. Each entry contains fold context,
#' preparation timing, and either the prepared inputs or a structured error.
#' @export
prepare_sjsdm_tuning_folds <- function(
    data_assignments = NULL,
    prepare_fold_function = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_assignments),
    base::all(
      base::c(
        "repeat_id",
        "fold_id",
        "location_id",
        "n_samples",
        "row_indices"
      ) %in% base::colnames(data_assignments)
    ),
    base::is.function(prepare_fold_function),
    msg = "Fold-preparation inputs are incomplete."
  )

  data_fold_keys <-
    data_assignments |>
    dplyr::distinct(.data[["repeat_id"]], .data[["fold_id"]]) |>
    dplyr::arrange(.data[["repeat_id"]], .data[["fold_id"]])

  list_folds <-
    purrr::map2(
      .x = data_fold_keys[["repeat_id"]],
      .y = data_fold_keys[["fold_id"]],
      .f = function(repeat_id, fold_id) {
        list_fold_context <-
          build_sjsdm_tuning_fold_context(
            data_assignments = data_assignments,
            repeat_id = repeat_id,
            fold_id = fold_id
          )

        preparation_started <-
          base::proc.time()[["elapsed"]]

        list_prepared_fold <-
          tryCatch(
            expr = prepare_fold_function(
              train_indices = list_fold_context[["train_indices"]],
              test_indices = list_fold_context[["test_indices"]],
              repeat_id = repeat_id,
              fold_id = fold_id
            ),
            error = function(error_condition) {
              error_condition
            }
          )

        preparation_seconds <-
          base::proc.time()[["elapsed"]] - preparation_started

        flag_preparation_error <-
          base::inherits(list_prepared_fold, "error")

        return(
          base::list(
            fold_key = stringr::str_glue(
              "repeat_{stringr::str_pad(repeat_id, 3L, 'left', '0')}__",
              "fold_{stringr::str_pad(fold_id, 3L, 'left', '0')}"
            ),
            list_fold_context = list_fold_context,
            list_prepared_fold = if (
              flag_preparation_error
            ) {
              NULL
            } else {
              list_prepared_fold
            },
            preparation_seconds = preparation_seconds,
            preparation_status = if (
              flag_preparation_error
            ) {
              "preparation_error"
            } else {
              "ok"
            },
            error_message = if (
              flag_preparation_error
            ) {
              base::conditionMessage(list_prepared_fold)
            } else {
              NA_character_
            }
          )
        )
      }
    )

  base::names(list_folds) <-
    purrr::map_chr(list_folds, "fold_key")

  return(list_folds)
}
