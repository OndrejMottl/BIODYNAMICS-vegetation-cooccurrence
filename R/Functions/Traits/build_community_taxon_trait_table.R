#' @title Build Community-Taxon-Level Trait Table
#' @description
#' Builds a wide-format trait table where rows correspond to
#' community taxon names (as they appear in pollen/community
#' data) rather than species names. For each trait observation
#' the function looks up the full taxonomic lineage of the
#' source species and maps it to every community taxon that
#' appears anywhere in that lineage (kingdom → species). Trait
#' values are then aggregated (median) per
#' `(community_taxon, trait_domain)` and pivoted to a wide
#' matrix ready for `cluster_functional_types()`.
#'
#' This correctly handles pollen taxa resolved only to family
#' or higher rank: "Asteraceae" in the community data will
#' collect the median across all trait species whose lineage
#' contains Asteraceae.
#' @param data_traits
#' A data frame of trait observations in long format.
#' Must contain columns `taxon_name` (character; the original
#' trait species name, matching `sel_name` in
#' `data_classification_table`), `trait_domain_name`
#' (character; trait domain label), and `trait_value`
#' (numeric; observed value).
#' @param data_classification_table
#' A wide-format taxonomic classification table with one row
#' per `sel_name` and columns `sel_name`, `kingdom`,
#' `phylum`, `class`, `order`, `family`, `genus`, `species`.
#' Typically produced by `make_classification_table()` and
#' combined with manual overrides via
#' `combine_classification_tables()`. `sel_name` must match
#' the `taxon_name` values in `data_traits` (after trait
#' QC and correction).
#' @param vec_community_taxa
#' A character vector of taxon names present in the community
#' (pollen) data for this project / spatial unit. Only
#' taxonomy values that appear in this vector are used as
#' aggregation targets. Must be non-empty.
#' @param aggregation_fn
#' A single character string specifying how trait values are
#' aggregated per `(community_taxon, trait_domain_name)` pair.
#' Must be one of `"median"` (default) or `"mean"`.
#' @param verbose
#' A single logical. If `TRUE` (default), progress messages
#' reporting coverage statistics are printed via `cli`.
#' @return
#' A tibble with one row per community taxon that could be
#' matched to at least one trait observation. Contains a
#' `taxon_name` column (the community taxon name) plus one
#' numeric column per distinct `trait_domain_name`. Taxa
#' from `vec_community_taxa` with no trait match are silently
#' absent (not filled with `NA` rows). The column order is
#' `taxon_name` followed by trait domain columns in
#' alphabetical order.
#' @details
#' **Algorithm**:
#' \enumerate{
#'   \item Pivot the seven rank columns of
#'     `data_classification_table` to long format.
#'   \item Retain only rows where the rank value appears in
#'     `vec_community_taxa`.
#'   \item For each trait species (`sel_name`), this produces
#'     one or more rows mapping it to community taxon(a) at
#'     various ranks (e.g. genus "Abies" AND family
#'     "Pinaceae", if both exist in the community data).
#'     Unlike `resolve_classification_to_finest_rank()`,
#'     **all** matching ranks are kept so that coarser
#'     community taxa (family, order) accumulate contributions
#'     from all their member species.
#'   \item Inner-join this mapping to `data_traits` on
#'     `taxon_name == sel_name`, producing one row per
#'     `(community_taxon, trait_domain_name, observation)`.
#'   \item Aggregate: median of `trait_value` per
#'     `(community_taxon, trait_domain_name)`.
#'   \item Pivot wide: `taxon_name` (community taxon) ×
#'     trait domain columns.
#' }
#' @seealso [make_classification_table()],
#'   [combine_classification_tables()],
#'   [cluster_functional_types()],
#'   [classify_to_functional_type()]
#' @export
build_community_taxon_trait_table <- function(
    data_traits,
    data_classification_table,
    vec_community_taxa,
    aggregation_fn = "median",
    verbose = TRUE) {

  #--------------------------------------------------#
  # 1. Input validation -----
  #--------------------------------------------------#

  assertthat::assert_that(
    base::is.data.frame(data_traits),
    msg = "`data_traits` must be a data frame."
  )

  assertthat::assert_that(
    base::all(
      base::c("taxon_name", "trait_domain_name", "trait_value") %in%
        base::colnames(data_traits)
    ),
    msg = stringr::str_glue(
      "`data_traits` must contain columns: ",
      "'taxon_name', 'trait_domain_name', 'trait_value'."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_classification_table),
    msg = "`data_classification_table` must be a data frame."
  )

  vec_required_cols <-
    base::c(
      "sel_name", "kingdom", "phylum", "class", "order",
      "family", "genus", "species"
    )

  assertthat::assert_that(
    base::all(
      vec_required_cols %in% base::colnames(data_classification_table)
    ),
    msg = stringr::str_glue(
      "`data_classification_table` must contain columns: ",
      "{stringr::str_c(vec_required_cols, collapse = ', ')}."
    )
  )

  assertthat::assert_that(
    base::is.character(vec_community_taxa) &&
      base::length(vec_community_taxa) > 0L,
    msg = "`vec_community_taxa` must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.logical(verbose) && base::length(verbose) == 1L,
    msg = "`verbose` must be a single logical."
  )

  assertthat::assert_that(
    base::is.character(aggregation_fn) &&
      base::length(aggregation_fn) == 1L &&
      aggregation_fn %in% base::c("median", "mean"),
    msg = "`aggregation_fn` must be one of 'median' or 'mean'."
  )

  #--------------------------------------------------#
  # 2. Build taxonomy → community-taxon mapping -----
  #--------------------------------------------------#

  # Pivot the seven rank columns long, keep only rows where the rank value
  # matches a community taxon (the allow-list). Unlike
  # resolve_classification_to_finest_rank(), ALL matching ranks are kept so
  # that coarser pollen taxa (family, order) collect contributions from every
  # member species in the traits table.
  vec_ranks <-
    base::c("kingdom", "phylum", "class", "order", "family", "genus", "species")

  data_classification_to_community <-
    data_classification_table |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(vec_ranks),
      names_to = "rank",
      values_to = "taxon_community"
    ) |>
    dplyr::filter(!base::is.na(.data$taxon_community)) |>
    dplyr::filter(.data$taxon_community %in% vec_community_taxa) |>
    dplyr::select(dplyr::all_of(base::c("sel_name", "taxon_community")))

  #--------------------------------------------------#
  # 3. Join mapping to trait observations -----
  #--------------------------------------------------#

  data_traits_classified <-
    data_traits |>
    dplyr::inner_join(
      data_classification_to_community,
      by = dplyr::join_by(taxon_name == sel_name),
      multiple = "all",
      relationship = "many-to-many"
    )

  #--------------------------------------------------#
  # 4. Aggregate (median) and pivot wide -----
  #--------------------------------------------------#

  fn_aggregate <-
    base::switch(
      aggregation_fn,
      "median" = function(x) stats::median(x, na.rm = TRUE),
      "mean"   = function(x) base::mean(x, na.rm = TRUE)
    )

  data_res <-
    data_traits_classified |>
    dplyr::group_by(.data$taxon_community, .data$trait_domain_name) |>
    dplyr::summarise(
      trait_value = fn_aggregate(.data$trait_value),
      .groups = "drop"
    ) |>
    tidyr::pivot_wider(
      names_from = "trait_domain_name",
      values_from = "trait_value"
    ) |>
    dplyr::rename(taxon_name = "taxon_community")

  # Consistent column order: taxon_name first, then domains alphabetically
  vec_domain_cols <-
    base::setdiff(base::colnames(data_res), "taxon_name") |>
    base::sort()

  data_res <-
    data_res |>
    dplyr::select(dplyr::all_of(base::c("taxon_name", vec_domain_cols))) |>
    dplyr::arrange(.data$taxon_name)

  #--------------------------------------------------#
  # 5. Verbose reporting -----
  #--------------------------------------------------#

  if (base::isTRUE(verbose)) {
    n_matched <-
      base::nrow(data_res)

    n_total <-
      base::length(vec_community_taxa)

    cli::cli_inform(
      stringr::str_glue(
        "build_community_taxon_trait_table(): ",
        "{n_matched} of {n_total} community taxa matched to traits."
      )
    )
  }

  return(data_res)
}
