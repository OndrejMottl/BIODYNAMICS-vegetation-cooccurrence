#' @title Load Trait Domain Names from VegVault
#' @description
#' Loads all unique trait
#' domain names from the `TraitsDomain` table.
#' @param path_vegvault
#' A character string specifying the path to the VegVault SQLite
#' database (default: `here::here("Data/Input/VegVault.sqlite")`).
#' @param data_vegvault_release
#' A one-row data frame with the VegVault release record the pipeline
#' built from the same file (the `config_vegvault_release` target), as
#' returned by [load_vegvault_database_version()].
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
#'      `validate_vegvault_presence()`, and with
#'      [validate_vegvault_release()] that it holds the release in
#'      `data_vegvault_release`.
#'   3. Opens a read-only DBI connection to the SQLite database.
#'   4. Queries the `TraitsDomain` table for distinct
#'      `trait_domain_name` values and collects results.
#'   5. Closes the database connection.
#'   6. Removes `NA` values from the result.
#'   7. Asserts that at least one domain name was found.
#'   8. Optionally logs the result via `cli::cli_inform()`.
#'   9. Returns the character vector of domain names.
#' @seealso [load_trait_records_from_vegvault()],
#'   [validate_vegvault_release()]
#' @export
load_trait_domain_names_from_vegvault <- function(
    path_vegvault = here::here(
      "Data/Input/VegVault.sqlite"
    ),
    data_vegvault_release,
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.character(path_vegvault) &&
      base::length(path_vegvault) == 1L,
    msg = "'path_vegvault' must be a single character string."
  )

  assertthat::assert_that(
    base::is.logical(verbose) &&
      base::length(verbose) == 1L,
    msg = "'verbose' must be a single logical value (TRUE or FALSE)."
  )

  validate_vegvault_presence(path_vegvault)

  validate_vegvault_release(
    path_to_vegvault = path_vegvault,
    data_vegvault_release = data_vegvault_release
  )

  connection_vegvault <-
    DBI::dbConnect(
      drv = RSQLite::SQLite(),
      dbname = path_vegvault,
      flags = RSQLite::SQLITE_RO
    )
  base::on.exit(DBI::dbDisconnect(connection_vegvault), add = TRUE)

  vec_trait_domain_names <-
    dplyr::tbl(connection_vegvault, "TraitsDomain") |>
    dplyr::distinct(.data[["trait_domain_name"]]) |>
    dplyr::collect() |>
    dplyr::pull("trait_domain_name")

  vec_trait_domain_names <-
    vec_trait_domain_names[!base::is.na(vec_trait_domain_names)]

  assertthat::assert_that(
    base::length(vec_trait_domain_names) >= 1L,
    msg = "No trait domain names found in TraitsDomain table."
  )

  if (
    base::isTRUE(verbose)
  ) {
    cli::cli_inform(
      c(
        "v" = stringr::str_c(
          base::length(vec_trait_domain_names),
          " trait domain(s) found: ",
          stringr::str_c(vec_trait_domain_names, collapse = " | ")
        )
      )
    )
  }

  return(vec_trait_domain_names)
}
