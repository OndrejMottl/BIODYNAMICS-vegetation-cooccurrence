#' @title Get Trait Domain Names from VegVault
#' @description
#' Queries the VegVault SQLite database to retrieve all unique trait
#' domain names from the `TraitsDomain` table.
#' @param path_to_vegvault
#' A character string specifying the path to the VegVault SQLite
#' database (default: `here::here("Data/Input/VegVault.sqlite")`).
#' @param verbose
#' Logical. If `TRUE` (default), progress messages are printed to
#' the console via `cli`. Set to `FALSE` to suppress all console
#' output.
#' @return
#' A character vector of unique, non-`NA` trait domain names found
#' in the `TraitsDomain` table.
#' @details
#' The function performs the following steps:
#'
#'   1. Validates input parameters.
#'   2. Checks the presence of the VegVault SQLite database using
#'      `check_presence_of_vegvault()`.
#'   3. Opens a DBI connection to the SQLite database.
#'   4. Queries the `TraitsDomain` table for distinct
#'      `trait_domain_name` values and collects results.
#'   5. Closes the database connection.
#'   6. Removes `NA` values from the result.
#'   7. Asserts that at least one domain name was found.
#'   8. Optionally logs the result via `cli::cli_inform()`.
#'   9. Returns the character vector of domain names.
#' @seealso [extract_traits_from_vegvault()]
#' @export
get_trait_domain_names_from_vegvault <- function(
    path_to_vegvault = here::here(
      "Data/Input/VegVault.sqlite"
    ),
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.character(path_to_vegvault) &&
      base::length(path_to_vegvault) == 1L,
    msg = paste0(
      "'path_to_vegvault' must be a single character string."
    )
  )

  assertthat::assert_that(
    base::is.logical(verbose) &&
      base::length(verbose) == 1L,
    msg = paste0(
      "'verbose' must be a single logical value (TRUE or FALSE)."
    )
  )

  check_presence_of_vegvault(path_to_vegvault)

  vegvault_conn <-
    DBI::dbConnect(
      RSQLite::SQLite(),
      path_to_vegvault
    )

  vec_domains <-
    dplyr::tbl(vegvault_conn, "TraitsDomain") |>
    dplyr::distinct(.data[["trait_domain_name"]]) |>
    dplyr::collect() |>
    dplyr::pull("trait_domain_name")

  DBI::dbDisconnect(vegvault_conn)

  vec_domains <-
    vec_domains[!base::is.na(vec_domains)]

  assertthat::assert_that(
    base::length(vec_domains) >= 1L,
    msg = "No trait domain names found in TraitsDomain table."
  )

  if (
    isTRUE(verbose)
  ) {
    cli::cli_inform(
      c(
        "v" = base::paste0(
          base::length(vec_domains),
          " trait domain(s) found: ",
          base::paste(vec_domains, collapse = " | ")
        )
      )
    )
  }

  return(vec_domains)
}
