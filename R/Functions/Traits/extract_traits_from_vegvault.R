#' @title Extract Trait Data from VegVault
#' @description
#' Extracts functional trait data from the VegVault SQLite database for
#' specified trait domains. Optional geographic filtering limits records
#' to datasets within the specified longitude/latitude bounding box.
#' Taxon names are returned as-is (`classify_to = NULL`) for downstream
#' manual classification.
#' @param path_to_vegvault
#' A character string specifying the path to the VegVault SQLite database
#' (default: `here::here("Data/Input/VegVault.sqlite")`).
#' @param sel_trait_domain_names
#' A character vector specifying the trait domain names to extract
#' (e.g. `c("Specific leaf area (SLA)", "Plant height vegetative")`).
#' @param x_lim
#' A numeric vector of length 2 giving the longitude limits
#' `c(min, max)` for geographic filtering. Must be supplied together
#' with `y_lim`. If `NULL` (default) no geographic filter is applied.
#' @param y_lim
#' A numeric vector of length 2 giving the latitude limits
#' `c(min, max)` for geographic filtering. Must be supplied together
#' with `x_lim`. If `NULL` (default) no geographic filter is applied.
#' @return
#' A flat data frame containing extracted trait records with columns
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
#'   5. Returns the extracted data as a flat data frame.
#' @seealso [extract_data_from_vegvault()]
#' @export
extract_traits_from_vegvault <- function(
    path_to_vegvault = here::here(
      "Data/Input/VegVault.sqlite"
    ),
    sel_trait_domain_names = NULL,
    x_lim = NULL,
    y_lim = NULL) {
  assertthat::assert_that(
    base::is.character(path_to_vegvault) &&
      base::length(path_to_vegvault) == 1L,
    msg = "'path_to_vegvault' must be a single character string."
  )

  # Check if the VegVault file exists
  check_presence_of_vegvault(path_to_vegvault)

  assertthat::assert_that(
    base::is.character(sel_trait_domain_names) &&
      base::length(sel_trait_domain_names) > 0L,
    msg = paste0(
      "'sel_trait_domain_names' must be a non-empty ",
      "character vector."
    )
  )

  # Both or neither geo-limits must be supplied
  flag_use_geo_filter <-
    !base::is.null(x_lim) && !base::is.null(y_lim)

  if (
    flag_use_geo_filter
  ) {
    assertthat::assert_that(
      base::is.numeric(x_lim) && base::length(x_lim) == 2L,
      msg = "'x_lim' must be a numeric vector of length 2."
    )
    assertthat::assert_that(
      base::is.numeric(y_lim) && base::length(y_lim) == 2L,
      msg = "'y_lim' must be a numeric vector of length 2."
    )
  } else {
    assertthat::assert_that(
      base::is.null(x_lim) && base::is.null(y_lim),
      msg = paste0(
        "'x_lim' and 'y_lim' must both be supplied or ",
        "both be NULL."
      )
    )
  }

  plan_error <- NULL

  vaultkeepr_plan <-
    tryCatch(
      expr = {
        # Build trait query — traits are species-level properties.
        # classify_to = NULL preserves raw taxon names for downstream
        # manual classification via the same taxospace pipeline used
        # for community data. An optional geo-filter restricts datasets
        # to the continental bounding box containing the project area.
        data_query <-
          vaultkeepr::open_vault(
            path = path_to_vegvault
          ) |>
          vaultkeepr::get_datasets() |>
          vaultkeepr::select_dataset_by_type(
            sel_dataset_type = "traits"
          )

        # Apply geo-filter only when continental bounds are supplied.
        # lat_lim = y_lim, long_lim = x_lim follows vaultkeepr
        # convention.
        if (
          flag_use_geo_filter
        ) {
          data_query <-
            data_query |>
            vaultkeepr::select_dataset_by_geo(
              lat_lim = y_lim,
              long_lim = x_lim,
              verbose = FALSE,
              sel_dataset_type = "traits"
            )
        }

        data_query |>
          vaultkeepr::get_samples() |>
          vaultkeepr::get_traits(
            classify_to = NULL,
            verbose = FALSE
          ) |>
          vaultkeepr::select_traits_by_domain_name(
            sel_domain = sel_trait_domain_names
          )
      },
      error = function(e) {
        plan_error <<- base::conditionMessage(e)
        NULL
      }
    )

  if (
    base::is.null(vaultkeepr_plan)
  ) {
    cli::cli_abort(
      c(
        "Failed to build the vaultkeepr trait query plan.",
        "i" = paste0(
          "No trait data available for the specified ",
          "domain names."
        ),
        "x" = plan_error
      )
    )
  }

  data_extracted <-
    vaultkeepr_plan |>
    vaultkeepr::extract_data(
      return_raw_data = TRUE,
      verbose = FALSE
    )

  return(data_extracted)
}
