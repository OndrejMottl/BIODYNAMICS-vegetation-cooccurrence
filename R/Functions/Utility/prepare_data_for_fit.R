prepare_data_for_fit <- function(data = NULL, type = c("community", "abiotic")) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  type <- match.arg(type)

  assertthat::assert_that(
    type %in% c("community", "abiotic"),
    msg = "type must be either 'community' or 'abiotic'"
  )

  res <-
    switch(type,
      "community" = data %>%
        dplyr::mutate(
          sample_name = paste0(dataset_name, "__", age),
        ) %>%
        dplyr::select("sample_name", "taxon", "pollen_prop") %>%
        tidyr::pivot_wider(
          names_from = "taxon",
          values_from = "pollen_prop",
          values_fill = 0
        ) %>%
        tibble::column_to_rownames("sample_name"),
      "abiotic" = data %>%
        dplyr::mutate(
          sample_name = paste0(dataset_name, "__", age),
        ) %>%
        dplyr::select(
          "sample_name", "abiotic_variable_name", "abiotic_value"
        ) %>%
        tidyr::pivot_wider(
          names_from = "abiotic_variable_name",
          values_from = "abiotic_value",
          values_fill = NULL
        ) %>%
        tibble::column_to_rownames("sample_name")
    )

    return(res)
}
