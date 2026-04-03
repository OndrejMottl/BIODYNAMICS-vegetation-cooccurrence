#' @title Extract and Clean Trait Data for One Continental Unit
#' @description
#' Extracts raw trait data from VegVault for a single continental
#' bounding box, removes incomplete records, and translates numeric
#' taxon IDs to taxon names. Optionally prints progress messages.
#' @param data_continental_rows
#' A single-row data frame (one continental unit from the spatial
#' grid) with columns `scale_id`, `x_min`, `x_max`, `y_min`,
#' and `y_max`.
#' @param vec_trait_domain_names
#' A non-empty character vector of trait domain names to extract
#' (e.g. `c("Specific leaf area (SLA)", "Plant height vegetative")`).
#' @param path_to_vegvault
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
#'      `data_continental_rows`.
#'   3. Calls [extract_traits_from_vegvault()] to retrieve raw records.
#'   4. Calls [clean_raw_trait_data()] to drop incomplete rows.
#'   5. Calls [resolve_trait_taxon_ids()] to replace numeric IDs with
#'      taxon names.
#'   6. Returns the final tibble with taxon-name columns only.
#' @seealso [extract_traits_from_vegvault()], [clean_raw_trait_data()],
#'   [resolve_trait_taxon_ids()]
#' @export
extract_and_clean_continent_traits <- function(
    data_continental_rows,
    vec_trait_domain_names,
    path_to_vegvault = here::here(
      "Data/Input/VegVault.sqlite"
    ),
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data_continental_rows),
    msg = paste0(
      "'data_continental_rows' must be a data frame."
    )
  )

  assertthat::assert_that(
    base::nrow(data_continental_rows) >= 1L,
    msg = paste0(
      "'data_continental_rows' must have at least one row."
    )
  )

  assertthat::assert_that(
    base::all(
      base::c(
        "scale_id", "x_min", "x_max", "y_min", "y_max"
      ) %in% base::names(data_continental_rows)
    ),
    msg = paste0(
      "'data_continental_rows' must contain columns: ",
      "'scale_id', 'x_min', 'x_max', 'y_min', 'y_max'."
    )
  )

  assertthat::assert_that(
    base::is.character(vec_trait_domain_names) &&
      base::length(vec_trait_domain_names) > 0L,
    msg = paste0(
      "'vec_trait_domain_names' must be a non-empty ",
      "character vector."
    )
  )

  assertthat::assert_that(
    base::is.character(path_to_vegvault) &&
      base::length(path_to_vegvault) == 1L,
    msg = paste0(
      "'path_to_vegvault' must be a single character string."
    )
  )

  assertthat::assert_that(
    base::file.exists(path_to_vegvault),
    msg = base::paste0(
      "VegVault database not found at: '",
      path_to_vegvault, "'."
    )
  )

  assertthat::assert_that(
    base::is.logical(verbose) &&
      base::length(verbose) == 1L,
    msg = "'verbose' must be a single logical value."
  )

  vec_scale_id <-
    data_continental_rows |>
    dplyr::pull("scale_id")

  vec_x_lim <-
    base::c(
      data_continental_rows |> dplyr::pull("x_min"),
      data_continental_rows |> dplyr::pull("x_max")
    )

  vec_y_lim <-
    base::c(
      data_continental_rows |> dplyr::pull("y_min"),
      data_continental_rows |> dplyr::pull("y_max")
    )

  if (
    isTRUE(verbose)
  ) {
    cli::cli_inform(
      c(
        "i" = base::paste0(
          "Extracting traits for '", vec_scale_id, "'."
        ),
        " " = base::paste0(
          "Bounds: lon [",
          vec_x_lim[1L], ", ", vec_x_lim[2L],
          "], lat [",
          vec_y_lim[1L], ", ", vec_y_lim[2L], "]."
        ),
        " " = base::paste0(
          "Domains (",
          base::length(vec_trait_domain_names), "): ",
          base::paste(
            vec_trait_domain_names,
            collapse = " | "
          )
        ),
        " " = "This may take 15-60 min per continent."
      )
    )
  }

  data_raw <-
    extract_traits_from_vegvault(
      path_to_vegvault = path_to_vegvault,
      sel_trait_domain_names = vec_trait_domain_names,
      x_lim = vec_x_lim,
      y_lim = vec_y_lim
    )

  data_clean <-
    clean_raw_trait_data(data_raw = data_raw)

  res_result <-
    resolve_trait_taxon_ids(
      data_clean = data_clean,
      path_to_vegvault = path_to_vegvault
    )

  if (
    isTRUE(verbose)
  ) {
    cli::cli_inform(
      c(
        "v" = base::paste0(
          "'", vec_scale_id, "': extracted ",
          base::nrow(res_result), " records."
        )
      )
    )
  }

  return(res_result)
}
