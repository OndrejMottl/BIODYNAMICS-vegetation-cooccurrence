#' @title Get Continent ID from Scale ID
#' @description
#' Resolves the continental parent identifier for a spatial
#' `scale_id` using the project's spatial grid CSV catalogue.
#' @param scale_id
#' A non-empty character vector identifying spatial units whose
#' `continent_id` values should be returned.
#' @param file
#' Path to the spatial grid CSV catalogue file.
#' Default: `here::here("Data/Input/spatial_grid.csv")`.
#' @return
#' A character vector containing one `continent_id` per supplied
#' `scale_id`, in the same order as `scale_id`.
#' @details
#' The function validates the inputs, reads the spatial grid CSV,
#' finds rows matching `scale_id`, and returns `continent_id`
#' values. The function errors when the file is not a readable CSV,
#' when required columns are absent, when any requested `scale_id` is
#' absent or duplicated, or when any matched row has a missing
#' `continent_id` value.
#' @examples
#' get_continent_id_from_scale_id(
#'   scale_id = "eu_r005",
#'   file = here::here("Data/Input/spatial_grid.csv")
#' )
#' @seealso get_scale_id_from_store, get_spatial_window
#' @export
get_continent_id_from_scale_id <- function(
    scale_id,
    file = here::here("Data/Input/spatial_grid.csv")) {
  assertthat::assert_that(
    base::is.character(scale_id) &&
      base::length(scale_id) > 0L &&
      base::all(!base::is.na(scale_id)) &&
      base::all(base::nchar(scale_id) > 0L),
    msg = "`scale_id` must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.character(file) &&
      base::length(file) == 1L &&
      assertthat::is.readable(file) &&
      assertthat::has_extension(file, "csv"),
    msg = "`file` must be a readable CSV file."
  )

  data_grid <-
    readr::read_csv(
      file = file,
      show_col_types = FALSE
    )

  vec_required_columns <-
    base::c("scale_id", "continent_id")

  if (
    !base::all(vec_required_columns %in% base::colnames(data_grid))
  ) {
    cli::cli_abort(
      "Spatial grid CSV must contain columns: scale_id, continent_id."
    )
  }

  data_requested <-
    tibble::tibble(
      scale_id = base::unique(scale_id)
    )

  data_grid_selected <-
    data_grid |>
    dplyr::select(
      scale_id,
      continent_id
    ) |>
    dplyr::filter(
      .data$scale_id %in% data_requested[["scale_id"]]
    )

  data_match_count <-
    data_requested |>
    dplyr::left_join(
      y = data_grid_selected |>
        dplyr::count(
          .data$scale_id,
          name = "n_matches"
        ),
      by = dplyr::join_by(scale_id)
    ) |>
    dplyr::mutate(
      n_matches = tidyr::replace_na(
        data = .data$n_matches,
        replace = 0L
      )
    )

  res_continent_id <-
    data_requested |>
    dplyr::left_join(
      y = data_match_count,
      by = dplyr::join_by(scale_id)
    ) |>
    dplyr::filter(
      .data$n_matches != 1L
    )

  if (
    base::nrow(res_continent_id) > 0L
  ) {
    cli::cli_abort(
      stringr::str_glue(
        "Expected exactly 1 row for each scale_id. Problems: ",
        "{stringr::str_c(res_continent_id[['scale_id']], collapse = ', ')}."
      )
    )
  }

  data_resolved <-
    data_requested |>
    dplyr::left_join(
      y = data_grid_selected,
      by = dplyr::join_by(scale_id),
      multiple = "error",
      unmatched = "error"
    )

  data_missing_continent <-
    data_resolved |>
    dplyr::filter(
      base::is.na(.data$continent_id) |
        .data$continent_id == ""
    )

  if (
    base::nrow(data_missing_continent) > 0L
  ) {
    cli::cli_abort(
      stringr::str_glue(
        "Missing continent_id for scale_id(s): ",
        "{stringr::str_c(data_missing_continent[['scale_id']], ",
        "collapse = ', ')}."
      )
    )
  }

  res_continent_id <-
    data_resolved[["continent_id"]][
      base::match(
        x = scale_id,
        table = data_resolved[["scale_id"]]
      )
    ]

  return(res_continent_id)
}
