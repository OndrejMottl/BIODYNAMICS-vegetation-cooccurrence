#' @title Prepare sjSDM Tuning Folds
#' @description
#' Prepares every repeat/fold partition exactly once for reuse by granular
#' candidate work items.
#' @param data_assignments
#' Cross-validation assignments accepted by
#' [run_sjsdm_tuning_candidates()].
#' @param cached_folds_function
#' Optional zero-argument reader of prior fold records. Current folds are
#' always prepared first. Successful analytically identical records reuse
#' the original cached object, retaining its operational measurements.
#' Unreadable or analytically different caches are ignored.
#' @param prepare_fold_function
#' Injectable preparation function documented by
#' [run_sjsdm_tuning_candidates()].
#' @return
#' List with one keyed entry per fold. Each entry contains fold context,
#' preparation timing, and either the prepared inputs or a structured error.
#' @details
#' Exact equality uses the version-five calibration content contract. Only
#' operational timing and spatial memory measurements are excluded; all
#' analytical fields and fold contexts remain part of the comparison.
#' @examples
#' \dontrun{
#' prepare_sjsdm_tuning_folds(
#'   data_assignments = assignments,
#'   prepare_fold_function = prepare_fold
#' )
#' }
#' @export
prepare_sjsdm_tuning_folds <- function(
    data_assignments = NULL,
    prepare_fold_function = NULL,
    cached_folds_function = NULL) {
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
  assertthat::assert_that(
    base::is.null(cached_folds_function) ||
      base::is.function(cached_folds_function),
    msg = "Cached folds reader must be NULL or a function."
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

  if (
    base::is.function(cached_folds_function) &&
      base::all(purrr::map_chr(list_folds, "preparation_status") == "ok")
  ) {
    # Compare complete analytical records, never work-item IDs or counts.
    # Returning the old object preserves its genuine historical measurements
    # and its target data hash without modifying target metadata directly.
    list_cached_folds <-
      base::tryCatch(
        expr = cached_folds_function(),
        error = function(error_condition) NULL
      )
    flag_identical_content <-
      base::tryCatch(
        expr = base::is.list(list_cached_folds) &&
          purrr::every(list_cached_folds, ~ {
            elapsed <-
              purrr::pluck(.x, "preparation_seconds", .default = NA_real_)
            base::is.numeric(elapsed) && base::length(elapsed) == 1L &&
              base::is.finite(elapsed) && elapsed >= 0
          }) && base::identical(
          prepare_sjsdm_cv_calibration_hash_folds(
            list_prepared_folds = list_folds,
            contract_version = "v5"
          ),
          prepare_sjsdm_cv_calibration_hash_folds(
            list_prepared_folds = list_cached_folds,
            contract_version = "v5"
          )
        ),
        error = function(error_condition) FALSE
      )
    if (
      base::isTRUE(flag_identical_content)
    ) {
      return(list_cached_folds)
    }
  }

  return(list_folds)
}
