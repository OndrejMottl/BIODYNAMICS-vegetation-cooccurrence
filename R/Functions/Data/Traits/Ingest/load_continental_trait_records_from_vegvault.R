#' @title Load Continental Trait Records from VegVault
#' @description
#' Loads raw trait data from VegVault for a single continental
#' bounding box, removes incomplete records, and translates numeric
#' taxon IDs to taxon names. Optionally prints progress messages.
#' @param data_continental_unit
#' A single-row data frame (one continental unit from the spatial
#' grid) with columns `scale_id`, `x_min`, `x_max`, `y_min`,
#' and `y_max`.
#' @param vec_trait_domain_names
#' A non-empty character vector of trait domain names to extract
#' (e.g. `c("Specific leaf area (SLA)", "Plant height vegetative")`).
#' @param path_vegvault
#' A single character string giving the path to the VegVault
#' SQLite database
#' (default: `here::here("Data/Input/VegVault.sqlite")`).
#' @param verbose
#' A single logical value. If `TRUE` (default), progress messages
#' are printed via `cli::cli_inform()`. Set to `FALSE` to suppress
#' all console output.
#' @return
#' A tibble with columns `taxon_name`, `trait_domain_name`,
#' `trait_name`, and `trait_value`, containing the cleaned and
#' ID-resolved trait records for the supplied continental unit.
#' @details
#' The function performs the following steps:
#'
#'   1. Validates all input arguments.
#'   2. Derives the bounding-box limits and scale identifier from
#'      `data_continental_unit`.
#'   3. Calls [load_trait_records_from_vegvault()] to retrieve raw records.
#'   4. Calls [filter_complete_trait_records()] to drop incomplete rows.
#'   5. Calls [resolve_trait_taxon_ids()] to replace numeric IDs with
#'      taxon names.
#'   6. Returns the final tibble with taxon-name columns only.
#' @seealso [load_trait_records_from_vegvault()],
#'   [filter_complete_trait_records()], [resolve_trait_taxon_ids()]
#' @export
load_continental_trait_records_from_vegvault <- function(
    data_continental_unit,
    vec_trait_domain_names,
    path_vegvault = here::here(
      "Data/Input/VegVault.sqlite"
    ),
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data_continental_unit),
    msg = "'data_continental_unit' must be a data frame."
  )

  assertthat::assert_that(
    base::nrow(data_continental_unit) >= 1L,
    msg = "'data_continental_unit' must have at least one row."
  )

  assertthat::assert_that(
    base::all(
      base::c(
        "scale_id", "x_min", "x_max", "y_min", "y_max"
      ) %in% base::names(data_continental_unit)
    ),
    msg = stringr::str_c(
      "'data_continental_unit' must contain columns: ",
      "'scale_id', 'x_min', 'x_max', 'y_min', 'y_max'."
    )
  )

  assertthat::assert_that(
    base::is.character(vec_trait_domain_names) &&
      base::length(vec_trait_domain_names) > 0L,
    msg = stringr::str_c(
      "'vec_trait_domain_names' must be a non-empty ",
      "character vector."
    )
  )

  assertthat::assert_that(
    base::is.character(path_vegvault) &&
      base::length(path_vegvault) == 1L,
    msg = "'path_vegvault' must be a single character string."
  )

  assertthat::assert_that(
    base::file.exists(path_vegvault),
    msg = stringr::str_c(
      "VegVault database not found at: '",
      path_vegvault,
      "'."
    )
  )

  assertthat::assert_that(
    base::is.logical(verbose) &&
      base::length(verbose) == 1L,
    msg = "'verbose' must be a single logical value."
  )

  scale_id <-
    data_continental_unit |>
    dplyr::pull("scale_id")

  vec_longitude_limits <-
    base::c(
      data_continental_unit |> dplyr::pull("x_min"),
      data_continental_unit |> dplyr::pull("x_max")
    )

  vec_latitude_limits <-
    base::c(
      data_continental_unit |> dplyr::pull("y_min"),
      data_continental_unit |> dplyr::pull("y_max")
    )

  if (
    base::isTRUE(verbose)
  ) {
    cli::cli_inform(
      base::c(
        "i" = stringr::str_c(
          "Loading traits for '",
          scale_id,
          "'."
        ),
        " " = stringr::str_c(
          "Bounds: lon [",
          vec_longitude_limits[1L],
          ", ",
          vec_longitude_limits[2L],
          "], lat [",
          vec_latitude_limits[1L],
          ", ",
          vec_latitude_limits[2L],
          "]."
        ),
        " " = stringr::str_c(
          "Domains (",
          base::length(vec_trait_domain_names),
          "): ",
          stringr::str_c(
            vec_trait_domain_names,
            collapse = " | "
          )
        ),
        " " = "This may take 15-60 min per continent."
      )
    )
  }

  data_trait_records_raw <-
    load_trait_records_from_vegvault(
      path_vegvault = path_vegvault,
      vec_trait_domain_names = vec_trait_domain_names,
      vec_longitude_limits = vec_longitude_limits,
      vec_latitude_limits = vec_latitude_limits
    )

  data_trait_records_complete <-
    filter_complete_trait_records(
      data_trait_records_raw = data_trait_records_raw
    )

  data_trait_records_resolved <-
    resolve_trait_taxon_ids(
      data_trait_records = data_trait_records_complete,
      path_vegvault = path_vegvault
    )

  if (
    base::isTRUE(verbose)
  ) {
    cli::cli_inform(
      base::c(
        "v" = stringr::str_c(
          "'",
          scale_id,
          "': loaded ",
          base::nrow(data_trait_records_resolved),
          " records."
        )
      )
    )
  }

  return(data_trait_records_resolved)
}
