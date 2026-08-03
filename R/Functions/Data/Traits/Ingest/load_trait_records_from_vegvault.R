#' @title Load Trait Records from VegVault
#' @description
#' Loads functional trait records from the VegVault SQLite database for
#' specified trait domains. Optional geographic filtering limits records
#' to datasets within the specified longitude/latitude bounding box.
#' Taxon names are returned as-is (`classify_to = NULL`) for downstream
#' manual classification.
#' @param path_vegvault
#' A character string specifying the path to the VegVault SQLite database
#' (default: `here::here("Data/Input/VegVault.sqlite")`).
#' @param vec_trait_domain_names
#' A character vector specifying the trait domain names to load
#' (e.g. `c("Specific leaf area (SLA)", "Plant height vegetative")`).
#' @param vec_longitude_limits
#' A numeric vector of length 2 giving the longitude limits
#' `c(min, max)` for geographic filtering. Must be supplied together
#' with `vec_latitude_limits`. If `NULL` (default) no geographic filter is
#' applied.
#' @param vec_latitude_limits
#' A numeric vector of length 2 giving the latitude limits
#' `c(min, max)` for geographic filtering. Must be supplied together
#' with `vec_longitude_limits`. If `NULL` (default) no geographic filter is
#' applied.
#' @return
#' A flat data frame containing loaded trait records with columns
#' including `taxon_name` (original, unclassified), `trait_domain_name`,
#' `trait_name`, and `trait_value`.
#' @details
#' The function performs the following steps:
#'
#'   1. Validates input parameters.
#'   2. Checks the presence of the VegVault SQLite database.
#'   3. Builds the vaultkeepr query plan (lazy SQL). If geographic limits
#'      are supplied, datasets are filtered to the bounding box using
#'      `vaultkeepr::select_dataset_by_geo()` before sample retrieval.
#'      If vaultkeepr raises an error during plan assembly (e.g. no data
#'      for the given domain names), the error is caught and re-thrown
#'      via `cli::cli_abort()` with the original message preserved.
#'   4. Retrieves trait values using `classify_to = NULL` to preserve raw
#'      taxon names for downstream manual classification via the same
#'      taxospace + auxiliary-table pipeline used for community data.
#'   5. Returns the loaded data as a flat data frame.
#' @seealso [extract_data_from_vegvault()]
#' @export
load_trait_records_from_vegvault <- function(
    path_vegvault = here::here(
      "Data/Input/VegVault.sqlite"
    ),
    vec_trait_domain_names = NULL,
    vec_longitude_limits = NULL,
    vec_latitude_limits = NULL) {
  assertthat::assert_that(
    base::is.character(path_vegvault) &&
      base::length(path_vegvault) == 1L,
    msg = "'path_vegvault' must be a single character string."
  )

  # Check if the VegVault file exists
  check_presence_of_vegvault(path_vegvault)

  assertthat::assert_that(
    base::is.character(vec_trait_domain_names) &&
      base::length(vec_trait_domain_names) > 0L,
    msg = stringr::str_c(
      "'vec_trait_domain_names' must be a non-empty ",
      "character vector."
    )
  )

  # Both or neither geo-limits must be supplied
  flag_use_geo_filter <-
    !base::is.null(vec_longitude_limits) &&
    !base::is.null(vec_latitude_limits)

  if (
    flag_use_geo_filter
  ) {
    assertthat::assert_that(
      base::is.numeric(vec_longitude_limits) &&
        base::length(vec_longitude_limits) == 2L,
      msg = "'vec_longitude_limits' must be a numeric vector of length 2."
    )
    assertthat::assert_that(
      base::is.numeric(vec_latitude_limits) &&
        base::length(vec_latitude_limits) == 2L,
      msg = "'vec_latitude_limits' must be a numeric vector of length 2."
    )
  } else {
    assertthat::assert_that(
      base::is.null(vec_longitude_limits) &&
        base::is.null(vec_latitude_limits),
      msg = stringr::str_c(
        "'vec_longitude_limits' and 'vec_latitude_limits' ",
        "must both be supplied or both be NULL."
      )
    )
  }

  result_trait_query <-
    tryCatch(
      expr = {
        # Build trait query — traits are species-level properties.
        # classify_to = NULL preserves raw taxon names for downstream
        # manual classification via the same taxospace pipeline used
        # for community data. An optional geo-filter restricts datasets
        # to the continental bounding box containing the project area.
        query_trait_data <-
          vaultkeepr::open_vault(
            path = path_vegvault
          ) |>
          vaultkeepr::get_datasets() |>
          vaultkeepr::select_dataset_by_type(
            sel_dataset_type = "traits"
          )

        # Apply geo-filter only when continental bounds are supplied.
        # Vaultkeepr expects latitude limits before longitude limits.
        if (
          flag_use_geo_filter
        ) {
          query_trait_data <-
            query_trait_data |>
            vaultkeepr::select_dataset_by_geo(
              lat_lim = vec_latitude_limits,
              long_lim = vec_longitude_limits,
              verbose = FALSE,
              sel_dataset_type = "traits"
            )
        }

        query_trait_data |>
          vaultkeepr::get_samples() |>
          vaultkeepr::get_traits(
            classify_to = NULL,
            verbose = FALSE
          ) |>
          vaultkeepr::select_traits_by_domain_name(
            sel_domain = vec_trait_domain_names
          )
      },
      error = base::identity
    )

  if (
    base::inherits(result_trait_query, "error")
  ) {
    cli::cli_abort(
      c(
        "Failed to build the vaultkeepr trait query plan.",
        "i" = stringr::str_c(
          "No trait data available for the specified ",
          "domain names."
        ),
        "x" = base::conditionMessage(result_trait_query)
      )
    )
  }

  data_trait_records <-
    result_trait_query |>
    vaultkeepr::extract_data(
      return_raw_data = TRUE,
      verbose = FALSE
    )

  return(data_trait_records)
}
