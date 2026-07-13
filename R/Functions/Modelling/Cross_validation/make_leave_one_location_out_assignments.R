#' @title Make Leave-One-Location-Out Assignments
#' @description
#' Assigns each complete sampling location to its own held-out fold using the
#' shared cross-validation assignment schema.
#' @param data_locations
#' Location table returned by [make_cross_validation_location_table()] with
#' `location_id`, `n_samples`, and `row_indices` columns.
#' @param repeat_id
#' Single positive integer identifying the assignment repeat. Defaults to
#' `1L`.
#' @return
#' Tibble with `repeat_id`, `fold_id`, `location_id`, `grid_cell_id`,
#' `n_samples`, and `row_indices`. `grid_cell_id` is `NA` because spatial-grid
#' stratification is not applicable to leave-one-location-out assignment.
#' @examples
#' data_locations <-
#'   tibble::tibble(
#'     location_id = c("core_a", "core_b"),
#'     n_samples = c(2L, 1L),
#'     row_indices = list(c(1L, 2L), 3L)
#'   )
#' make_leave_one_location_out_assignments(data_locations)
#' @export
make_leave_one_location_out_assignments <- function(
    data_locations = NULL,
    repeat_id = 1L) {
  assertthat::assert_that(
    base::is.data.frame(data_locations),
    base::nrow(data_locations) > 0L,
    msg = "`data_locations` must be a non-empty data frame."
  )

  vec_required_columns <-
    base::c("location_id", "n_samples", "row_indices")

  assertthat::assert_that(
    base::all(
      vec_required_columns %in% base::colnames(data_locations)
    ),
    msg = "`data_locations` is missing required columns."
  )

  flag_valid_repeat_id <-
    base::is.numeric(repeat_id) &&
    base::length(repeat_id) == 1L &&
    base::is.finite(repeat_id) &&
    repeat_id >= 1L &&
    repeat_id == base::as.integer(repeat_id)

  assertthat::assert_that(
    flag_valid_repeat_id,
    msg = "`repeat_id` must be a single positive integer."
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
    msg = "`row_indices` must be a list-column."
  )

  vec_valid_row_indices <-
    list_row_indices |>
    purrr::map2_lgl(
      vec_n_samples,
      .f = ~ {
        base::is.numeric(.x) &&
          base::length(.x) == .y &&
          base::all(base::is.finite(.x)) &&
          base::all(.x >= 1L) &&
          base::all(.x == base::as.integer(.x))
      }
    )

  assertthat::assert_that(
    base::all(vec_valid_row_indices),
    msg = "Each `row_indices` element must match its `n_samples` value."
  )

  vec_all_row_indices <-
    list_row_indices |>
    base::unlist(use.names = FALSE) |>
    base::as.integer() |>
    base::sort()

  vec_expected_row_indices <-
    base::seq_len(base::sum(vec_n_samples))

  if (
    !base::identical(vec_all_row_indices, vec_expected_row_indices)
  ) {
    cli::cli_abort(
      "Every sample row must belong to exactly one location."
    )
  }

  res <-
    tibble::tibble(
      repeat_id = base::rep(
        base::as.integer(repeat_id),
        base::nrow(data_locations)
      ),
      fold_id = base::seq_len(base::nrow(data_locations)),
      location_id = vec_location_ids,
      grid_cell_id = NA_character_,
      n_samples = base::as.integer(vec_n_samples),
      row_indices = list_row_indices
    )

  return(res)
}
