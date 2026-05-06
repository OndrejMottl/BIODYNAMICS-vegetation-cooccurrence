#' @title Build VegVault Query Plan
#' @description
#' Opens the VegVault SQLite database and constructs a lazy
#' vaultkeepr query plan filtered to the specified dataset types,
#' geographic bounds, and age range. The returned plan object is
#' built up to `vaultkeepr::select_samples_by_age()` and can be
#' passed directly to `extract_data_from_vegvault()` or
#' `extract_age_uncertainty_from_vegvault()`.
#' @param path_to_vegvault
#' A character string specifying the path to the VegVault SQLite
#' database
#' (default: `here::here("Data/Input/VegVault.sqlite")`).
#' @param x_lim
#' A numeric vector of length 2 specifying the longitude range
#' `c(min, max)`.
#' @param y_lim
#' A numeric vector of length 2 specifying the latitude range
#' `c(min, max)`.
#' @param age_lim
#' A numeric vector of length 2 specifying the age range in cal yr
#' BP `c(min, max)`.
#' @param sel_dataset_type
#' A non-empty character vector of dataset types to include
#' (e.g. `"fossil_pollen_archive"`,
#' `c("vegetation_plot", "gridpoints")`).
#' @return
#' A vaultkeepr plan object (lazy SQL query) after applying dataset
#' type, geographic, and age-range filters, ready for use with
#' `extract_data_from_vegvault()` or
#' `extract_age_uncertainty_from_vegvault()`.
#' @details
#' The plan is assembled via the following vaultkeepr chain:
#'   `open_vault()` -> `get_datasets()` ->
#'   `select_dataset_by_type()` -> `select_dataset_by_geo()` ->
#'   `get_samples()` -> `select_samples_by_age()`
#'
#' If vaultkeepr raises an error during plan assembly (e.g. no data
#' available for the specified constraints), the error is caught and
#' re-thrown via `cli::cli_abort()` with the original message
#' preserved.
#' @seealso
#'   [extract_data_from_vegvault()],
#'   [extract_age_uncertainty_from_vegvault()]
#' @export
build_vegvault_plan <- function(
    path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
    x_lim = NULL,
    y_lim = NULL,
    age_lim = NULL,
    sel_dataset_type = NULL) {
  #-- Validate inputs ----------------------------------------------------------

  assertthat::assert_that(
    base::is.character(path_to_vegvault) &&
      base::length(path_to_vegvault) == 1L,
    msg = "'path_to_vegvault' must be a single character string"
  )

  check_presence_of_vegvault(path_to_vegvault)

  assertthat::assert_that(
    base::is.numeric(x_lim) && base::length(x_lim) == 2L,
    msg = "'x_lim' must be a numeric vector of length 2"
  )

  assertthat::assert_that(
    base::is.numeric(y_lim) && base::length(y_lim) == 2L,
    msg = "'y_lim' must be a numeric vector of length 2"
  )

  assertthat::assert_that(
    base::is.numeric(age_lim) && base::length(age_lim) == 2L,
    msg = "'age_lim' must be a numeric vector of length 2"
  )

  assertthat::assert_that(
    base::is.character(sel_dataset_type) &&
      base::length(sel_dataset_type) >= 1L,
    msg = paste0(
      "'sel_dataset_type' must be a non-empty character vector"
    )
  )

  #-- Build plan ---------------------------------------------------------------

  plan_error <- NULL

  res_plan <-
    tryCatch(
      expr = {
        suppressMessages(
          vaultkeepr::open_vault(path = path_to_vegvault) |>
            vaultkeepr::get_datasets() |>
            vaultkeepr::select_dataset_by_type(
              sel_dataset_type = sel_dataset_type
            ) |>
            vaultkeepr::select_dataset_by_geo(
              long_lim = x_lim,
              lat_lim = y_lim,
              verbose = FALSE
            ) |>
            vaultkeepr::get_samples() |>
            vaultkeepr::select_samples_by_age(
              age_lim = age_lim,
              verbose = FALSE
            )
        )
      },
      error = function(e) {
        plan_error <<- base::conditionMessage(e)
        NULL
      }
    )

  if (
    base::is.null(res_plan)
  ) {
    cli::cli_abort(
      c(
        "Failed to build the vaultkeepr query plan.",
        "i" = "No data available for the specified constraints.",
        "x" = plan_error
      )
    )
  }

  return(res_plan)
}
