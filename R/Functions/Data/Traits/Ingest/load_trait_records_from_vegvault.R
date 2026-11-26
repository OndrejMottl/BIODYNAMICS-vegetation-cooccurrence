#' @title Load Trait Records from VegVault
#' @description
#' Loads functional trait records from the VegVault SQLite database for
#' specified trait domains. Optional geographic filtering limits records
#' to datasets within the specified longitude/latitude bounding box.
#' Taxon names are returned as-is (`classify_to = "original"`) for
#' downstream manual classification.
#' @param path_vegvault
#' A character string specifying the path to the VegVault SQLite database
#' (default: `here::here("Data/Input/VegVault.sqlite")`).
#' @param data_vegvault_release
#' A one-row data frame with the VegVault release record the pipeline
#' built from the same file (the `config_vegvault_release` target), as
#' returned by [load_vegvault_database_version()].
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
#' including `dataset_id`, `dataset_name`, `data_source_id`, `sample_id`,
#' `trait_id`, `taxon_id`, `trait_domain_name`, `trait_name`, and
#' `trait_value`.
#' @details
#' The function performs the following steps:
#'
#'   1. Validates input parameters.
#'   2. Checks the presence of the VegVault SQLite database, and with
#'      [validate_vegvault_release()] that it holds the release in
#'      `data_vegvault_release`.
#'   3. Builds the vaultkeepr query plan (lazy SQL). If geographic limits
#'      are supplied, datasets are filtered to the bounding box using
#'      `vaultkeepr::select_dataset_by_geo()` before sample retrieval.
#'      If vaultkeepr raises an error during plan assembly (e.g. no data
#'      for the given domain names), the error is caught and re-thrown
#'      via `cli::cli_abort()` with the original message preserved.
#'   4. Retrieves trait values using `classify_to = "original"` to preserve
#'      raw taxon names for downstream manual classification via the same
#'      taxospace + auxiliary-table pipeline used for community data.
#'   5. Returns the loaded data, including source identifiers, as a flat
#'      data frame.
#'
#' The direct query for dataset sources opens the file read-only.
#' @seealso [extract_data_from_vegvault()], [validate_vegvault_release()]
#' @export
load_trait_records_from_vegvault <- function(
    path_vegvault = here::here(
      "Data/Input/VegVault.sqlite"
    ),
    data_vegvault_release,
    vec_trait_domain_names = NULL,
    vec_longitude_limits = NULL,
    vec_latitude_limits = NULL) {
  assertthat::assert_that(
    base::is.character(path_vegvault) &&
      base::length(path_vegvault) == 1L,
    msg = "'path_vegvault' must be a single character string."
  )

  # Check if the VegVault file exists
  validate_vegvault_presence(path_vegvault)

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

  validate_vegvault_release(
    path_to_vegvault = path_vegvault,
    data_vegvault_release = data_vegvault_release
  )

  result_trait_query <-
    tryCatch(
      expr = {
        # Build trait query - traits are species-level properties.
        # classify_to = "original" keeps the raw taxon names for downstream
        # manual classification via the same taxospace pipeline used for
        # community data. vaultkeepr 0.2.0 reads NULL the same way; naming
        # the value keeps the choice visible. An optional geo-filter
        # restricts datasets to the continental bounding box containing the
        # project area.
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
            classify_to = "original",
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

  connection_vegvault <-
    DBI::dbConnect(
      drv = RSQLite::SQLite(),
      dbname = path_vegvault,
      flags = RSQLite::SQLITE_RO
    )
  base::on.exit(
    DBI::dbDisconnect(connection_vegvault),
    add = TRUE
  )
  data_dataset_sources <-
    DBI::dbGetQuery(
      connection_vegvault,
      "SELECT dataset_id, data_source_id FROM Datasets"
    ) |>
    dplyr::filter(
      .data[["dataset_id"]] %in% data_trait_records[["dataset_id"]]
    )
  assertthat::assert_that(
    !base::anyDuplicated(data_dataset_sources[["dataset_id"]]),
    msg = "Each VegVault dataset must map to exactly one data source."
  )
  n_records_before_join <- base::nrow(data_trait_records)
  data_trait_records <-
    data_trait_records |>
    dplyr::select(-dplyr::any_of("data_source_id")) |>
    dplyr::left_join(
      data_dataset_sources,
      by = dplyr::join_by(dataset_id)
    )
  assertthat::assert_that(
    base::nrow(data_trait_records) == n_records_before_join,
    !base::any(base::is.na(data_trait_records[["data_source_id"]])),
    msg = paste0(
      "Dataset-to-source resolution must not multiply or lose records."
    )
  )

  return(data_trait_records)
}
