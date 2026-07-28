#' @title Get Community Taxa
#' @description
#' Extracts a vector of unique taxa from a community data frame.
#' @param data A data frame containing a 'taxon' column.
#' @return A character vector of unique taxon names present in the data.
#' @details
#' Uses dplyr to select distinct values from the 'taxon' column and returns
#' them as a vector.
#' @export
get_community_taxa <- function(data) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    "taxon" %in% colnames(data),
    msg = "data must contain a 'taxon' column"
  )

  data_res <-
    data %>%
    dplyr::distinct(taxon) %>%
    dplyr::pull(taxon)

  if (
    base::length(data_res) == 0L
  ) {
    cli::cli_abort(
      c(
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

  return(data_res)
}
