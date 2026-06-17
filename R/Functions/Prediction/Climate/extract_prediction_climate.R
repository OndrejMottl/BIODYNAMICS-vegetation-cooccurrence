#' @title Extract Prediction Climate Values
#' @description
#' Extracts CHELSA raster values for one age slice at prediction grid
#' cell coordinates.
#' @param data_grid
#' Data frame with `grid_id`, `coord_long`, and `coord_lat` columns.
#' @param age
#' Numeric scalar age in years before present.
#' @param abiotic_variables
#' Character vector of CHELSA variable names.
#' @param x_lim
#' Numeric longitude range used for raster cropping.
#' @param y_lim
#' Numeric latitude range used for raster cropping.
#' @param cache_dir
#' Character scalar cache directory passed to [get_chelsa_raster()].
#' @param raster_fn
#' Raster-loading function. Defaults to [get_chelsa_raster()].
#' @return
#' Tibble with grid coordinates, age, and extracted abiotic columns.
#' @examples
#' \dontrun{
#' extract_prediction_climate(
#'   data_grid = data_grid,
#'   age = 0,
#'   abiotic_variables = c("bio1", "bio12"),
#'   x_lim = c(-10, 40),
#'   y_lim = c(35, 70),
#'   cache_dir = "Data/Temp/chelsa/prediction"
#' )
#' }
#' @export
extract_prediction_climate <- function(
    data_grid,
    age,
    abiotic_variables,
    x_lim,
    y_lim,
    cache_dir,
    raster_fn = get_chelsa_raster) {
  assertthat::assert_that(
    base::is.data.frame(data_grid) &&
      base::all(
        c("grid_id", "coord_long", "coord_lat") %in%
          base::colnames(data_grid)
      ),
    msg = paste(
      "`data_grid` must contain grid_id, coord_long,",
      "and coord_lat columns."
    )
  )

  assertthat::assert_that(
    (base::is.numeric(age) || base::is.integer(age)) &&
      base::length(age) == 1L,
    msg = "`age` must be a single numeric value."
  )

  assertthat::assert_that(
    base::is.character(abiotic_variables) &&
      base::length(abiotic_variables) > 0L,
    msg = "`abiotic_variables` must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.character(cache_dir) &&
      base::length(cache_dir) == 1L &&
      base::dir.exists(cache_dir),
    msg = "`cache_dir` must be an existing directory."
  )

  assertthat::assert_that(
    base::is.function(raster_fn),
    msg = "`raster_fn` must be a function."
  )

  mat_coordinates <-
    base::cbind(
      data_grid[["coord_long"]],
      data_grid[["coord_lat"]]
    )

  data_climate_values <-
    abiotic_variables |>
    rlang::set_names() |>
    purrr::map(
      .f = ~ {
        rast_bio <-
          raster_fn(
            chelsa_var = .x,
            age = age,
            x_lim = x_lim,
            y_lim = y_lim,
            cache_dir = cache_dir
          )

        data_extract <-
          terra::extract(
            x = rast_bio,
            y = mat_coordinates
          )

        value_column_index <-
          if (
            base::ncol(data_extract) > 1L &&
              base::identical(base::colnames(data_extract)[[1L]], "ID")
          ) {
            2L
          } else {
            1L
          }

        data_extract[[value_column_index]]
      }
    ) |>
    tibble::as_tibble()

  res_climate <-
    dplyr::bind_cols(
      data_grid |>
        dplyr::select(
          "grid_id",
          "coord_long",
          "coord_lat"
        ),
      data_climate_values
    ) |>
    dplyr::mutate(age = age) |>
    tidyr::drop_na()

  return(res_climate)
}
