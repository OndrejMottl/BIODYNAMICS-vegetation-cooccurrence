#' @title Make sjSDM Tuning Fold Context
#' @description
#' Converts one repeat and fold from location-level assignments into disjoint
#' training and test sample indices plus compact fold metadata.
#' @param data_assignments
#' Location-level assignment table containing `repeat_id`, `fold_id`,
#' `location_id`, `row_indices`, and optional `cv_strategy`.
#' @param repeat_id,fold_id
#' Positive integer identifiers selecting one held-out fold.
#' @return
#' Named list containing repeat and fold IDs, sorted train/test indices,
#' location and sample counts, and the CV strategy.
#' @export
make_sjsdm_tuning_fold_context <- function(
    data_assignments = NULL,
    repeat_id = NULL,
    fold_id = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_assignments),
    base::nrow(data_assignments) > 0L,
    msg = "`data_assignments` must be a non-empty data frame."
  )

  vec_required_columns <-
    base::c("repeat_id", "fold_id", "location_id", "row_indices")

  assertthat::assert_that(
    base::all(
      vec_required_columns %in% base::colnames(data_assignments)
    ),
    msg = "`data_assignments` is missing required columns."
  )

  vec_selected_ids <-
    base::c(repeat_id, fold_id)

  assertthat::assert_that(
    base::is.numeric(vec_selected_ids),
    base::length(vec_selected_ids) == 2L,
    base::all(base::is.finite(vec_selected_ids)),
    base::all(vec_selected_ids >= 1L),
    base::all(vec_selected_ids == base::as.integer(vec_selected_ids)),
    msg = "`repeat_id` and `fold_id` must be positive integers."
  )

  assertthat::assert_that(
    base::is.list(data_assignments[["row_indices"]]),
    msg = "`row_indices` must be a list column."
  )

  repeat_id <-
    base::as.integer(repeat_id)

  fold_id <-
    base::as.integer(fold_id)

  data_repeat_assignments <-
    data_assignments |>
    dplyr::filter(.data[["repeat_id"]] == .env[["repeat_id"]])

  data_test_assignments <-
    data_repeat_assignments |>
    dplyr::filter(.data[["fold_id"]] == .env[["fold_id"]])

  data_train_assignments <-
    data_repeat_assignments |>
    dplyr::filter(.data[["fold_id"]] != .env[["fold_id"]])

  vec_train_indices <-
    data_train_assignments[["row_indices"]] |>
    base::unlist(use.names = FALSE) |>
    base::as.integer() |>
    base::sort()

  vec_test_indices <-
    data_test_assignments[["row_indices"]] |>
    base::unlist(use.names = FALSE) |>
    base::as.integer() |>
    base::sort()

  if (
    base::nrow(data_train_assignments) == 0L ||
      base::nrow(data_test_assignments) == 0L ||
      base::length(vec_train_indices) == 0L ||
      base::length(vec_test_indices) == 0L ||
      base::any(base::is.na(vec_train_indices)) ||
      base::any(base::is.na(vec_test_indices)) ||
      base::any(vec_train_indices < 1L) ||
      base::any(vec_test_indices < 1L) ||
      base::any(base::duplicated(vec_train_indices)) ||
      base::any(base::duplicated(vec_test_indices)) ||
      base::length(
        base::intersect(vec_train_indices, vec_test_indices)
      ) > 0L
  ) {
    cli::cli_abort(
      "Fold row indices must be positive, unique, and disjoint."
    )
  }

  vec_cv_strategies <-
    if (
      "cv_strategy" %in% base::colnames(data_repeat_assignments)
    ) {
      base::unique(data_repeat_assignments[["cv_strategy"]])
    } else {
      NA_character_
    }

  if (
    base::length(vec_cv_strategies) != 1L
  ) {
    cli::cli_abort("Each repeat must use one CV strategy.")
  }

  res <-
    base::list(
      repeat_id = repeat_id,
      fold_id = fold_id,
      train_indices = vec_train_indices,
      test_indices = vec_test_indices,
      n_train_locations = base::nrow(data_train_assignments),
      n_test_locations = base::nrow(data_test_assignments),
      n_train_samples = base::length(vec_train_indices),
      n_test_samples = base::length(vec_test_indices),
      cv_strategy = base::as.character(vec_cv_strategies[[1L]])
    )

  return(res)
}
