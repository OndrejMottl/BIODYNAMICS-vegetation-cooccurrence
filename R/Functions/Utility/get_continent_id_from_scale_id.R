#' @title Get Continent ID from Scale ID
#' @description
#' Resolves the continental parent identifier for a spatial
#' `scale_id` using the project's spatial grid CSV catalogue.
#' @param scale_id
#' A single non-empty character string identifying the spatial
#' unit whose `continent_id` should be returned.
#' @param file
#' Path to the spatial grid CSV catalogue file.
#' Default: `here::here("Data/Input/spatial_grid.csv")`.
#' @return
#' A single non-empty character string containing the `continent_id`
#' for the supplied `scale_id`.
#' @details
#' The function validates the inputs, reads the spatial grid CSV,
#' finds the row matching `scale_id`, and returns its
#' `continent_id`. The function errors when the file is not a
#' readable CSV, when required columns are absent, when the
#' `scale_id` is absent or duplicated, or when the matched row has
#' a missing `continent_id` value.
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
      base::length(scale_id) == 1L &&
      base::nchar(scale_id) > 0L,
    msg = "`scale_id` must be a single non-empty character string."
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

  data_row <-
    data_grid[
      data_grid[["scale_id"]] == scale_id,
      ,
      drop = FALSE
    ]

  if (
    base::nrow(data_row) != 1L
  ) {
    cli::cli_abort(
      stringr::str_glue(
        "Expected exactly 1 row for scale_id '{scale_id}'. ",
        "Found: {base::nrow(data_row)}."
      )
    )
  }

  res_continent_id <-
    data_row[["continent_id"]]

  if (
    base::is.na(res_continent_id) ||
      base::nchar(res_continent_id) == 0L
  ) {
    cli::cli_abort(
      stringr::str_glue(
        "Missing continent_id for scale_id '{scale_id}'."
      )
    )
  }

  return(res_continent_id)
}