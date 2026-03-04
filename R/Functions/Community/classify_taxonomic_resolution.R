#' @title Classify Taxonomic Resolution
#' @description
#' Classifies taxa in a data frame to a specified taxonomic resolution using
#' a classification table, and aggregates pollen proportions accordingly.
#' Supported resolutions are `kingdom`, `phylum`, `class`, `order`, `family`,
#' `genus`, and `species`.
#' @param data A data frame containing taxon data with columns including
#'   'taxon', 'dataset_name', 'age', and 'pollen_prop'.
#' @param data_classification_table A data frame mapping 'sel_name' to
#'   taxonomic levels (e.g., family, genus, species).
#' @param taxonomic_resolution A character string specifying the taxonomic
#'   resolution to classify to. Must be one of `'kingdom'`, `'phylum'`,
#'   `'class'`, `'order'`, `'family'`, `'genus'`, or `'species'`.
#' @return A data frame with taxa classified to the specified resolution and
#'   pollen proportions aggregated accordingly. The output preserves all
#'   dataset_name and age combinations for true negatives.
#' @details
#' Performs a left join to map taxa to the desired resolution, aggregates
#' pollen proportions, and ensures all dataset_name-age-taxon combinations are
#' present in the output. Taxa that have a valid `sel_name` entry in the
#' classification table but lack a value at the requested resolution level
#' (i.e. the resolution column is `NA`) are silently dropped with a warning.
#' This prevents a column named `NA` from appearing in the fitted community
#' matrix downstream.
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
    taxonomic_resolution %in% c(
      "kingdom", "phylum", "class", "order",
      "family", "genus", "species"
    ),
    msg = paste(
      "taxonomic_resolution must be one of",
      "'kingdom', 'phylum', 'class', 'order',",
      "'family', 'genus', or 'species'"
    )
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

  # Warn and drop taxa with no classification at the requested resolution.
  #   A taxon can have a valid sel_name row yet have NA at the target rank
  #   (e.g. classified only to family when genus is requested). Without
  #   this filter, the NA taxon flows into pivot_wider() and creates a
  #   column literally named NA in the fitted community matrix.
  vec_na_taxa <-
    data_classified %>%
    dplyr::filter(base::is.na(taxon)) %>%
    dplyr::distinct(taxon) %>%
    base::nrow()

  if (
    vec_na_taxa > 0
  ) {
    cli::cli_warn(
      c(
        "!" = paste0(
          "{vec_na_taxa} taxon/taxa ",
          "ha{?s/ve} no classification at the ",
          "'{taxonomic_resolution}' level and ",
          "{?was/were} dropped."
        ),
        "i" = paste0(
          "Check the classification table for missing ",
          "'{taxonomic_resolution}' values."
        )
      )
    )
  }

  data_classified <-
    data_classified %>%
    dplyr::filter(!base::is.na(taxon))

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
