get_community_taxa <- function(data) {
  data_res <-
    data %>%
    dplyr::distinct(taxon) %>%
    dplyr::pull(taxon)

  return(data_res)
}
