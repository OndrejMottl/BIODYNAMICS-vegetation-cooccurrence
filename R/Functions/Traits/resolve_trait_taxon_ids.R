#' @title Resolve Trait Taxon IDs to Taxon Names
#' @description
#' Replaces numeric `taxon_id` values in a cleaned trait data frame
#' with the corresponding `taxon_name` from the `Taxa` table in the
#' VegVault SQLite database. Rows with unresolved IDs receive `NA`
#' for `taxon_name` (standard left-join behaviour).
#' @param data_clean
#' A data frame with at least the column `taxon_id` (integer or
#' numeric), typically the output of [clean_raw_trait_data()].
#' @param path_to_vegvault
#' A single character string giving the path to the VegVault
#' SQLite database
#' (default: `here::here("Data/Input/VegVault.sqlite")`).
#' @return
#' A tibble with columns `taxon_name`, `trait_domain_name`,
#' `trait_name`, and `trait_value`. The `taxon_id` column is
#' dropped from the output.
#' @details
#' Opens a fresh database connection, loads the `Taxa` table, filters
#' it to only the IDs present in `data_clean`, performs a left join,
#' and immediately disconnects. The connection is always closed —
#' even if the join step errors — through standard sequential
#' disconnect after collect.
#' @seealso [clean_raw_trait_data()],
#'   [extract_and_clean_continent_traits()]
#' @export
resolve_trait_taxon_ids <- function(
    data_clean,
    path_to_vegvault = here::here(
      "Data/Input/VegVault.sqlite"
    )) {
  assertthat::assert_that(
    base::is.data.frame(data_clean),
    msg = "'data_clean' must be a data frame."
  )

  assertthat::assert_that(
    "taxon_id" %in% base::names(data_clean),
    msg = "'data_clean' must contain a 'taxon_id' column."
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

  vegvault_conn <-
    DBI::dbConnect(
      RSQLite::SQLite(),
      path_to_vegvault
    )

  data_taxon_lookup <-
    dplyr::tbl(vegvault_conn, "Taxa") |>
    dplyr::collect() |>
    dplyr::filter(
      .data[["taxon_id"]] %in% data_clean[["taxon_id"]]
    )

  DBI::dbDisconnect(vegvault_conn)

  res <-
    data_clean |>
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

  return(res)
}
