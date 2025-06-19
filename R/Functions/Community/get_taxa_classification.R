#' @title Get Taxa Classification
#' @description
#' Retrieves taxonomic classification for a vector of taxa using the
#' taxospace package. Filters results to include only plant taxa.
#' @param data A character vector of taxon names to classify.
#' @return A data frame with columns for selected name, taxonomic name,
#'   rank, and id.
#' @details
#' Uses taxospace::get_classification to retrieve classification. Flags and
#' filters for plant taxa (kingdom Plantae). Returns an empty tibble if no
#' plant taxa found.
#' @export
get_taxa_classification <- function(data) {
  require(taxospace)

  assertthat::assert_that(
    is.character(data) && length(data) > 0,
    msg = "data must be a non-empty character vector"
  )

  res_classification <-
    taxospace::get_classification(
      taxa_vec = data,
      # this is done so that the best match is returned
      #   even if the result is not flagged as "exact"
      use_only_exact_match = FALSE
    )

  res_plant <-
    res_classification %>%
    # flag taxa that are plants
    dplyr::mutate(
      is_plant = purrr::map_lgl(
        .x = classification,
        .f = ~ .x %>%
          dplyr::filter(rank == "kingdom") %>%
          dplyr::pull(name) %>%
          stringr::str_detect("Plantae") %>%
          any()
      )
    ) %>%
    # filter only plant taxa
    dplyr::filter(is_plant)

  if (
    isTRUE(nrow(res_plant) == 0)
  ) {
    return(
      tibble::tibble(
        sel_name = data,
        name = character(),
        rank = character(),
        id = integer(),
      )
    )
  }

  res_plant %>%
    dplyr::select(sel_name, classification) %>%
    tidyr::unnest(classification) %>%
    return()
}
