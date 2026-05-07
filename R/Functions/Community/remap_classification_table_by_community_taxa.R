#' @title Remap Classification Table by Community Taxa
#' @description
#' Re-keys a classification table so that `sel_name` equals the
#' classified taxon name at the specified `taxonomic_resolution`,
#' rather than the original raw pollen name. For each classified
#' taxon name, one representative row is kept (preferring rows where
#' the original `sel_name` already matches the classified name).
#' Rank columns finer than `taxonomic_resolution` are set to
#' `NA_character_` so that downstream
#' `resolve_classification_to_finest_rank()` returns the classified
#' name as the canonical label rather than a species name.
#' @param data_classification_table
#' A data frame mapping raw taxon names (`sel_name`) to all
#' taxonomic rank columns (`kingdom`, `phylum`, `class`, `order`,
#' `family`, `genus`, `species`). This is typically
#' `data_combined_classification_table` produced by
#' `pipe_segment_community_preprocess_paleo`.
#' @param data_community_classified
#' A data frame containing a `taxon` column with the classified
#' community taxon names (e.g. genus or family names). Used to
#' determine which classified names are present in the community
#' and should be retained in the output table.
#' @param taxonomic_resolution
#' A single character string specifying the finest taxonomic rank
#' to use for classification. Must be one of `"kingdom"`,
#' `"phylum"`, `"class"`, `"order"`, `"family"`, `"genus"`, or
#' `"species"`.
#' @return
#' A data frame with the same columns as `data_classification_table`
#' (`sel_name`, `kingdom`, `phylum`, `class`, `order`, `family`,
#' `genus`, `species`) where:
#' - `sel_name` is the classified taxon name (not the raw pollen
#'   name).
#' - One row per classified taxon name (duplicate rows removed,
#'   direct-match rows preferred).
#' - Rank columns finer than `taxonomic_resolution` are set to
#'   `NA_character_`.
#' - Only classified names present in `data_community_classified`
#'   are included.
#' @details
#' Internally, ranks from `kingdom` up to and including
#' `taxonomic_resolution` are used to coalesce a `classified_name`
#' column via `dplyr::pick()` and `purrr::reduce(dplyr::coalesce)`.
#' The coalesce applies ranks from finest-to-coarsest (reversed)
#' so that the most-specific available rank is used. After
#' deduplication, `sel_name` is replaced with `classified_name`
#' and finer rank columns are nulled out.
#' @seealso [classify_taxonomic_resolution()],
#'   [resolve_classification_to_finest_rank()],
#'   [build_community_taxon_trait_table()]
#' @export
remap_classification_table_by_community_taxa <- function(
    data_classification_table,
    data_community_classified,
    taxonomic_resolution) {
  vec_all_ranks <-
    base::c(
      "kingdom", "phylum", "class", "order",
      "family", "genus", "species"
    )

  assertthat::assert_that(
    base::is.data.frame(data_classification_table),
    msg = "'data_classification_table' must be a data frame."
  )

  assertthat::assert_that(
    base::all(
      base::c("sel_name", vec_all_ranks) %in%
        base::colnames(data_classification_table)
    ),
    msg = stringr::str_glue(
      "'data_classification_table' must contain columns: ",
      "'sel_name', {stringr::str_c(vec_all_ranks, collapse = ', ')}."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_community_classified),
    msg = "'data_community_classified' must be a data frame."
  )

  assertthat::assert_that(
    "taxon" %in% base::colnames(data_community_classified),
    msg = "'data_community_classified' must contain a 'taxon' column."
  )

  assertthat::assert_that(
    base::is.character(taxonomic_resolution) &&
      base::length(taxonomic_resolution) == 1L,
    msg = "'taxonomic_resolution' must be a single character string."
  )

  assertthat::assert_that(
    taxonomic_resolution %in% vec_all_ranks,
    msg = stringr::str_glue(
      "'taxonomic_resolution' must be one of: ",
      "{stringr::str_c(vec_all_ranks, collapse = ', ')}."
    )
  )

  vec_target_ranks <-
    vec_all_ranks[
      base::seq_len(
        base::which(vec_all_ranks == taxonomic_resolution)
      )
    ]

  vec_finer_ranks <-
    base::setdiff(vec_all_ranks, vec_target_ranks)

  vec_classified <-
    data_community_classified |>
    dplyr::distinct(taxon) |>
    dplyr::pull(taxon)

  res <-
    data_classification_table |>
    dplyr::mutate(
      # Note: !!!rlang::syms() cannot be used inside tar_target()
      #   commands because targets eagerly evaluates !!! at call
      #   time. purrr::reduce() + dplyr::pick() avoids rlang
      #   injection while producing an identical result — and is
      #   also the preferred pipe-over-nesting pattern for this
      #   project.
      classified_name = dplyr::pick(
        dplyr::all_of(base::rev(vec_target_ranks))
      ) |>
        base::as.list() |>
        purrr::reduce(dplyr::coalesce)
    ) |>
    dplyr::filter(
      .data$classified_name %in% vec_classified
    ) |>
    dplyr::mutate(
      .is_direct =
        .data$sel_name == .data$classified_name
    ) |>
    dplyr::arrange(dplyr::desc(.data$.is_direct)) |>
    dplyr::distinct(classified_name, .keep_all = TRUE) |>
    dplyr::mutate(
      sel_name = .data$classified_name,
      dplyr::across(
        dplyr::all_of(vec_finer_ranks),
        ~NA_character_
      )
    ) |>
    dplyr::select(-".is_direct", -"classified_name") |>
    dplyr::select(
      dplyr::all_of(
        base::c(
          "sel_name", "kingdom", "phylum", "class",
          "order", "family", "genus", "species"
        )
      )
    )

  return(res)
}
