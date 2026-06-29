#' @title Make Spatial Cross-Validation Assignments
#' @description
#' Assigns complete sampling locations to deterministic spatially stratified
#' folds while balancing grid-cell coverage, location counts, and sample counts.
#' @param data_locations
#' Location table returned by [make_cross_validation_location_table()] with
#' projected coordinates, sample counts, and sample-row indices.
#' @param n_folds
#' Single integer greater than one and no greater than the location count.
#' @param n_repeats
#' Single positive integer. Grid origins and within-cell ordering change
#' deterministically between repeats. Defaults to `1L`.
#' @param grid_cell_size_km
#' Single positive numeric grid-cell width in projected kilometres.
#' @param seed
#' Single finite integer used for reproducible within-cell ordering. Defaults
#' to `900723L`.
#' @return
#' Tibble with `repeat_id`, `fold_id`, `location_id`, `grid_cell_id`,
#' `n_samples`, and `row_indices`. Every location occurs exactly once per
#' repeat and every sample row remains attached to its complete location.
#' @details
#' Locations in the most populated cells are assigned first. For each
#' location, folds are ranked lexicographically by existing locations from the
#' same grid cell, total locations, total represented samples, and fold ID.
#' Grid origins shift deterministically between repeats to expose sensitivity
#' to arbitrary grid boundaries. The caller's random-number state is restored.
#' @examples
#' data_locations <-
#'   tibble::tibble(
#'     location_id = c("a", "b", "c", "d"),
#'     coord_x_km = c(0, 1, 10, 11),
#'     coord_y_km = c(0, 1, 10, 11),
#'     n_samples = rep(1L, 4L),
#'     row_indices = list(1L, 2L, 3L, 4L)
#'   )
#' make_spatial_cross_validation_assignments(
#'   data_locations = data_locations,
#'   n_folds = 2L,
#'   grid_cell_size_km = 5
#' )
#' @export
make_spatial_cross_validation_assignments <- function(
    data_locations = NULL,
    n_folds = 5L,
    n_repeats = 1L,
    grid_cell_size_km = NULL,
    seed = 900723L) {
  assertthat::assert_that(
    base::is.data.frame(data_locations),
    base::nrow(data_locations) > 0L,
    msg = "`data_locations` must be a non-empty data frame."
  )

  vec_required_columns <-
    base::c(
      "location_id",
      "coord_x_km",
      "coord_y_km",
      "n_samples",
      "row_indices"
    )

  assertthat::assert_that(
    base::all(
      vec_required_columns %in% base::colnames(data_locations)
    ),
    msg = "`data_locations` is missing required columns."
  )

  flag_valid_n_folds <-
    base::is.numeric(n_folds) &&
    base::length(n_folds) == 1L &&
    base::is.finite(n_folds) &&
    n_folds >= 2L &&
    n_folds == base::as.integer(n_folds)

  assertthat::assert_that(
    flag_valid_n_folds,
    msg = "`n_folds` must be a single integer greater than one."
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

  flag_valid_grid_size <-
    base::is.numeric(grid_cell_size_km) &&
    base::length(grid_cell_size_km) == 1L &&
    base::is.finite(grid_cell_size_km) &&
    grid_cell_size_km > 0

  assertthat::assert_that(
    flag_valid_grid_size,
    msg = "`grid_cell_size_km` must be a single positive number."
  )

  flag_valid_seed <-
    base::is.numeric(seed) &&
    base::length(seed) == 1L &&
    base::is.finite(seed) &&
    seed >= 0L &&
    seed == base::as.integer(seed)

  assertthat::assert_that(
    flag_valid_seed,
    msg = "`seed` must be a single non-negative integer."
  )

  n_folds <-
    base::as.integer(n_folds)

  n_repeats <-
    base::as.integer(n_repeats)

  seed <-
    base::as.integer(seed)

  n_locations <-
    base::nrow(data_locations)

  assertthat::assert_that(
    n_folds <= n_locations,
    msg = "`n_folds` must not exceed the number of locations."
  )

  vec_location_ids <-
    data_locations |>
    dplyr::pull("location_id") |>
    base::as.character()

  assertthat::assert_that(
    !base::any(base::is.na(vec_location_ids)),
    base::all(base::nzchar(vec_location_ids)),
    !base::any(base::duplicated(vec_location_ids)),
    msg = "`location_id` values must be unique non-missing strings."
  )

  vec_coord_x <-
    data_locations |>
    dplyr::pull("coord_x_km")

  vec_coord_y <-
    data_locations |>
    dplyr::pull("coord_y_km")

  assertthat::assert_that(
    base::is.numeric(vec_coord_x),
    base::is.numeric(vec_coord_y),
    base::all(base::is.finite(vec_coord_x)),
    base::all(base::is.finite(vec_coord_y)),
    msg = "Projected coordinates must contain finite numeric values."
  )

  vec_n_samples <-
    data_locations |>
    dplyr::pull("n_samples")

  assertthat::assert_that(
    base::is.numeric(vec_n_samples),
    base::all(base::is.finite(vec_n_samples)),
    base::all(vec_n_samples >= 1L),
    base::all(vec_n_samples == base::as.integer(vec_n_samples)),
    msg = "`n_samples` must contain positive integers."
  )

  list_row_indices <-
    data_locations |>
    dplyr::pull("row_indices")

  assertthat::assert_that(
    base::is.list(list_row_indices),
    base::length(list_row_indices) == n_locations,
    msg = "`row_indices` must contain one list element per location."
  )

  flag_had_seed <-
    base::exists(
      x = ".Random.seed",
      envir = .GlobalEnv,
      inherits = FALSE
    )

  if (
    flag_had_seed
  ) {
    old_seed <-
      base::get(
        x = ".Random.seed",
        envir = .GlobalEnv,
        inherits = FALSE
      )
  } else {
    old_seed <- NULL
  }

  on.exit(
    expr = {
      if (
        flag_had_seed
      ) {
        base::assign(
          x = ".Random.seed",
          value = old_seed,
          envir = .GlobalEnv
        )
      } else if (
        base::exists(
          x = ".Random.seed",
          envir = .GlobalEnv,
          inherits = FALSE
        )
      ) {
        base::rm(
          list = ".Random.seed",
          envir = .GlobalEnv
        )
      }
    },
    add = TRUE
  )

  base::set.seed(seed)

  res <-
    base::seq_len(n_repeats) |>
    purrr::map(
      .f = ~ {
        repeat_id <- .x

        shift_x_fraction <-
          (repeat_id - 1L) / n_repeats

        shift_y_fraction <-
          (((repeat_id - 1L) * 2L) %% n_repeats) / n_repeats

        grid_origin_x <-
          base::min(vec_coord_x) -
          shift_x_fraction * grid_cell_size_km

        grid_origin_y <-
          base::min(vec_coord_y) -
          shift_y_fraction * grid_cell_size_km

        vec_cell_x <-
          base::floor(
            (vec_coord_x - grid_origin_x) / grid_cell_size_km
          )

        vec_cell_y <-
          base::floor(
            (vec_coord_y - grid_origin_y) / grid_cell_size_km
          )

        vec_grid_cell_ids <-
          stringr::str_glue("x{vec_cell_x}_y{vec_cell_y}") |>
          base::as.character()

        data_assignment_order <-
          tibble::tibble(
            location_index = base::seq_len(n_locations),
            grid_cell_id = vec_grid_cell_ids,
            random_order = stats::runif(n_locations)
          ) |>
          dplyr::group_by(.data[["grid_cell_id"]]) |>
          dplyr::mutate(
            cell_location_count = dplyr::n()
          ) |>
          dplyr::ungroup() |>
          dplyr::arrange(
            dplyr::desc(.data[["cell_location_count"]]),
            .data[["grid_cell_id"]],
            .data[["random_order"]]
          )

        vec_unique_cell_ids <-
          base::unique(vec_grid_cell_ids)

        mat_cell_location_counts <-
          base::matrix(
            data = 0L,
            nrow = n_folds,
            ncol = base::length(vec_unique_cell_ids)
          )

        vec_fold_location_counts <-
          base::integer(n_folds)

        vec_fold_sample_counts <-
          base::integer(n_folds)

        vec_fold_assignments <-
          base::integer(n_locations)

        for (
          order_index in base::seq_len(n_locations)
        ) {
          location_index <-
            data_assignment_order[["location_index"]][[order_index]]

          grid_cell_id <-
            vec_grid_cell_ids[[location_index]]

          cell_index <-
            base::match(grid_cell_id, vec_unique_cell_ids)

          selected_fold <-
            tibble::tibble(
              fold_id = base::seq_len(n_folds),
              cell_locations = mat_cell_location_counts[, cell_index],
              total_locations = vec_fold_location_counts,
              total_samples = vec_fold_sample_counts
            ) |>
            dplyr::arrange(
              .data[["cell_locations"]],
              .data[["total_locations"]],
              .data[["total_samples"]],
              .data[["fold_id"]]
            ) |>
            dplyr::pull("fold_id") |>
            dplyr::first()

          vec_fold_assignments[[location_index]] <-
            selected_fold

          mat_cell_location_counts[selected_fold, cell_index] <-
            mat_cell_location_counts[selected_fold, cell_index] + 1L

          vec_fold_location_counts[[selected_fold]] <-
            vec_fold_location_counts[[selected_fold]] + 1L

          vec_fold_sample_counts[[selected_fold]] <-
            vec_fold_sample_counts[[selected_fold]] +
            vec_n_samples[[location_index]]
        }

        tibble::tibble(
          repeat_id = base::rep(repeat_id, n_locations),
          fold_id = vec_fold_assignments,
          location_id = vec_location_ids,
          grid_cell_id = vec_grid_cell_ids,
          n_samples = base::as.integer(vec_n_samples),
          row_indices = list_row_indices
        )
      }
    ) |>
    purrr::list_rbind()

  return(res)
}
