#' @title Build Spatial Model Store Index
#' @description
#' Creates a catalogue of spatial targets stores for one data source
#' and one or more spatial scales.
#' @param data_source
#' A single character string. Must be `"paleo"` or `"modern"`.
#' @param scales
#' Character vector of spatial scales to include.
#' @param pipeline_name
#' Optional pipeline name. Defaults to
#' `pipeline_{data_source}_spatial_resolution`.
#' @param path_spatial_grid
#' Path to the spatial grid CSV file.
#' @return
#' A tibble with columns `data_source`, `scale`, `scale_id`,
#' `pipeline_name`, `store_path`, and `store_exists`.
#' @export
build_spatial_model_store_index <- function(
    data_source,
    scales = c("continental", "regional", "local"),
    pipeline_name = NULL,
    path_spatial_grid = here::here("Data/Input/spatial_grid.csv")) {
  assertthat::assert_that(
    base::is.character(data_source) &&
      base::length(data_source) == 1L &&
      data_source %in% c("paleo", "modern"),
    msg = "`data_source` must be either 'paleo' or 'modern'."
  )

  assertthat::assert_that(
    base::is.character(scales) &&
      base::length(scales) > 0L,
    msg = "`scales` must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::all(scales %in% c("continental", "regional", "local")),
    msg = "`scales` must contain only continental, regional, or local."
  )

  if (
    base::is.null(pipeline_name)
  ) {
    pipeline_name <-
      stringr::str_glue("pipeline_{data_source}_spatial_resolution")
  }

  assertthat::assert_that(
    base::is.character(pipeline_name) &&
      base::length(pipeline_name) == 1L &&
      base::nchar(pipeline_name) > 0L,
    msg = "`pipeline_name` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(path_spatial_grid) &&
      base::length(path_spatial_grid) == 1L &&
      assertthat::is.readable(path_spatial_grid) &&
      assertthat::has_extension(path_spatial_grid, "csv"),
    msg = "`path_spatial_grid` must be a readable CSV file."
  )

  data_grid <-
    readr::read_csv(
      file = path_spatial_grid,
      show_col_types = FALSE
    )

  vec_required_cols <-
    c("scale", "scale_id")

  assertthat::assert_that(
    base::all(vec_required_cols %in% base::colnames(data_grid)),
    msg = "`path_spatial_grid` must contain columns: scale, scale_id."
  )

  res <-
    data_grid |>
    dplyr::filter(
      .data$scale %in% .env$scales
    ) |>
    dplyr::mutate(
      data_source = .env$data_source,
      scale = .data$scale,
      scale_id = .data$scale_id,
      pipeline_name = .env$pipeline_name,
      store_path = base::file.path(
        here::here(),
        stringr::str_glue(
          "Data/targets/{.env$data_source}_spatial_{.data$scale}",
          "/{.data$scale_id}/{.env$pipeline_name}"
        )
      ),
      store_exists = fs::dir_exists(.data$store_path),
      .keep = "none"
    )

  return(res)
}
