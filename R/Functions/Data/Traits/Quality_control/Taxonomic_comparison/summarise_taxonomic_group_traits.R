#' @title Summarise Traits Within a Taxonomic Group
#' @description
#' Resolves the taxonomic group containing `focal_taxon`, collects
#' records for taxa in that group and `trait_domain`, and returns
#' per-taxon summary statistics sorted by `median`.
#' @param data_trait_records
#' A data frame of raw trait observations. Must contain columns
#' `taxon_name` (character), `trait_domain_name` (character), and
#' `trait_value` (numeric).
#' @param data_taxon_classification
#' A data frame mapping taxon names to taxonomic ranks. Must contain
#' `sel_name` and the column named by `taxonomic_rank`.
#' @param focal_taxon
#' Character scalar. Name of the focal taxon to look up.
#' @param trait_domain
#' Character scalar. Trait domain to summarise (matched against
#' `trait_domain_name` in `data_trait_records`).
#' @param taxonomic_rank
#' Character scalar. Name of the taxonomic rank column in
#' `data_taxon_classification` to use for grouping (e.g. `"family"`,
#' `"genus"`, `"order"`). Defaults to `"family"`.
#' @param verbose
#' Logical. If `TRUE` (default), progress messages are printed to
#' the console via `cli`.
#' @return
#' A tibble with one row per taxon that has data for `trait_domain`
#' within the same `taxonomic_rank` group as `focal_taxon`. Columns:
#' `taxon_name`, `n_records`, `minimum`, `lower_quartile`, `median`,
#' `mean`, `upper_quartile`, and `maximum`. Rows are sorted ascending
#' by `median`. If the focal taxon or rank value cannot be resolved,
#' only records for `focal_taxon` are summarised.
#' @details
#' 1. The function looks up `focal_taxon` in
#'    `data_taxon_classification` to resolve `taxonomic_rank`.
#' 2. All taxa sharing that rank value are identified.
#' 3. `data_trait_records` is filtered to those taxa and
#'    `trait_domain`, then grouped by `taxon_name`.
#' 4. If the rank value cannot be resolved (taxon absent from
#'    classification or the rank column is `NA`), only the focal
#'    taxon's own records are summarised.
#' @seealso
#' [write_trait_quality_control_report()], [plot_focal_trait_distribution()]
#' @examples
#' \dontrun{
#' data_aux_classification <-
#'   readr::read_csv(
#'     here::here("Data/Input/aux_classification_table.csv"),
#'     show_col_types = FALSE
#'   )
#'
#' data_taxonomic_trait_summary <-
#'   summarise_taxonomic_group_traits(
#'     data_trait_records = data_traits_raw,
#'     data_taxon_classification = data_aux_classification,
#'     focal_taxon = "Anacyclus clavatus",
#'     trait_domain = "Leaf Area"
#'   )
#' }
#' @export
summarise_taxonomic_group_traits <- function(
    data_trait_records,
    data_taxon_classification,
    focal_taxon,
    trait_domain,
    taxonomic_rank = "family",
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_records),
    msg = "'data_trait_records' must be a data frame."
  )

  assertthat::assert_that(
    base::all(
      c("taxon_name", "trait_domain_name", "trait_value") %in%
        base::names(data_trait_records)
    ),
    msg = stringr::str_c(
      "'data_trait_records' must contain columns ",
      "'taxon_name', 'trait_domain_name', and 'trait_value'."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_taxon_classification),
    msg = "'data_taxon_classification' must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(focal_taxon),
    msg = "'focal_taxon' must be a character scalar."
  )

  assertthat::assert_that(
    base::length(focal_taxon) == 1L,
    msg = "'focal_taxon' must be a scalar (length 1)."
  )

  assertthat::assert_that(
    base::is.character(trait_domain),
    msg = "'trait_domain' must be a character scalar."
  )

  assertthat::assert_that(
    base::length(trait_domain) == 1L,
    msg = "'trait_domain' must be a scalar (length 1)."
  )

  assertthat::assert_that(
    base::is.character(taxonomic_rank),
    msg = "'taxonomic_rank' must be a character scalar."
  )

  assertthat::assert_that(
    base::length(taxonomic_rank) == 1L,
    msg = "'taxonomic_rank' must be a scalar (length 1)."
  )

  assertthat::assert_that(
    base::all(
      c("sel_name", taxonomic_rank) %in%
        base::names(data_taxon_classification)
    ),
    msg = stringr::str_glue(
      "'data_taxon_classification' must contain columns ",
      "'sel_name' and '{taxonomic_rank}'."
    )
  )

  assertthat::assert_that(
    base::is.logical(verbose),
    msg = "'verbose' must be a logical scalar."
  )

  taxonomic_group_values <-
    data_taxon_classification |>
    dplyr::filter(.data[["sel_name"]] == focal_taxon) |>
    dplyr::pull(.data[[taxonomic_rank]])

  if (
    base::length(taxonomic_group_values) == 0L ||
      base::all(base::is.na(taxonomic_group_values))
  ) {
    taxonomic_group <- NA_character_
    comparison_taxa <- focal_taxon
  } else {
    taxonomic_group <- taxonomic_group_values[[1L]]
    comparison_taxa <-
      data_taxon_classification |>
      dplyr::filter(.data[[taxonomic_rank]] == taxonomic_group) |>
      dplyr::pull(.data[["sel_name"]])
  }

  data_taxonomic_trait_records <-
    data_trait_records |>
    dplyr::filter(
      .data[["taxon_name"]] %in% comparison_taxa,
      .data[["trait_domain_name"]] == trait_domain
    )

  if (
    base::nrow(data_taxonomic_trait_records) == 0L
  ) {
    data_taxonomic_trait_summary <-
      tibble::tibble(
        taxon_name = base::character(0L),
        n_records = base::integer(0L),
        minimum = base::numeric(0L),
        lower_quartile = base::numeric(0L),
        median = base::numeric(0L),
        mean = base::numeric(0L),
        upper_quartile = base::numeric(0L),
        maximum = base::numeric(0L)
      )
  } else {
    data_taxonomic_trait_summary <-
      data_taxonomic_trait_records |>
      dplyr::group_by(.data[["taxon_name"]]) |>
      dplyr::summarise(
        n_records = dplyr::n(),
        minimum = base::min(.data[["trait_value"]], na.rm = TRUE),
        lower_quartile = stats::quantile(
          .data[["trait_value"]],
          probs = 0.25,
          na.rm = TRUE,
          names = FALSE
        ),
        median = stats::median(.data[["trait_value"]], na.rm = TRUE),
        mean = base::mean(.data[["trait_value"]], na.rm = TRUE),
        upper_quartile = stats::quantile(
          .data[["trait_value"]],
          probs = 0.75,
          na.rm = TRUE,
          names = FALSE
        ),
        maximum = base::max(.data[["trait_value"]], na.rm = TRUE),
        .groups = "drop"
      ) |>
      dplyr::arrange(.data[["median"]])
  }

  if (
    base::isTRUE(verbose)
  ) {
    cli::cli_inform(
      stringr::str_c(
        taxonomic_rank, " comparison: ",
        if (
          !base::is.na(taxonomic_group)
        ) {
          taxonomic_group
        } else {
          "(unknown)"
        },
        " x ", trait_domain,
        " \u2014 ", base::nrow(data_taxonomic_trait_summary),
        " taxa with data."
      )
    )
  }

  return(data_taxonomic_trait_summary)
}
