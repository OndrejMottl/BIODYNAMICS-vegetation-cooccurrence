#' @title Adapt Cross-Validation Assignments
#' @description
#' Replaces infeasible grouped folds with leave-one-location-out assignments
#' before an ID is classified for tier-pooled regularization.
#' @param data_locations
#' Location table returned by [make_cross_validation_location_table()].
#' @param data_assignments
#' Initial assignment table with `cv_strategy` and `assignment_source`.
#' @param data_partition_diagnostics
#' Initial diagnostics returned by
#' [make_cross_validation_partition_diagnostics()].
#' @param min_train_locations,min_train_samples,min_train_taxa,
#' min_mem_locations
#' Positive integer feasibility thresholds passed to
#' [assess_cross_validation_feasibility()].
#' @return
#' The initial assignment table when it is feasible or does not use grouped
#' folds. Infeasible grouped folds are replaced by leave-one-location-out
#' assignments with source `"leave_one_location_out_fallback"`.
#' @examples
#' data_locations <-
#'   tibble::tibble(
#'     location_id = base::letters[1:6],
#'     n_samples = base::rep(1L, 6L),
#'     row_indices = base::as.list(base::seq_len(6L))
#'   )
#' data_assignments <-
#'   tibble::tibble(
#'     repeat_id = base::integer(),
#'     fold_id = base::integer(),
#'     location_id = base::character(),
#'     grid_cell_id = base::character(),
#'     n_samples = base::integer(),
#'     row_indices = base::list(),
#'     cv_strategy = base::character(),
#'     assignment_source = base::character()
#'   )
#' data_diagnostics <-
#'   tibble::tibble(
#'     cv_strategy = "full_model",
#'     repeat_id = 0L,
#'     effective_folds = NA_integer_,
#'     fold_id = 0L,
#'     n_train_locations = 6L,
#'     n_train_samples = 6L,
#'     n_train_taxa = 1L,
#'     n_train_mem_locations = 6L
#'   )
#' adapt_cross_validation_assignments(
#'   data_locations = data_locations,
#'   data_assignments = data_assignments,
#'   data_partition_diagnostics = data_diagnostics,
#'   min_train_locations = 5L,
#'   min_train_samples = 1L,
#'   min_train_taxa = 1L,
#'   min_mem_locations = 4L
#' )
#' @export
adapt_cross_validation_assignments <- function(
    data_locations = NULL,
    data_assignments = NULL,
    data_partition_diagnostics = NULL,
    min_train_locations = NULL,
    min_train_samples = NULL,
    min_train_taxa = NULL,
    min_mem_locations = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_locations),
    base::nrow(data_locations) > 0L,
    msg = "`data_locations` must be a non-empty data frame."
  )

  assertthat::assert_that(
    base::is.data.frame(data_assignments),
    msg = "`data_assignments` must be a data frame."
  )

  assertthat::assert_that(
    base::all(
      base::c("cv_strategy", "assignment_source") %in%
        base::colnames(data_assignments)
    ),
    msg = "`data_assignments` is missing provenance columns."
  )

  data_initial_feasibility <-
    assess_cross_validation_feasibility(
      data_partition_diagnostics = data_partition_diagnostics,
      min_train_locations = min_train_locations,
      min_train_samples = min_train_samples,
      min_train_taxa = min_train_taxa,
      min_mem_locations = min_mem_locations
    )

  initial_strategy <-
    dplyr::first(
      dplyr::pull(data_assignments, "cv_strategy"),
      default = "none"
    )

  initial_feasibility_status <-
    data_initial_feasibility |>
    dplyr::pull("cv_feasibility_status")

  flag_requires_leave_one_out <-
    initial_strategy == "spatially_stratified_group_kfold" &&
    initial_feasibility_status ==
      "tier_pooled_regularization_required"

  if (
    !flag_requires_leave_one_out
  ) {
    return(data_assignments)
  }

  data_leave_one_out_assignments <-
    make_leave_one_location_out_assignments(
      data_locations = data_locations
    )

  res <-
    data_leave_one_out_assignments |>
    dplyr::mutate(
      cv_strategy = "leave_one_location_out",
      assignment_source = "leave_one_location_out_fallback"
    )

  return(res)
}
