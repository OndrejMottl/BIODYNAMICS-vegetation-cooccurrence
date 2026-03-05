#' @title Classify Taxonomic Resolution
#' @description
#' Classifies taxa in a data frame to a specified taxonomic resolution
#' using a classification table, and aggregates pollen proportions
#' accordingly. Supported resolutions are `kingdom`, `phylum`, `class`,
#' `order`, `family`, `genus`, and `species`.
#' @param data
#' A data frame containing taxon data with columns including 'taxon',
#' 'dataset_name', 'age', and 'pollen_prop'.
#' @param data_classification_table
#' A data frame mapping 'sel_name' to taxonomic levels. Must contain
#' at least one rank column at or below `taxonomic_resolution`
#' (e.g. 'family', 'genus', 'species').
#' @param taxonomic_resolution
#' A character string specifying the finest taxonomic level to use.
#' Must be one of `'kingdom'`, `'phylum'`, `'class'`, `'order'`,
#' `'family'`, `'genus'`, or `'species'`. Taxa will be classified at
#' this rank if possible, or at the coarsest available rank below it
#' if not (fallback behaviour).
#' @return
#' A data frame with taxa classified to the finest available rank at
#' or below `taxonomic_resolution` and pollen proportions aggregated
#' accordingly. The output preserves all dataset_name and age
#' combinations for true negatives.
#' @details
#' Performs a left join to map taxa to all available rank columns up
#' to and including `taxonomic_resolution`. The finest non-NA rank is
#' then selected via `dplyr::coalesce()` applied from finest to
#' coarsest. This means a taxon known only to family when genus is
#' requested will be assigned to its family name rather than dropped.
#' Taxa with no valid classification at any available rank are removed
#' with a `cli::cli_warn()` warning. Taxa that fall back to a coarser
#' rank are reported via `cli::cli_inform()`. Ranks finer than
#' `taxonomic_resolution` (e.g. species when genus is requested) are
#' never used, even when present in the classification table. The
#' NA-drop step prevents a column literally named NA appearing in the
#' community matrix produced by downstream `pivot_wider()` calls.
#' @seealso [filter_non_plantae_taxa()], [filter_rare_taxa()]
#' @export
classify_taxonomic_resolution <- function(
    data,
    data_classification_table,
    taxonomic_resolution) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    all(
      c("taxon", "dataset_name", "age", "pollen_prop") %in%
        colnames(data)
    ),
    msg = paste(
      "data must contain columns:",
      "taxon, dataset_name, age, and pollen_prop"
    )
  )

  assertthat::assert_that(
    is.data.frame(data_classification_table),
    msg = "data_classification_table must be a data frame"
  )

  assertthat::assert_that(
    is.character(taxonomic_resolution) &&
      length(taxonomic_resolution) == 1,
    msg = "taxonomic_resolution must be a single character string"
  )

  vec_all_ranks <- c(
    "kingdom", "phylum", "class", "order",
    "family", "genus", "species"
  )

  assertthat::assert_that(
    taxonomic_resolution %in% vec_all_ranks,
    msg = paste(
      "taxonomic_resolution must be one of",
      "'kingdom', 'phylum', 'class', 'order',",
      "'family', 'genus', or 'species'"
    )
  )

  # All ranks from kingdom up to and including the requested level.
  #   These are the only ranks eligible for fallback assignment.
  vec_target_ranks <-
    vec_all_ranks[
      base::seq_len(
        base::which(vec_all_ranks == taxonomic_resolution)
      )
    ]

  # Subset to ranks actually present in the classification table.
  vec_available_ranks <-
    base::intersect(
      vec_target_ranks,
      base::colnames(data_classification_table)
    )

  assertthat::assert_that(
    base::length(vec_available_ranks) > 0,
    msg = paste0(
      "data_classification_table must contain at least one ",
      "rank column at or below '",
      taxonomic_resolution,
      "'. Expected one of: ",
      paste(vec_target_ranks, collapse = ", ")
    )
  )

  data_classification_table_sub <-
    data_classification_table |>
    dplyr::select(
      sel_name,
      dplyr::all_of(vec_available_ranks)
    )

  # Join all available rank columns, then coalesce from finest to
  #   coarsest so each taxon gets the most-specific non-NA label.
  data_joined <-
    data |>
    dplyr::left_join(
      data_classification_table_sub,
      by = dplyr::join_by("taxon" == "sel_name")
    ) |>
    dplyr::select(-taxon) |>
    dplyr::mutate(
      taxon = dplyr::coalesce(
        !!!rlang::syms(base::rev(vec_available_ranks))
      )
    )

  # Report taxa that fell back to a coarser rank.
  #   These are kept in the data but flagged informally.
  if (taxonomic_resolution %in% vec_available_ranks) {
    n_fallback <-
      data_joined |>
      dplyr::filter(
        base::is.na(!!rlang::sym(taxonomic_resolution)),
        !base::is.na(taxon)
      ) |>
      dplyr::distinct(taxon) |>
      base::nrow()

    if (n_fallback > 0) {
      cli::cli_inform(
        c(
          "i" = paste0(
            "{n_fallback} taxon/taxa could not be classified ",
            "to '{taxonomic_resolution}' and ",
            "{?was/were} assigned to a coarser rank."
          )
        )
      )
    }
  }

  data_classified <-
    data_joined |>
    dplyr::select(-dplyr::all_of(vec_available_ranks))

  # Warn and drop taxa with no valid classification at any available
  #   rank. Without this filter, the NA taxon flows into pivot_wider()
  #   and creates a column literally named NA in the community matrix.
  vec_na_taxa <-
    data_classified |>
    dplyr::filter(base::is.na(taxon)) |>
    dplyr::distinct(taxon) |>
    base::nrow()

  if (vec_na_taxa > 0) {
    cli::cli_warn(
      c(
        "!" = paste0(
          "{vec_na_taxa} taxon/taxa ",
          "ha{?s/ve} no classification at any available ",
          "rank up to '{taxonomic_resolution}' and ",
          "{?was/were} dropped."
        ),
        "i" = paste0(
          "Check the classification table for missing ",
          "rank values up to '{taxonomic_resolution}'."
        )
      )
    )
  }

  data_classified <-
    data_classified |>
    dplyr::filter(!base::is.na(taxon))

  # make dummy table with all dataset_name and age combinations
  #   this is needed to ensure that all combinations are present in the
  #   final output to preserve true negative values
  data_dataset_age_cross_ref <-
    data_classified |>
    dplyr::distinct(dataset_name, age, taxon)

  res <-
    data_classified |>
    tidyr::drop_na(pollen_prop) |>
    dplyr::group_by(
      dataset_name, age, taxon
    ) |>
    dplyr::summarise(
      .groups = "drop",
      pollen_prop = sum(pollen_prop)
    ) |>
    dplyr::full_join(
      data_dataset_age_cross_ref,
      by = c("dataset_name", "age", "taxon")
    ) |>
    dplyr::arrange(age, dataset_name, taxon) |>
    dplyr::select(
      names(data)
    )

  return(res)
}
