#' @title Calibrate Cross-Validation Grid Size
#' @description
#' Compares candidate spatial-grid sizes using occupied-cell density and fold
#' balance, then marks the finest eligible candidate.
#' @param data_locations
#' Location table returned by [make_cross_validation_location_table()].
#' @param candidate_grid_cell_sizes_km
#' Numeric vector of unique positive candidate grid-cell widths in kilometres.
#' @param n_folds
#' Single integer greater than one and no greater than the location count.
#' @param n_repeats
#' Single positive integer used to evaluate deterministic origin shifts.
#' @param occupancy_criterion
#' Character scalar: `"minimum"`, `"lower_quantile"`, or `"median"`.
#' @param target_locations_per_cell
#' Positive numeric occupancy target. Defaults to `n_folds` when `NULL`.
#' @param lower_quantile_probability
#' Probability used by `"lower_quantile"`, between zero and `0.5`. Defaults
#' to `0.25`.
#' @param max_fold_location_difference
#' Maximum allowed difference between the largest and smallest fold location
#' counts within any repeat. Defaults to `1L`.
#' @param max_fold_sample_difference
#' Maximum allowed difference between fold sample counts within any repeat.
#' Defaults to `Inf` so it is diagnostic until calibrated explicitly.
#' @param seed
#' Single non-negative integer assignment seed. Defaults to `900723L`.
#' @return
#' Tibble with one row per candidate grid size, occupancy and balance
#' diagnostics, eligibility, selection status, and a single `selected` flag
#' when at least one candidate is eligible.
#' @details
#' Candidate assignments use [make_spatial_cross_validation_assignments()].
#' Eligibility requires the configured occupancy statistic and both balance
#' thresholds. Among eligible candidates, the smallest cell size is selected.
#' @examples
#' data_locations <-
#'   tibble::tibble(
#'     location_id = letters[1:6],
#'     coord_x_km = c(0, 1, 2, 10, 11, 12),
#'     coord_y_km = rep(0, 6),
#'     n_samples = rep(1L, 6),
#'     row_indices = as.list(seq_len(6L))
#'   )
#' calibrate_cross_validation_grid_size(
#'   data_locations = data_locations,
#'   candidate_grid_cell_sizes_km = c(1, 10),
#'   n_folds = 3L
#' )
#' @export
calibrate_cross_validation_grid_size <- function(
    data_locations = NULL,
    candidate_grid_cell_sizes_km = NULL,
    n_folds = 5L,
    n_repeats = 1L,
    occupancy_criterion = "median",
    target_locations_per_cell = NULL,
    lower_quantile_probability = 0.25,
    max_fold_location_difference = 1L,
    max_fold_sample_difference = Inf,
    seed = 900723L) {
  assertthat::assert_that(
    base::is.data.frame(data_locations),
    base::nrow(data_locations) > 0L,
    msg = "`data_locations` must be a non-empty data frame."
  )

  assertthat::assert_that(
    base::is.numeric(candidate_grid_cell_sizes_km),
    base::length(candidate_grid_cell_sizes_km) > 0L,
    base::all(base::is.finite(candidate_grid_cell_sizes_km)),
    base::all(candidate_grid_cell_sizes_km > 0),
    !base::any(base::duplicated(candidate_grid_cell_sizes_km)),
    msg = stringr::str_c(
      "`candidate_grid_cell_sizes_km` must contain unique positive",
      " ",
      "finite numbers."
    )
  )

  flag_valid_n_folds <-
    base::is.numeric(n_folds) &&
    base::length(n_folds) == 1L &&
    base::is.finite(n_folds) &&
    n_folds >= 2L &&
    n_folds <= base::nrow(data_locations) &&
    n_folds == base::as.integer(n_folds)

  assertthat::assert_that(
    flag_valid_n_folds,
    msg = "`n_folds` must be a valid integer for the location count."
  )

  flag_valid_n_repeats <-
    base::is.numeric(n_repeats) &&
    base::length(n_repeats) == 1L &&
    base::is.finite(n_repeats) &&
    n_repeats >= 1L &&
    n_repeats == base::as.integer(n_repeats)

  assertthat::assert_that(
    flag_valid_n_repeats,
    msg = "`n_repeats` must be a single positive integer."
  )

  vec_supported_criteria <-
    base::c("minimum", "lower_quantile", "median")

  assertthat::assert_that(
    base::is.character(occupancy_criterion),
    base::length(occupancy_criterion) == 1L,
    occupancy_criterion %in% vec_supported_criteria,
    msg = "`occupancy_criterion` is not supported."
  )

  target_locations_per_cell_value <-
    if (
      base::is.null(target_locations_per_cell)
    ) {
      base::as.numeric(n_folds)
    } else {
      target_locations_per_cell
    }

  flag_valid_occupancy_target <-
    base::is.numeric(target_locations_per_cell_value) &&
    base::length(target_locations_per_cell_value) == 1L &&
    base::is.finite(target_locations_per_cell_value) &&
    target_locations_per_cell_value > 0

  assertthat::assert_that(
    flag_valid_occupancy_target,
    msg = "`target_locations_per_cell` must be a positive number."
  )

  flag_valid_quantile_probability <-
    base::is.numeric(lower_quantile_probability) &&
    base::length(lower_quantile_probability) == 1L &&
    base::is.finite(lower_quantile_probability) &&
    lower_quantile_probability >= 0 &&
    lower_quantile_probability <= 0.5

  assertthat::assert_that(
    flag_valid_quantile_probability,
    msg = stringr::str_c(
      "`lower_quantile_probability` must be a number between zero",
      " ",
      "and 0.5."
    )
  )

  flag_valid_location_difference <-
    base::is.numeric(max_fold_location_difference) &&
    base::length(max_fold_location_difference) == 1L &&
    base::is.finite(max_fold_location_difference) &&
    max_fold_location_difference >= 0

  assertthat::assert_that(
    flag_valid_location_difference,
    msg = "`max_fold_location_difference` must be non-negative."
  )

  flag_valid_sample_difference <-
    base::is.numeric(max_fold_sample_difference) &&
    base::length(max_fold_sample_difference) == 1L &&
    !base::is.na(max_fold_sample_difference) &&
    max_fold_sample_difference >= 0

  assertthat::assert_that(
    flag_valid_sample_difference,
    msg = "`max_fold_sample_difference` must be non-negative."
  )

  vec_candidate_grid_sizes <-
    candidate_grid_cell_sizes_km |>
    base::as.numeric() |>
    base::sort()

  n_folds_integer <-
    base::as.integer(n_folds)

  n_repeats_integer <-
    base::as.integer(n_repeats)

  data_candidate_diagnostics <-
    vec_candidate_grid_sizes |>
    purrr::map(
      .f = ~ {
        grid_cell_size <- .x

        data_assignments <-
          make_spatial_cross_validation_assignments(
            data_locations = data_locations,
            n_folds = n_folds_integer,
            n_repeats = n_repeats_integer,
            grid_cell_size_km = grid_cell_size,
            seed = seed
          )

        data_cell_counts <-
          data_assignments |>
          dplyr::count(
            .data[["repeat_id"]],
            .data[["grid_cell_id"]],
            name = "n_locations"
          )

        data_occupied_cells_by_repeat <-
          data_cell_counts |>
          dplyr::count(
            .data[["repeat_id"]],
            name = "n_occupied_cells"
          )

        data_fold_counts <-
          data_assignments |>
          dplyr::group_by(
            .data[["repeat_id"]],
            .data[["fold_id"]]
          ) |>
          dplyr::summarise(
            n_locations = dplyr::n(),
            n_samples = base::sum(.data[["n_samples"]]),
            .groups = "drop"
          )

        data_balance_by_repeat <-
          data_fold_counts |>
          dplyr::group_by(.data[["repeat_id"]]) |>
          dplyr::summarise(
            fold_location_difference =
              base::max(.data[["n_locations"]]) -
              base::min(.data[["n_locations"]]),
            fold_sample_difference =
              base::max(.data[["n_samples"]]) -
              base::min(.data[["n_samples"]]),
            .groups = "drop"
          )

        minimum_locations_per_cell <-
          base::min(data_cell_counts[["n_locations"]])

        lower_quantile_locations_per_cell <-
          stats::quantile(
            data_cell_counts[["n_locations"]],
            probs = lower_quantile_probability,
            names = FALSE
          ) |>
          base::as.numeric()

        median_locations_per_cell <-
          stats::median(data_cell_counts[["n_locations"]])

        occupancy_value <-
          dplyr::case_when(
            occupancy_criterion == "minimum" ~
              base::as.numeric(minimum_locations_per_cell),
            occupancy_criterion == "lower_quantile" ~
              lower_quantile_locations_per_cell,
            .default = base::as.numeric(median_locations_per_cell)
          )

        maximum_location_difference <-
          base::max(
            data_balance_by_repeat[["fold_location_difference"]]
          )

        maximum_sample_difference <-
          base::max(
            data_balance_by_repeat[["fold_sample_difference"]]
          )

        tibble::tibble(
          grid_cell_size_km = grid_cell_size,
          mean_occupied_cells = base::mean(
            data_occupied_cells_by_repeat[["n_occupied_cells"]]
          ),
          minimum_locations_per_cell = minimum_locations_per_cell,
          lower_quantile_locations_per_cell =
            lower_quantile_locations_per_cell,
          median_locations_per_cell = median_locations_per_cell,
          occupancy_criterion = occupancy_criterion,
          occupancy_value = occupancy_value,
          target_locations_per_cell = target_locations_per_cell_value,
          maximum_fold_location_difference =
            maximum_location_difference,
          maximum_fold_sample_difference = maximum_sample_difference,
          eligible =
            occupancy_value >= target_locations_per_cell_value &&
            maximum_location_difference <=
              max_fold_location_difference &&
            maximum_sample_difference <= max_fold_sample_difference
        )
      }
    ) |>
    purrr::list_rbind()

  vec_eligible_grid_sizes <-
    data_candidate_diagnostics |>
    dplyr::filter(.data[["eligible"]]) |>
    dplyr::pull("grid_cell_size_km")

  selected_grid_size <-
    dplyr::first(vec_eligible_grid_sizes, default = NA_real_)

  selection_status <-
    dplyr::if_else(
      base::is.na(selected_grid_size),
      "no_eligible_grid",
      "selected"
    )

  res <-
    data_candidate_diagnostics |>
    dplyr::mutate(
      selected =
        .data[["eligible"]] &
        .data[["grid_cell_size_km"]] == selected_grid_size,
      selection_status = selection_status
    )

  return(res)
}
