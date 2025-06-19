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

  return(data_res)
}
