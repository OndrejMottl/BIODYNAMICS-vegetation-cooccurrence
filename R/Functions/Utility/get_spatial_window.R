#' @title Get Spatial Window from Grid Catalogue
#' @description
#' Retrieves the spatial bounding box for a given spatial unit ID from the
#' project's spatial grid CSV catalogue.
#' @param scale_id
#' A single character string identifying the spatial unit.
#' Must match exactly one row in the catalogue file.
#' @param file
#' Path to the spatial grid CSV file.
#' Default: `here::here("Data/Input/spatial_grid.csv")`.
#' @return
#' A named list with two elements:
#' \describe{
#'   \item{`x_lim`}{Numeric vector of length 2: `c(x_min, x_max)`.}
#'   \item{`y_lim`}{Numeric vector of length 2: `c(y_min, y_max)`.}
#' }
#' @details
#' Reads the CSV using `readr::read_csv`, filters to the row whose
#' `scale_id` column matches the supplied `scale_id` argument, and
#' constructs the bounding box vectors. Validation ensures the file
#' is readable, has a `.csv` extension, and that exactly one row
#' matches the requested `scale_id`.
#' @seealso get_active_config
#' @export
get_spatial_window <- function(
    scale_id,
    file = here::here("Data/Input/spatial_grid.csv")) {
  assertthat::assert_that(
    is.character(scale_id) && length(scale_id) == 1,
    msg = paste0(
      "`scale_id` must be a single character string.",
      " Got length: ", length(scale_id)
    )
  )

  assertthat::assert_that(
    assertthat::is.readable(file) &&
      assertthat::has_extension(file, "csv"),
    msg = "`file` must be a readable CSV file."
  )

  data_grid <-
    readr::read_csv(
      file = file,
      show_col_types = FALSE
    )

  data_row <-
    data_grid |>
    dplyr::filter(
      .data$scale_id == .env$scale_id
    )

  assertthat::assert_that(
    base::nrow(data_row) == 1,
    msg = paste0(
      "Expected exactly 1 row for scale_id '", scale_id, "'.",
      " Found: ", base::nrow(data_row)
    )
  )

  res <-
    list(
      x_lim = c(
        dplyr::pull(data_row, x_min),
        dplyr::pull(data_row, x_max)
      ),
      y_lim = c(
        dplyr::pull(data_row, y_min),
        dplyr::pull(data_row, y_max)
      )
    )

  return(res)
}
