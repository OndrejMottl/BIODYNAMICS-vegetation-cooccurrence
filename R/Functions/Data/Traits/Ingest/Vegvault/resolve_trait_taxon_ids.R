#' @title Resolve Trait Taxon IDs to Taxon Names
#' @description
#' Replaces numeric `taxon_id` values in a cleaned trait data frame
#' with the corresponding `taxon_name` from the `Taxa` table in the
#' VegVault SQLite database. Rows with unresolved IDs receive `NA`
#' for `taxon_name` (standard left-join behaviour).
#' @param data_trait_records
#' A data frame with at least the column `taxon_id` (integer or
#' numeric), typically the output of [filter_complete_trait_records()].
#' @param path_vegvault
#' A single character string giving the path to the VegVault
#' SQLite database
#' (default: `here::here("Data/Input/VegVault.sqlite")`).
#' @return
#' A tibble with columns `taxon_name`, `trait_domain_name`,
#' `trait_name`, and `trait_value`. The `taxon_id` column is
#' dropped from the output.
#' @details
#' Opens a fresh database connection, loads the `Taxa` table, filters
#' it to only the IDs present in `data_trait_records`, performs a left
#' join, and closes the connection via `on.exit()`.
#' @seealso [filter_complete_trait_records()],
#'   [load_continental_trait_records_from_vegvault()]
#' @export
resolve_trait_taxon_ids <- function(
    data_trait_records,
    path_vegvault = here::here(
      "Data/Input/VegVault.sqlite"
    )) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_records),
    msg = "'data_trait_records' must be a data frame."
  )

  assertthat::assert_that(
    "taxon_id" %in% base::names(data_trait_records),
    msg = "'data_trait_records' must contain a 'taxon_id' column."
  )

  assertthat::assert_that(
    base::is.character(path_vegvault) &&
      base::length(path_vegvault) == 1L,
    msg = "'path_vegvault' must be a single character string."
  )

  assertthat::assert_that(
    base::file.exists(path_vegvault),
    msg = stringr::str_glue(
      "VegVault database not found at: '{path_vegvault}'."
    )
  )

  connection_vegvault <-
    DBI::dbConnect(
      RSQLite::SQLite(),
      path_vegvault
    )

  base::on.exit(
    DBI::dbDisconnect(connection_vegvault),
    add = TRUE
  )

  data_taxon_lookup <-
    dplyr::tbl(connection_vegvault, "Taxa") |>
    dplyr::collect() |>
    dplyr::filter(
      .data[["taxon_id"]] %in% data_trait_records[["taxon_id"]]
    )

  data_trait_records_resolved <-
    data_trait_records |>
    dplyr::left_join(
      data_taxon_lookup |>
        dplyr::select("taxon_id", "taxon_name"),
      by = dplyr::join_by("taxon_id")
    ) |>
    dplyr::select(
      "taxon_name",
      dplyr::any_of(
        base::c(
          "trait_domain_name",
          "trait_name",
          "trait_value"
        )
      )
    )

  return(data_trait_records_resolved)
}
