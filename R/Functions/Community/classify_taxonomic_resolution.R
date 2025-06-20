#' @title Classify Taxonomic Resolution
#' @description
#' Classifies taxa in a data frame to a specified taxonomic resolution (family,
#' genus, or species) using a classification table, and aggregates pollen
#' proportions accordingly.
#' @param data A data frame containing taxon data with columns including
#'   'taxon', 'dataset_name', 'age', and 'pollen_prop'.
#' @param data_classification_table A data frame mapping 'sel_name' to
#'   taxonomic levels (e.g., family, genus, species).
#' @param taxonomic_resolution A character string specifying the taxonomic
#'   resolution to classify to. Must be one of 'family', 'genus', or 'species'.
#' @return A data frame with taxa classified to the specified resolution and
#'   pollen proportions aggregated accordingly. The output preserves all
#'   dataset_name and age combinations for true negatives.
#' @details
#' Performs a left join to map taxa to the desired resolution, aggregates
#' pollen proportions, and ensures all dataset_name-age-taxon combinations are
#' present in the output.
#' @export
classify_taxonomic_resolution <- function(data, data_classification_table, taxonomic_resolution) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    all(c("taxon", "dataset_name", "age", "pollen_prop") %in% colnames(data)),
    msg = "data must contain columns: taxon, dataset_name, age, and pollen_prop"
  )

  assertthat::assert_that(
    is.data.frame(data_classification_table),
    msg = "data_classification_table must be a data frame"
  )

  assertthat::assert_that(
    is.character(taxonomic_resolution) && length(taxonomic_resolution) == 1,
    msg = "taxonomic_resolution must be a single character string"
  )

  assertthat::assert_that(
    taxonomic_resolution %in% c("family", "genus", "species"),
    msg = "taxonomic_resolution must be one of 'family', 'genus', or 'species'"
  )

  assertthat::assert_that(
    any(taxonomic_resolution %in% colnames(data_classification_table)),
    msg = "taxonomic_resolution must be a column in data_classification_table"
  )

  data_classification_table_sub <-
    data_classification_table %>%
    dplyr::select(sel_name, !!taxonomic_resolution)

  data_classified <-
    data %>%
    dplyr::left_join(
      data_classification_table_sub,
      by = dplyr::join_by("taxon" == "sel_name")
    ) %>%
    dplyr::select(-taxon) %>%
    dplyr::rename(
      taxon = !!taxonomic_resolution
    )

  # make dummy table with all dataset_name and age combinations
  #   this is needed to ensure that all combinations are present in the
  #   final output to preserve true negative values
  data_dataset_age_cross_ref <-
    data_classified %>%
    dplyr::distinct(dataset_name, age, taxon)

  res <-
    data_classified %>%
    tidyr::drop_na(pollen_prop) %>%
    dplyr::group_by(
      dataset_name, age, taxon
    ) %>%
    dplyr::summarise(
      .groups = "drop",
      pollen_prop = sum(pollen_prop)
    ) %>%
    dplyr::full_join(
      data_dataset_age_cross_ref,
      by = c("dataset_name", "age", "taxon")
    ) %>%
    dplyr::arrange(age, dataset_name, taxon) %>%
    dplyr::select(
      names(data)
    )

  return(res)
}
