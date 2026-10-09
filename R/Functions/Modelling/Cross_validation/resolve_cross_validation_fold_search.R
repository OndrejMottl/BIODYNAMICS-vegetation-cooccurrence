#' @title Resolve a Feasible Grouped Cross-Validation Design
#' @description
#' Preserves feasible initial assignments, otherwise tests increasing grouped
#' fold counts before the existing leave-one-location-out fallback. No models
#' are fitted during this search and no feasibility threshold is relaxed.
#' @param data_locations,data_assignments,data_partition_diagnostics
#' Initial location, assignment, and training-partition diagnostic tables.
#' @param data_community_matrix
#' Binary response matrix aligned with location row indices.
#' @param config_data_processing
#' Processing configuration with `min_n_cores`, `min_n_samples`, `min_n_taxa`.
#' @param config_cross_validation
#' CV controls including MEM threshold, repeats, assignment seed, and grid.
#' @param grouped_fold_ladder
#' Strictly increasing unique integer fold counts, all at least two.
#' @param verbose
#' Logical. Print selected design and candidate-fold task estimates if TRUE.
#' @return
#' Named list containing unchanged-schema `data_assignments`, attempt-level
#' `data_fold_search`, partition-level `data_partition_diagnostics_search`,
#' and the configured `vec_grouped_fold_ladder`.
#' Failed grids are recorded; unexpected errors propagate. All configured
#' repeats must pass. The search never tries counts at or above location count.
#' @examples
#' \dontrun{
#' list_search <-
#'   resolve_cross_validation_fold_search(
#'     data_locations = data_cross_validation_locations,
#'     data_assignments = data_cross_validation_assignments_initial,
#'     data_partition_diagnostics =
#'       data_cross_validation_partition_diagnostics_initial,
#'     data_community_matrix = data_community_filtered,
#'     config_data_processing = config_data_processing,
#'     config_cross_validation = config_model_fitting[["cross_validation"]]
#'   )
#' }
#' @export
resolve_cross_validation_fold_search <- function(
    data_locations = NULL,
    data_assignments = NULL,
    data_partition_diagnostics = NULL,
    data_community_matrix = NULL,
    config_data_processing = NULL,
    config_cross_validation = NULL,
    grouped_fold_ladder = base::c(5L, 10L, 20L, 50L),
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.numeric(grouped_fold_ladder),
    base::length(grouped_fold_ladder) > 0L,
    base::all(base::is.finite(grouped_fold_ladder)),
    base::all(grouped_fold_ladder >= 2L),
    base::all(grouped_fold_ladder == base::floor(grouped_fold_ladder)),
    base::all(base::diff(grouped_fold_ladder) > 0),
    msg = "`grouped_fold_ladder` must contain increasing integer counts >= 2."
  )
  assertthat::assert_that(
    base::is.logical(verbose),
    base::length(verbose) == 1L,
    !base::is.na(verbose),
    msg = "`verbose` must be TRUE or FALSE."
  )
  min_train_locations <-
    purrr::chuck(config_data_processing, "min_n_cores")
  min_train_samples <-
    purrr::chuck(config_data_processing, "min_n_samples")
  min_train_taxa <-
    purrr::chuck(config_data_processing, "min_n_taxa")
  min_mem_locations <-
    purrr::chuck(config_cross_validation, "min_mem_locations")
  data_initial_feasibility <-
    resolve_cross_validation_strategy(
      data_partition_diagnostics = data_partition_diagnostics,
      min_train_locations = min_train_locations,
      min_train_samples = min_train_samples,
      min_train_taxa = min_train_taxa,
      min_mem_locations = min_mem_locations
    )
  strategy_initial <-
    dplyr::first(data_assignments[["cv_strategy"]], default = "none")
  n_initial_folds <-
    dplyr::n_distinct(data_assignments[["fold_id"]])
  if (
    strategy_initial == "spatially_stratified_group_kfold"
  ) {
    assertthat::assert_that(
      base::identical(
        base::sort(base::unique(data_assignments[["repeat_id"]])),
        base::seq_len(
          purrr::chuck(config_cross_validation, "assignment_repeats")
        )
      ),
      msg = "Initial grouped assignments must cover every configured repeat."
    )
  }
  flag_search_required <-
    strategy_initial == "spatially_stratified_group_kfold" &&
      data_initial_feasibility[["cv_feasibility_status"]] ==
        "tier_pooled_regularization_required"
  data_initial_attempt <-
    tibble::tibble(
      attempt = 1L,
      effective_folds = base::as.integer(n_initial_folds),
      cv_strategy = strategy_initial,
      assignment_source = dplyr::first(
        data_assignments[["assignment_source"]], default = "none"
      ),
      n_partitions = base::sum(
        data_partition_diagnostics[["repeat_id"]] > 0L
      ),
      cv_feasibility_status =
        data_initial_feasibility[["cv_feasibility_status"]],
      selected = !flag_search_required,
      policy_version = "grouped_fold_ladder_v1"
    )
  vec_candidate_folds <-
    grouped_fold_ladder[
      grouped_fold_ladder > n_initial_folds &
        grouped_fold_ladder < base::nrow(data_locations)
    ] |>
    base::as.integer()
  list_attempts <-
    base::vector("list", base::length(vec_candidate_folds) + 2L)
  list_diagnostics <-
    base::vector("list", base::length(vec_candidate_folds) + 2L)
  list_attempts[[1L]] <- data_initial_attempt
  list_diagnostics[[1L]] <-
    dplyr::mutate(data_partition_diagnostics, attempt = 1L)
  data_assignments_selected <- data_assignments
  flag_selected <- !flag_search_required
  n_attempts <- 1L
  if (
    flag_search_required
  ) {
    config_grid <-
      purrr::chuck(config_cross_validation, "grid")
    for (
      n_folds_candidate in vec_candidate_folds
    ) {
      n_attempts <- n_attempts + 1L
      data_resolution_candidate <-
        tibble::tibble(
          cv_strategy = "spatially_stratified_group_kfold",
          effective_folds = n_folds_candidate
        )
      data_grid_candidates <-
        build_cross_validation_grid_candidates_from_resolution(
          data_locations = data_locations,
          data_fold_resolution = data_resolution_candidate,
          target_locations_per_cell =
            purrr::chuck(config_grid, "target_locations_per_cell"),
          grid_size_multipliers =
            purrr::chuck(config_grid, "size_multipliers")
        )
      data_grid_calibration <-
        compute_cross_validation_grid_calibration_from_resolution(
          data_locations = data_locations,
          data_fold_resolution = data_resolution_candidate,
          candidate_grid_cell_sizes_km =
            data_grid_candidates[["grid_cell_size_km"]],
          n_repeats =
            purrr::chuck(config_cross_validation, "assignment_repeats"),
          occupancy_criterion =
            purrr::chuck(config_grid, "occupancy_criterion"),
          target_locations_per_cell =
            purrr::chuck(config_grid, "target_locations_per_cell"),
          lower_quantile_probability =
            purrr::chuck(config_grid, "lower_quantile_probability"),
          max_fold_location_difference =
            purrr::chuck(config_grid, "max_fold_location_difference"),
          max_fold_sample_difference =
            purrr::chuck(config_grid, "max_fold_sample_difference"),
          seed = purrr::chuck(config_cross_validation, "assignment_seed")
        )
      if (
        !base::any(data_grid_calibration[["selected"]], na.rm = TRUE)
      ) {
        list_attempts[[n_attempts]] <-
          tibble::tibble(
            attempt = n_attempts,
            effective_folds = n_folds_candidate,
            cv_strategy = "spatially_stratified_group_kfold",
            assignment_source = "grouped_fold_ladder_fallback",
            n_partitions = 0L,
            cv_feasibility_status = "no_eligible_grid",
            selected = FALSE,
            policy_version = "grouped_fold_ladder_v1"
          )
        next
      }
      data_assignments_candidate <-
        build_cross_validation_assignments_from_resolution(
          data_locations = data_locations,
          data_fold_resolution = data_resolution_candidate,
          data_grid_calibration = data_grid_calibration,
          n_repeats =
            purrr::chuck(config_cross_validation, "assignment_repeats"),
          seed = purrr::chuck(config_cross_validation, "assignment_seed"),
          assignment_source = "grouped_fold_ladder_fallback"
        )
      data_diagnostics_candidate <-
        diagnose_cross_validation_partitions(
          data_locations = data_locations,
          data_assignments = data_assignments_candidate,
          data_community_matrix = data_community_matrix,
          cv_strategy = "spatially_stratified_group_kfold",
          min_taxon_locations = min_train_locations,
          min_taxon_samples = min_train_samples
        )
      data_feasibility_candidate <-
        resolve_cross_validation_strategy(
          data_partition_diagnostics = data_diagnostics_candidate,
          min_train_locations = min_train_locations,
          min_train_samples = min_train_samples,
          min_train_taxa = min_train_taxa,
          min_mem_locations = min_mem_locations
        )
      flag_candidate_feasible <-
        base::isTRUE(
          data_feasibility_candidate[["grouped_kfold_feasible"]]
        ) &&
          dplyr::n_distinct(data_assignments_candidate[["repeat_id"]]) ==
            purrr::chuck(config_cross_validation, "assignment_repeats")
      list_attempts[[n_attempts]] <-
        tibble::tibble(
          attempt = n_attempts,
          effective_folds = n_folds_candidate,
          cv_strategy = "spatially_stratified_group_kfold",
          assignment_source = "grouped_fold_ladder_fallback",
          n_partitions = base::nrow(data_diagnostics_candidate) - 1L,
          cv_feasibility_status =
            data_feasibility_candidate[["cv_feasibility_status"]],
          selected = flag_candidate_feasible,
          policy_version = "grouped_fold_ladder_v1"
        )
      list_diagnostics[[n_attempts]] <-
        dplyr::mutate(data_diagnostics_candidate, attempt = n_attempts)
      if (
        flag_candidate_feasible
      ) {
        data_assignments_selected <- data_assignments_candidate
        flag_selected <- TRUE
        break
      }
    }
    if (
      !flag_selected
    ) {
      data_assignments_selected <-
        resolve_cross_validation_assignments(
          data_locations = data_locations,
          data_assignments = data_assignments,
          data_partition_diagnostics = data_partition_diagnostics,
          min_train_locations = min_train_locations,
          min_train_samples = min_train_samples,
          min_train_taxa = min_train_taxa,
          min_mem_locations = min_mem_locations
        )
      data_diagnostics_leave_one_out <-
        diagnose_cross_validation_partitions(
          data_locations = data_locations,
          data_assignments = data_assignments_selected,
          data_community_matrix = data_community_matrix,
          cv_strategy = "leave_one_location_out",
          min_taxon_locations = min_train_locations,
          min_taxon_samples = min_train_samples
        )
      data_feasibility_leave_one_out <-
        resolve_cross_validation_strategy(
          data_partition_diagnostics = data_diagnostics_leave_one_out,
          min_train_locations = min_train_locations,
          min_train_samples = min_train_samples,
          min_train_taxa = min_train_taxa,
          min_mem_locations = min_mem_locations
        )
      n_attempts <- n_attempts + 1L
      list_attempts[[n_attempts]] <-
        tibble::tibble(
          attempt = n_attempts,
          effective_folds = base::as.integer(base::nrow(data_locations)),
          cv_strategy = "leave_one_location_out",
          assignment_source = "leave_one_location_out_fallback",
          n_partitions = base::nrow(data_locations),
          cv_feasibility_status =
            data_feasibility_leave_one_out[["cv_feasibility_status"]],
          selected = TRUE,
          policy_version = "grouped_fold_ladder_v1"
        )
      list_diagnostics[[n_attempts]] <-
        dplyr::mutate(data_diagnostics_leave_one_out, attempt = n_attempts)
    }
  }
  data_diagnostics_search <-
    purrr::list_rbind(list_diagnostics) |>
    dplyr::mutate(
      flag_locations_pass = .data[["n_train_locations"]] >=
        min_train_locations,
      flag_samples_pass = .data[["n_train_samples"]] >= min_train_samples,
      flag_taxa_pass = .data[["n_train_taxa"]] >= min_train_taxa,
      flag_mem_pass = .data[["n_train_mem_locations"]] >= min_mem_locations
    )
  res <-
    base::list(
      data_assignments = data_assignments_selected,
      data_fold_search = purrr::list_rbind(list_attempts),
      data_partition_diagnostics_search = data_diagnostics_search,
      vec_grouped_fold_ladder = grouped_fold_ladder
    )
  if (
    verbose
  ) {
    strategy_selected <-
      dplyr::first(data_assignments_selected[["cv_strategy"]],
        default = "none")
    n_folds_selected <-
      dplyr::n_distinct(data_assignments_selected[["fold_id"]])
    cli::cli_inform(stringr::str_glue(
      "CV design: {strategy_selected}; {n_folds_selected} folds."
    ))
    if (
      strategy_selected != "none" &&
        !base::is.null(config_cross_validation[["regularization"]])
    ) {
      n_candidates <-
        config_cross_validation[["regularization"]] |>
        purrr::map_int(base::length) |>
        base::prod()
      data_schedule <-
        build_sjsdm_tuning_schedule(
          tuning_strategy =
            purrr::chuck(config_cross_validation, "tuning_strategy"),
          n_candidates = n_candidates,
          repeat_ids = base::seq_len(
            purrr::chuck(config_cross_validation, "assignment_repeats")
          ),
          survivor_counts = purrr::pluck(
            config_cross_validation, "staged_search", "survivor_counts"
          ),
          cv_strategy = strategy_selected
        )
      n_tasks <-
        base::sum(data_schedule[["n_candidates_entering"]]) *
          n_folds_selected
      cli::cli_inform(stringr::str_glue(
        "Tuning plan: {n_tasks} candidate-fold tasks before escalation."
      ))
    }
  }
  return(res)
}
