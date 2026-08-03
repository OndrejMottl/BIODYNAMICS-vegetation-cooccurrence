#' @title Load and Cache a CHELSA-TraCE21k Raster
#' @description
#' Loads a cropped CHELSA-TraCE21k raster for a given
#' bioclim variable and age slice. If a cached `.tif` already
#' exists in `dir_cache` it is returned immediately without
#' re-downloading. Absolute-temperature variables (`bio1`,
#' `bio6`) are corrected from Kelvin to degrees Celsius
#' (subtract 273.15) before the raster is written to cache.
#' @param abiotic_variable_name
#' Character scalar. Project-level bioclim variable name,
#' e.g. `"bio1"`, `"bio4"`, `"bio12"`. Single-digit numbers
#' are zero-padded internally to match CHELSA file names
#' (`"bio1"` becomes `"bio01"` in the URL).
#' @param age
#' Numeric or integer scalar. Age in years BP used to encode
#' the CHELSA-TraCE21k time step (e.g. `1000` encodes as
#' time step `"-010"`).
#' @param x_lim
#' Numeric vector of length 2. Longitude extent
#' `c(min, max)` for cropping the downloaded raster.
#' @param y_lim
#' Numeric vector of length 2. Latitude extent
#' `c(min, max)` for cropping the downloaded raster.
#' @param dir_cache
#' Character scalar. Path to the directory where the cropped
#' raster is cached as
#' `{abiotic_variable_name}_{age}_{xmin}_{xmax}_{ymin}_{ymax}.tif`.
#' The extent values are rounded to 2 decimal places so the cache
#' is shared across calls with identical extents. The directory must
#' already exist before calling this function.
#' @return
#' A `terra::SpatRaster` cropped to `x_lim` / `y_lim`, with
#' corrected units: degrees Celsius for `bio1` and `bio6`;
#' original CHELSA units for all other variables.
#' @details
#' CHELSA-TraCE21k time steps: `age = 0` (present) maps to
#' the special step `"0000"`; all other ages use
#' `sprintf("-%03d", age %/% 100)`, so `age = 100` gives
#' `"-001"` and `age = 1000` gives `"-010"`.
#'
#' The remote raster is accessed via GDAL `/vsicurl/`, so an
#' internet connection is required the first time each
#' `(abiotic_variable_name, age, x_lim, y_lim)` combination is requested.
#' Subsequent calls load from the cached `.tif` and need no
#' connection. The geographic extent (rounded to 2 decimal
#' places) is embedded in the cache filename, so rasters with
#' different extents are always stored separately.
#'
#' Kelvin correction: `bio1` (Mean Annual Temperature) and
#' `bio6` (Min Temperature of Coldest Month) are absolute
#' temperatures stored in Kelvin; 273.15 is subtracted before
#' caching. Range and seasonality variables (`bio4`, `bio7`)
#' are differences or standard deviations — no offset needed.
#' @seealso
#'   [interpolate_mev_to_grid()],
#'   [interpolate_st_mev_to_grid()],
#'   [project_coords_to_metric()]
#' @export
load_chelsa_raster <- function(
    abiotic_variable_name = NULL,
    age = NULL,
    x_lim = NULL,
    y_lim = NULL,
    dir_cache = NULL) {
  assertthat::assert_that(
    assertthat::is.string(abiotic_variable_name),
    msg = "abiotic_variable_name must be a single character string"
  )

  assertthat::assert_that(
    (base::is.numeric(age) || base::is.integer(age)) &&
      base::length(age) == 1L,
    msg = "age must be a single numeric or integer value"
  )

  assertthat::assert_that(
    base::is.numeric(x_lim) && base::length(x_lim) == 2L,
    msg = "x_lim must be a numeric vector of length 2"
  )

  assertthat::assert_that(
    base::is.numeric(y_lim) && base::length(y_lim) == 2L,
    msg = "y_lim must be a numeric vector of length 2"
  )

  assertthat::assert_that(
    assertthat::is.string(dir_cache),
    base::dir.exists(dir_cache),
    msg = "dir_cache must be a string path to an existing directory"
  )

  # 1. Map project variable name to CHELSA file name -----
  # Pad single-digit bio numbers: "bio1" -> "bio01"
  name_chelsa_variable <-
    stringr::str_replace(
      abiotic_variable_name,
      "^bio(\\d)$",
      "bio0\\1"
    )

  # 2. Build cache file path -----
  # Include rounded extent in filename so rasters cropped to different
  # geographic areas never share the same cache entry.
  str_cache_extent <-
    stringr::str_c(
      base::c(
        base::round(base::min(x_lim), 2L),
        base::round(base::max(x_lim), 2L),
        base::round(base::min(y_lim), 2L),
        base::round(base::max(y_lim), 2L)
      ),
      collapse = "_"
    )

  file_chelsa_raster <-
    base::file.path(
      dir_cache,
      stringr::str_c(
        abiotic_variable_name,
        "_",
        age,
        "_",
        str_cache_extent,
        ".tif"
      )
    )

  # 3. Return from cache if available -----
  if (
    base::file.exists(file_chelsa_raster)
  ) {
    base::return(terra::rast(file_chelsa_raster))
  }

  # 4. Download and crop from CHELSA-TraCE21k -----
  url_chelsa_base <-
    stringr::str_c(
      "/vsicurl/https://os.zhdk.cloud.switch.ch/",
      "chelsa01/chelsa_trace21k/global/bioclim/"
    )

  # The present slice uses the special step "0000";
  # all other ages use sprintf("-%03d", age %/% 100).
  id_chelsa_time_step <-
    if (base::as.integer(age) == 0L) {
      "0000"
    } else {
      base::sprintf(
        "-%03d",
        base::as.integer(age) %/% 100L
      )
    }

  url_chelsa_raster <-
    stringr::str_c(
      url_chelsa_base,
      name_chelsa_variable,
      "/",
      "CHELSA_TraCE21k_",
      name_chelsa_variable,
      "_",
      id_chelsa_time_step,
      "_V.1.0.tif"
    )

  extent_crop <-
    terra::ext(
      base::min(x_lim), base::max(x_lim),
      base::min(y_lim), base::max(y_lim)
    )

  raster_chelsa_raw <-
    terra::rast(url_chelsa_raster) |>
    terra::crop(y = extent_crop)

  # 5. Apply Kelvin -> Celsius correction where needed -----
  # bio1 (mean annual temp) and bio6 (min temp coldest month)
  #   are absolute temperatures stored in Kelvin.
  # bio4 (temp seasonality) is a std dev — no offset needed.
  vec_kelvin_variables <- base::c("bio1", "bio6")

  raster_chelsa <-
    if (
      abiotic_variable_name %in% vec_kelvin_variables
    ) {
      raster_chelsa_raw - 273.15
    } else {
      raster_chelsa_raw
    }

  # 6. Write to cache and return -----
  terra::writeRaster(
    raster_chelsa,
    file_chelsa_raster,
    overwrite = TRUE
  )

  base::return(raster_chelsa)
}
