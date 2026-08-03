#' @title Extract Community Taxa
#' @description
#' Extracts unique taxon names from in-memory long community data.
#' @param data_community
#' A data frame containing a `taxon` column.
#' @return A character vector of unique taxon names present in the data.
#' @details
#' Taxa retain their first-seen order. An empty community aborts because
#' downstream classification and model fitting require at least one taxon.
#' @examples
#' data_community <-
#'   tibble::tibble(
#'     taxon = base::c("Pinus", "Betula", "Pinus")
#'   )
#'
#' extract_community_taxa(data_community = data_community)
#' @export
extract_community_taxa <- function(data_community = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_community),
    msg = "data_community must be a data frame"
  )

  assertthat::assert_that(
    "taxon" %in% base::colnames(data_community),
    msg = "data_community must contain a `taxon` column"
  )

  vec_community_taxa <-
    data_community |>
    dplyr::distinct(taxon) |>
    dplyr::pull(taxon)

  if (
    base::length(vec_community_taxa) == 0L
  ) {
    cli::cli_abort(
      base::c(
        "No community taxa found in this spatial window.",
        "i" = stringr::str_c(
          "The pipeline cannot classify taxa or fit models for",
          " an empty community."
        ),
        "i" = stringr::str_c(
          "This spatial unit should be recorded as failed and",
          " the batch runner should continue."
        )
      )
    )
  }

  return(vec_community_taxa)
}
