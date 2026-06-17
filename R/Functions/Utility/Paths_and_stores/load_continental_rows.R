#' @title Load Continental Rows from Spatial Grid
#' @description
#' Reads a spatial grid CSV file and filters it to rows where the
#' `scale` column equals `"continental"`. Validates that at least one
#' continental row is present before returning the result.
#' @param path_spatial_grid
#' A character string giving the path to the spatial grid CSV file
#' (e.g. `here::here("Data/Input/spatial_grid.csv")`).
#' @return
#' A data frame containing only the rows of the spatial grid where
#' `scale == "continental"`.
#' @details
#' The function performs the following steps:
#'
#'   1. Validates that `path_spatial_grid` is a single character string
#'      pointing to an existing file.
#'   2. Reads the CSV with `readr::read_csv()`.
#'   3. Filters to rows where `scale == "continental"`.
#'   4. Asserts that at least one row is retained.
#'   5. Returns the filtered data frame.
#' @export
load_continental_rows <- function(path_spatial_grid) {
  assertthat::assert_that(
    base::is.character(path_spatial_grid) &&
      base::length(path_spatial_grid) == 1L,
    msg = base::paste0(
      "'path_spatial_grid' must be a single character string."
    )
  )

  assertthat::assert_that(
    base::file.exists(path_spatial_grid),
    msg = base::paste0(
      "File not found: '", path_spatial_grid, "'."
    )
  )

  data_spatial_grid <-
    readr::read_csv(
      file = path_spatial_grid,
      show_col_types = FALSE
    )

  assertthat::assert_that(
    "scale" %in% base::colnames(data_spatial_grid),
    msg = base::paste0(
      "The CSV at '", path_spatial_grid, "' ",
      "has no 'scale' column."
    )
  )

  data_continental_rows <-
    data_spatial_grid |>
    dplyr::filter(
      .data[["scale"]] == "continental"
    )

  assertthat::assert_that(
    base::nrow(data_continental_rows) >= 1L,
    msg = base::paste0(
      "Expected at least one continental row in ",
      "'", path_spatial_grid, "', but found none. ",
      "Check the 'scale' column."
    )
  )

  return(data_continental_rows)
}
