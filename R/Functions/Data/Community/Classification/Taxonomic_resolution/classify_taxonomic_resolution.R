#' @title Classify Taxonomic Resolution
#' @description
#' Classifies taxa in a data frame to a specified taxonomic resolution
#' using a classification table, and aggregates pollen proportions
#' accordingly. Supported resolutions are `kingdom`, `phylum`, `class`,
#' `order`, `family`, `genus`, and `species`.
#' @param data_source
#' A data frame containing taxon data with columns including 'taxon',
#' 'dataset_name', 'age', and 'value'.
#' @param data_classification_table
#' A data frame mapping 'sel_name' to taxonomic levels. Must contain
#' at least one rank column at or below `vec_taxonomic_resolution`
#' (e.g. 'family', 'genus', 'species').
#' @param vec_taxonomic_resolution
#' A character string specifying the finest taxonomic level to use.
#' Must be one of `'kingdom'`, `'phylum'`, `'class'`, `'order'`,
#' `'family'`, `'genus'`, or `'species'`. Taxa will be classified at
#' this rank if possible, or at the coarsest available rank below it
#' if not (fallback behaviour).
#' @param flag_verbose
#' Logical. If `TRUE` (default), classification warnings and fallback
#' messages are printed.
#' @return
#' A data frame with taxa classified to the finest available rank at
#' or below `vec_taxonomic_resolution` and pollen proportions aggregated
#' accordingly. The output preserves all dataset_name and age
#' combinations for true negatives.
#' @details
#' Performs a left join to map taxa to all available rank columns up
#' to and including `vec_taxonomic_resolution`. The finest non-NA rank is
#' then selected via `dplyr::coalesce()` applied from finest to
#' coarsest. This means a taxon known only to family when genus is
#' requested will be assigned to its family name rather than dropped.
#' Taxa with no valid classification at any available rank are removed
#' with a `cli::cli_warn()` warning. Taxa that fall back to a coarser
#' rank are reported via `cli::cli_inform()`. Ranks finer than
#' `vec_taxonomic_resolution` (e.g. species when genus is requested) are
#' never used, even when present in the classification table. The
#' NA-drop step prevents a column literally named NA appearing in the
#' community matrix produced by downstream `pivot_wider()` calls.
#' @seealso [filter_community_to_plantae()],
#' [filter_community_by_minimum_proportion()]
#' @export
classify_taxonomic_resolution <- function(
    data_source,
    data_classification_table,
    vec_taxonomic_resolution,
    flag_verbose = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data_source),
    msg = "data_source must be a data frame"
  )

  assertthat::assert_that(
    base::all(
      base::c("taxon", "dataset_name", "age", "value") %in%
        base::colnames(data_source)
    ),
    msg = base::paste(
      "data_source must contain columns:",
      "taxon, dataset_name, age, and value"
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_classification_table),
    msg = "data_classification_table must be a data frame"
  )

  assertthat::assert_that(
    base::is.character(vec_taxonomic_resolution) &&
      base::length(vec_taxonomic_resolution) == 1,
    msg = stringr::str_c(
      "vec_taxonomic_resolution must be a single character string"
    )
  )

  assertthat::assert_that(
    base::is.logical(flag_verbose) &&
      base::length(flag_verbose) == 1L,
    msg = "flag_verbose must be a single logical value"
  )

  vec_all_ranks <-
    base::c(
      "kingdom", "phylum", "class", "order",
      "family", "genus", "species"
    )

  assertthat::assert_that(
    vec_taxonomic_resolution %in% vec_all_ranks,
    msg = base::paste(
      "vec_taxonomic_resolution must be one of",
      "'kingdom', 'phylum', 'class', 'order',",
      "'family', 'genus', or 'species'"
    )
  )

  # All ranks from kingdom up to and including the requested level.
  #   These are the only ranks eligible for fallback assignment.
  vec_target_ranks <-
    vec_all_ranks[
      base::seq_len(
        base::which(
          vec_all_ranks == vec_taxonomic_resolution
        )
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
    msg = base::paste0(
      "data_classification_table must contain at least one ",
      "rank column at or below '",
      vec_taxonomic_resolution,
      "'. Expected one of: ",
      base::paste(vec_target_ranks, collapse = ", ")
    )
  )

  data_classification_table_selected <-
    data_classification_table |>
    dplyr::select(
      sel_name,
      dplyr::all_of(vec_available_ranks)
    )

  # Join all available rank columns, then coalesce from finest to
  #   coarsest so each taxon gets the most-specific non-NA label.
  data_community_joined <-
    data_source |>
    dplyr::left_join(
      data_classification_table_selected,
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
  if (vec_taxonomic_resolution %in% vec_available_ranks) {
    n_fallback_taxa <-
      data_community_joined |>
      dplyr::filter(
        base::is.na(
          !!rlang::sym(vec_taxonomic_resolution)
        ),
        !base::is.na(taxon)
      ) |>
      dplyr::distinct(taxon) |>
      base::nrow()

    if (
      n_fallback_taxa > 0 &&
        base::isTRUE(flag_verbose)
    ) {
      cli::cli_inform(
        c(
          "i" = base::paste0(
            "{n_fallback_taxa} taxon/taxa could not be classified ",
            "to '{vec_taxonomic_resolution}' and ",
            "{?was/were} assigned to a coarser rank."
          )
        )
      )
    }
  }

  data_community_classified_raw <-
    data_community_joined |>
    dplyr::select(-dplyr::all_of(vec_available_ranks))

  # Warn and drop taxa with no valid classification at any available
  #   rank. Without this filter, the NA taxon flows into pivot_wider()
  #   and creates a column literally named NA in the community matrix.
  n_unclassified_taxa <-
    data_community_classified_raw |>
    dplyr::filter(base::is.na(taxon)) |>
    dplyr::distinct(taxon) |>
    base::nrow()

  if (
    n_unclassified_taxa > 0 &&
      base::isTRUE(flag_verbose)
  ) {
    cli::cli_warn(
      c(
        "!" = base::paste0(
          "{n_unclassified_taxa} taxon/taxa ",
          "ha{?s/ve} no classification at any available ",
          "rank up to '{vec_taxonomic_resolution}' and ",
          "{?was/were} dropped."
        ),
        "i" = base::paste0(
          "Check the classification table for missing ",
          "rank values up to '{vec_taxonomic_resolution}'."
        )
      )
    )
  }

  data_community_classified <-
    data_community_classified_raw |>
    dplyr::filter(!base::is.na(taxon))

  vec_identifier_columns <-
    base::setdiff(
      base::names(data_source),
      base::c("taxon", "value")
    )

  # make dummy table with all dataset_name and age combinations
  #   this is needed to ensure that all combinations are present in the
  #   final output to preserve true negative values
  data_dataset_age_cross_reference <-
    data_community_classified |>
    dplyr::distinct(
      dplyr::across(
        dplyr::all_of(
          base::c(vec_identifier_columns, "taxon")
        )
      )
    )

  res_community_classified <-
    data_community_classified |>
    tidyr::drop_na(value) |>
    dplyr::group_by(
      dplyr::across(
        dplyr::all_of(
          base::c(vec_identifier_columns, "taxon")
        )
      )
    ) |>
    dplyr::summarise(
      .groups = "drop",
      value = base::sum(value)
    ) |>
    dplyr::full_join(
      data_dataset_age_cross_reference,
      by = base::c(vec_identifier_columns, "taxon")
    ) |>
    dplyr::arrange(age, dataset_name, taxon) |>
    dplyr::select(
      base::names(data_source)
    )

  return(res_community_classified)
}
