make_classification_table <- function(data) {
  dplyr::bind_rows(data) %>%
    dplyr::filter(
      rank %in% c(
        "family", "genus", "species"
      )
    ) %>%
    dplyr::distinct(
      sel_name, rank, name
    ) %>%
    tidyr::pivot_wider(
      names_from = rank,
      values_from = name
    ) %>%
    return()
}
