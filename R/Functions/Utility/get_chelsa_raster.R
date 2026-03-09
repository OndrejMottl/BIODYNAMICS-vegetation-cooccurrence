#' @title Get and Cache a CHELSA-TraCE21k Raster
#' @description
#' Downloads a cropped CHELSA-TraCE21k raster for a given
#' bioclim variable and age slice. If a cached `.tif` already
#' exists in `cache_dir` it is returned immediately without
#' re-downloading. Absolute-temperature variables (`bio1`,
#' `bio6`) are corrected from Kelvin to degrees Celsius
#' (subtract 273.15) before the raster is written to cache.
#' @param chelsa_var
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
#' @param cache_dir
#' Character scalar. Path to the directory where the cropped
#' raster is cached as `{chelsa_var}_{age}.tif`. The
#' directory must already exist before calling this function.
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
#' `(chelsa_var, age)` combination is requested. Subsequent
#' calls load from the cached `.tif` and need no connection.
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
get_chelsa_raster <- function(
    chelsa_var = NULL,
    age = NULL,
    x_lim = NULL,
    y_lim = NULL,
    cache_dir = NULL) {
  assertthat::assert_that(
    assertthat::is.string(chelsa_var),
    msg = "chelsa_var must be a single character string"
  )

  assertthat::assert_that(
    (is.numeric(age) || is.integer(age)) && length(age) == 1L,
    msg = "age must be a single numeric or integer value"
  )

  assertthat::assert_that(
    is.numeric(x_lim) && length(x_lim) == 2L,
    msg = "x_lim must be a numeric vector of length 2"
  )

  assertthat::assert_that(
    is.numeric(y_lim) && length(y_lim) == 2L,
    msg = "y_lim must be a numeric vector of length 2"
  )

  assertthat::assert_that(
    assertthat::is.string(cache_dir),
    base::dir.exists(cache_dir),
    msg = "cache_dir must be a string path to an existing directory"
  )

  # 1. Map project variable name to CHELSA file name -----
  # Pad single-digit bio numbers: "bio1" -> "bio01"
  chelsa_var_name <-
    stringr::str_replace(chelsa_var, "^bio(\\d)$", "bio0\\1")

  # 2. Build cache file path -----
  cache_file <-
    base::file.path(
      cache_dir,
      base::paste0(chelsa_var, "_", age, ".tif")
    )

  # 3. Return from cache if available -----
  if (base::file.exists(cache_file)) {
    return(terra::rast(cache_file))
  }

  # 4. Download and crop from CHELSA-TraCE21k -----
  chelsa_base_url <-
    base::paste0(
      "/vsicurl/https://os.zhdk.cloud.switch.ch/",
      "chelsa01/chelsa_trace21k/global/bioclim/"
    )

  # The present slice uses the special step "0000";
  # all other ages use sprintf("-%03d", age %/% 100).
  chelsa_time_step <-
    if (base::as.integer(age) == 0L) {
      "0000"
    } else {
      base::sprintf(
        "-%03d",
        base::as.integer(age) %/% 100L
      )
    }

  url_rast <-
    base::paste0(
      chelsa_base_url,
      chelsa_var_name, "/",
      "CHELSA_TraCE21k_",
      chelsa_var_name, "_",
      chelsa_time_step,
      "_V.1.0.tif"
    )

  ext_rast <-
    terra::ext(
      base::min(x_lim), base::max(x_lim),
      base::min(y_lim), base::max(y_lim)
    )

  rast_raw <-
    terra::rast(url_rast) |>
    terra::crop(y = ext_rast)

  # 5. Apply Kelvin -> Celsius correction where needed -----
  # bio1 (mean annual temp) and bio6 (min temp coldest month)
  #   are absolute temperatures stored in Kelvin.
  # bio4 (temp seasonality) is a std dev — no offset needed.
  vec_kelvin_vars <- c("bio1", "bio6")

  rast_out <-
    if (chelsa_var %in% vec_kelvin_vars) {
      rast_raw - 273.15
    } else {
      rast_raw
    }

  # 6. Write to cache and return -----
  terra::writeRaster(rast_out, cache_file, overwrite = TRUE)

  return(rast_out)
}
