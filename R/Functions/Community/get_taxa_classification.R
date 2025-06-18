get_taxa_classification <- function(data) {
  require(taxospace)

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
