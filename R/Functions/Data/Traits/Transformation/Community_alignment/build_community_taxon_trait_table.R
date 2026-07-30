#' @title Build Community-Taxon-Level Trait Table
#' @description
#' Builds a wide-format trait table where rows correspond to
#' community taxon names (as they appear in pollen/community
#' data) rather than species names. For each trait observation
#' the function looks up the full taxonomic lineage of the
#' source species and maps it to every community taxon that
#' appears anywhere in that lineage (kingdom -> species). Trait
#' values are then aggregated (median) per
#' `(community_taxon, trait_domain)` and pivoted to a wide
#' matrix ready for `assign_functional_type_clusters()`.
#'
#' This correctly handles pollen taxa resolved only to family
#' or higher rank: "Asteraceae" in the community data will
#' collect the median across all trait species whose lineage
#' contains Asteraceae.
#' @param data_trait_records
#' A data frame of trait observations in long format.
#' Must contain columns `taxon_name` (character; the original
#' trait species name, matching `sel_name` in
#' `data_trait_taxonomy`), `trait_domain_name`
#' (character; trait domain label), and `trait_value`
#' (numeric; observed value).
#' @param data_trait_taxonomy
#' A wide-format taxonomic classification table with one row
#' per `sel_name` and columns `sel_name`, `kingdom`,
#' `phylum`, `class`, `order`, `family`, `genus`, `species`.
#' Typically produced by `build_classification_table()` and
#' combined with manual overrides via
#' `build_combined_classification_table()`. `sel_name` must match
#' the `taxon_name` values in `data_trait_records` (after trait
#' QC and correction).
#' @param data_community_taxonomy
#' A wide-format taxonomic classification table for the
#' community (pollen) taxa in this project / spatial unit.
#' Must contain a `sel_name` column (the pollen taxon name
#' as it appears in the community data) and the seven rank
#' columns `kingdom`, `phylum`, `class`, `order`, `family`,
#' `genus`, `species`. Typically the output of
#' `build_combined_classification_table()` applied to the pollen
#' community. `sel_name` provides the allow-list of community
#' taxa; each taxon is resolved to its finest available rank
#' (via `resolve_classification_to_finest_rank()`) to look up
#' matching entries in `data_trait_taxonomy`. This
#' correctly maps "Betulaceae Undiff" -> canonical "Betulaceae",
#' "Betula Nana-Type" -> canonical "Betula", etc.
#' @param aggregation_method
#' A single character string specifying how trait values are
#' aggregated per `(community_taxon, trait_domain_name)` pair.
#' Must be one of `"median"` (default) or `"mean"`.
#' @param verbose
#' A single logical. If `TRUE` (default), progress messages
#' reporting coverage statistics are printed via `cli`.
#' @return
#' A tibble with one row per community taxon that could be
#' matched to at least one trait observation. Contains a
#' `taxon_name` column (the original pollen taxon name from
#' `data_community_taxonomy$sel_name`) plus one
#' numeric column per distinct `trait_domain_name`. Community
#' taxa with no trait match are silently absent (not filled
#' with `NA` rows). The column order is `taxon_name` followed
#' by trait domain columns in alphabetical order.
#' @details
#' **Algorithm**:
#' \enumerate{
#'   \item Apply `resolve_classification_to_finest_rank()` to
#'     `data_community_taxonomy` to obtain a
#'     canonical name for each pollen taxon — e.g.
#'     "Betulaceae Undiff" -> "Betulaceae",
#'     "Betula Nana-Type" -> "Betula". This handles all pollen
#'     suffixes ("Undiff", "-Type", "Subg", "Sect", "Cf")
#'     without any string manipulation.
#'   \item Pivot the seven rank columns of
#'     `data_trait_taxonomy` (traits-side) to long
#'     format. Retain only rows whose rank value matches a
#'     canonical name from step 1.
#'   \item Join the community canonical-name table to the
#'     trait classification table on `canonical_name`
#'     (`many-to-many`), producing a mapping
#'     `(pollen_taxon, canonical_name, trait_species)`.
#'   \item Inner-join to `data_trait_records` on
#'     `taxon_name == trait_species`, giving one row per
#'     `(pollen_taxon, trait_domain_name, observation)`.
#'   \item Aggregate: median (or mean) of `trait_value` per
#'     `(pollen_taxon, trait_domain_name)`.
#'   \item Pivot wide: `taxon_name` (pollen taxon) ×
#'     trait domain columns.
#' }
#' @seealso [build_classification_table()],
#'   [build_combined_classification_table()],
#'   [resolve_classification_to_finest_rank()],
#'   [assign_functional_type_clusters()],
#'   [classify_to_functional_type()]
#' @export
build_community_taxon_trait_table <- function(
    data_trait_records,
    data_trait_taxonomy,
    data_community_taxonomy,
    aggregation_method = "median",
    verbose = TRUE) {

  #--------------------------------------------------#
  # 1. Input validation -----
  #--------------------------------------------------#

  assertthat::assert_that(
    base::is.data.frame(data_trait_records),
    msg = "`data_trait_records` must be a data frame."
  )

  assertthat::assert_that(
    base::all(
      base::c("taxon_name", "trait_domain_name", "trait_value") %in%
        base::colnames(data_trait_records)
    ),
    msg = stringr::str_glue(
      "`data_trait_records` must contain columns: ",
      "'taxon_name', 'trait_domain_name', 'trait_value'."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_trait_taxonomy),
    msg = "`data_trait_taxonomy` must be a data frame."
  )

  required_taxonomy_columns <-
    base::c(
      "sel_name", "kingdom", "phylum", "class", "order",
      "family", "genus", "species"
    )

  assertthat::assert_that(
    base::all(
      required_taxonomy_columns %in% base::colnames(data_trait_taxonomy)
    ),
    msg = stringr::str_glue(
      "`data_trait_taxonomy` must contain columns: ",
      "{stringr::str_c(required_taxonomy_columns, collapse = ', ')}."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_community_taxonomy),
    msg = "`data_community_taxonomy` must be a data frame."
  )

  assertthat::assert_that(
    base::all(
      required_taxonomy_columns %in%
        base::colnames(data_community_taxonomy)
    ),
    msg = stringr::str_glue(
      "`data_community_taxonomy` must contain ",
      "columns: ",
      "{stringr::str_c(required_taxonomy_columns, collapse = ', ')}."
    )
  )

  assertthat::assert_that(
    base::nrow(data_community_taxonomy) > 0L,
    msg = stringr::str_glue(
      "`data_community_taxonomy` must have ",
      "at least one row."
    )
  )

  assertthat::assert_that(
    base::is.logical(verbose) && base::length(verbose) == 1L,
    msg = "`verbose` must be a single logical."
  )

  assertthat::assert_that(
    base::is.character(aggregation_method) &&
      base::length(aggregation_method) == 1L &&
      aggregation_method %in% base::c("median", "mean"),
    msg = "`aggregation_method` must be one of 'median' or 'mean'."
  )

  #--------------------------------------------------#
  # 2. Resolve community taxa to canonical names -----
  #--------------------------------------------------#

  # Use resolve_classification_to_finest_rank() to map each pollen taxon
  # to its finest available taxonomic rank value.  This collapses pollen
  # suffixes: "Betulaceae Undiff" -> "Betulaceae", "Betula Nana-Type" ->
  # "Betula", "Pinus Subg Pinus" -> "Pinus", etc., without any string
  # manipulation.
  data_community_to_canonical <-
    resolve_classification_to_finest_rank(
      data_classification_table = data_community_taxonomy,
      vec_taxon_column_name = "canonical_name"
    )

  canonical_taxon_names <-
    data_community_to_canonical |>
    dplyr::pull(.data$canonical_name) |>
    base::unique()

  #--------------------------------------------------#
  # 3. Map canonical names to trait species -----
  #--------------------------------------------------#

  # Pivot the traits classification table long and retain only rows whose
  # rank value matches a canonical community name.
  # ALL matching ranks are kept so that coarser community taxa (family,
  # order) accumulate contributions from every member trait species.
  taxonomy_ranks <-
    base::c(
      "kingdom", "phylum", "class", "order", "family", "genus", "species"
    )

  data_canonical_to_trait_species <-
    data_trait_taxonomy |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(taxonomy_ranks),
      names_to = "rank",
      values_to = "canonical_name"
    ) |>
    dplyr::filter(!base::is.na(.data$canonical_name)) |>
    dplyr::filter(.data$canonical_name %in% canonical_taxon_names) |>
    dplyr::select(
      dplyr::all_of(base::c("sel_name", "canonical_name"))
    ) |>
    dplyr::rename(trait_species = "sel_name")

  # Join: pollen taxon <-> canonical name <-> trait species
  data_community_to_trait_species <-
    data_community_to_canonical |>
    dplyr::rename(taxon_community = "sel_name") |>
    dplyr::inner_join(
      data_canonical_to_trait_species,
      by = dplyr::join_by(canonical_name == canonical_name),
      relationship = "many-to-many"
    )

  #--------------------------------------------------#
  # 4. Join mapping to trait observations -----
  #--------------------------------------------------#

  data_traits_classified <-
    data_trait_records |>
    dplyr::inner_join(
      data_community_to_trait_species,
      by = dplyr::join_by(taxon_name == trait_species),
      relationship = "many-to-many"
    )

  #--------------------------------------------------#
  # 5. Aggregate (median) and pivot wide -----
  #--------------------------------------------------#

  aggregation_function <-
    base::switch(
      aggregation_method,
      "median" = stats::median,
      "mean" = base::mean
    )

  data_community_taxon_traits <-
    data_traits_classified |>
    dplyr::group_by(.data$taxon_community, .data$trait_domain_name) |>
    dplyr::summarise(
      trait_value = aggregation_function(
        .data[["trait_value"]],
        na.rm = TRUE
      ),
      .groups = "drop"
    ) |>
    tidyr::pivot_wider(
      names_from = "trait_domain_name",
      values_from = "trait_value"
    ) |>
    dplyr::rename(taxon_name = "taxon_community")

  # Consistent column order: taxon_name first, then domains alphabetically
  trait_domain_columns <-
    base::setdiff(
      base::colnames(data_community_taxon_traits),
      "taxon_name"
    ) |>
    base::sort()

  data_community_taxon_traits <-
    data_community_taxon_traits |>
    dplyr::select(
      dplyr::all_of(base::c("taxon_name", trait_domain_columns))
    ) |>
    dplyr::arrange(.data$taxon_name)

  #--------------------------------------------------#
  # 6. Verbose reporting -----
  #--------------------------------------------------#

  if (base::isTRUE(verbose)) {
    matched_taxon_count <-
      base::nrow(data_community_taxon_traits)

    community_taxon_count <-
      base::nrow(data_community_taxonomy)

    cli::cli_inform(
      stringr::str_glue(
        "build_community_taxon_trait_table(): ",
        "{matched_taxon_count} of {community_taxon_count} ",
        "community taxa matched to traits."
      )
    )
  }

  return(data_community_taxon_traits)
}
