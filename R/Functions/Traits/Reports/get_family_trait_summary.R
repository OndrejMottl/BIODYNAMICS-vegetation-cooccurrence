#' @title Get Family-Level Trait Summary for a Selected Taxon
#' @description
#' Looks up the taxonomic family of `sel_taxon` in
#' `data_classification`, collects all same-family taxa from
#' `data_traits_raw` for the chosen trait domain, and returns a
#' summary tibble with per-taxon statistics (`n`, `min`, `q25`,
#' `median`, `mean`, `q75`, `max`) sorted by `median`.
#' @param data_traits_raw
#' A data frame of raw trait observations. Must contain columns
#' `taxon_name` (character), `trait_domain_name` (character), and
#' `trait_value` (numeric).
#' @param data_classification
#' A data frame mapping taxon names to taxonomic ranks. Must contain
#' columns `sel_name` (character) and `family` (character).
#' @param sel_taxon
#' Character scalar. Name of the focal taxon to look up.
#' @param sel_domain
#' Character scalar. Trait domain to summarise (matched against
#' `trait_domain_name` in `data_traits_raw`).
#' @param sel_rank
#' Character scalar. Name of the taxonomic rank column in
#' `data_classification` to use for grouping (e.g. `"family"`,
#' `"genus"`, `"order"`). Defaults to `"family"`.
#' @param verbose
#' Logical. If `TRUE` (default), progress messages are printed to
#' the console via `cli`.
#' @return
#' A tibble with one row per taxon that has data for `sel_domain`
#' within the same `sel_rank` group as `sel_taxon`. Columns:
#' `taxon_name`, `n` (integer observation count), `min`, `q25`,
#' `median`, `mean`, `q75`, `max` (all numeric). Rows are sorted
#' ascending by `median`. If `sel_taxon` is not found in
#' `data_classification`, only observations for `sel_taxon` itself
#' are summarised.
#' @details
#' 1. The function joins `sel_taxon` against `data_classification`
#'    to resolve the value in the `sel_rank` column.
#' 2. All taxa sharing that same `sel_rank` value are identified
#'    from `data_classification`.
#' 3. `data_traits_raw` is filtered to those taxa and `sel_domain`,
#'    then grouped by `taxon_name` to produce summary statistics.
#' 4. If the rank value cannot be resolved (taxon absent from
#'    `data_classification` or the `sel_rank` column is `NA`),
#'    only `sel_taxon`'s own observations are summarised.
#' @seealso
#' [generate_trait_qc_report()], [plot_trait_group_distribution()]
#' @examples
#' \dontrun{
#' data_aux_classification <-
#'   readr::read_csv(
#'     here::here("Data/Input/aux_classification_table.csv"),
#'     show_col_types = FALSE
#'   )
#'
#' data_family_comparison <-
#'   get_family_trait_summary(
#'     data_traits_raw = data_traits_raw,
#'     data_classification = data_aux_classification,
#'     sel_taxon = "Anacyclus clavatus",
#'     sel_domain = "Leaf Area"
#'   )
#' }
#' @export
get_family_trait_summary <- function(
    data_traits_raw,
    data_classification,
    sel_taxon,
    sel_domain,
    sel_rank = "family",
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data_traits_raw),
    msg = "'data_traits_raw' must be a data frame."
  )

  assertthat::assert_that(
    base::all(
      c("taxon_name", "trait_domain_name", "trait_value") %in%
        base::names(data_traits_raw)
    ),
    msg = base::paste0(
      "'data_traits_raw' must contain columns ",
      "'taxon_name', 'trait_domain_name', and 'trait_value'."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_classification),
    msg = "'data_classification' must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(sel_taxon),
    msg = "'sel_taxon' must be a character scalar."
  )

  assertthat::assert_that(
    base::length(sel_taxon) == 1L,
    msg = "'sel_taxon' must be a scalar (length 1)."
  )

  assertthat::assert_that(
    base::is.character(sel_domain),
    msg = "'sel_domain' must be a character scalar."
  )

  assertthat::assert_that(
    base::length(sel_domain) == 1L,
    msg = "'sel_domain' must be a scalar (length 1)."
  )

  assertthat::assert_that(
    base::is.character(sel_rank),
    msg = "'sel_rank' must be a character scalar."
  )

  assertthat::assert_that(
    base::length(sel_rank) == 1L,
    msg = "'sel_rank' must be a scalar (length 1)."
  )

  assertthat::assert_that(
    base::all(
      c("sel_name", sel_rank) %in% base::names(data_classification)
    ),
    msg = base::paste0(
      "'data_classification' must contain columns ",
      "'sel_name' and '", sel_rank, "'."
    )
  )

  assertthat::assert_that(
    base::is.logical(verbose),
    msg = "'verbose' must be a logical scalar."
  )

  # Resolve rank value of sel_taxon
  vec_rank_value <-
    data_classification |>
    dplyr::filter(.data[["sel_name"]] == sel_taxon) |>
    dplyr::pull(.data[[sel_rank]])

  # Identify comparison taxa
  if (
    base::length(vec_rank_value) == 0L ||
      base::all(base::is.na(vec_rank_value))
  ) {
    sel_rank_value <- NA_character_
    vec_comparison_taxa <- sel_taxon
  } else {
    sel_rank_value <- vec_rank_value[[1L]]
    vec_comparison_taxa <-
      data_classification |>
      dplyr::filter(.data[[sel_rank]] == sel_rank_value) |>
      dplyr::pull(.data[["sel_name"]])
  }

  # Summarise per-taxon statistics
  data_filtered <-
    data_traits_raw |>
    dplyr::filter(
      .data[["taxon_name"]] %in% vec_comparison_taxa,
      .data[["trait_domain_name"]] == sel_domain
    )

  if (
    base::nrow(data_filtered) == 0L
  ) {
    res <-
      tibble::tibble(
        taxon_name = base::character(0L),
        n = base::integer(0L),
        min = base::numeric(0L),
        q25 = base::numeric(0L),
        median = base::numeric(0L),
        mean = base::numeric(0L),
        q75 = base::numeric(0L),
        max = base::numeric(0L)
      )
  } else {
    res <-
      data_filtered |>
      dplyr::group_by(.data[["taxon_name"]]) |>
      dplyr::summarise(
        n = dplyr::n(),
        min = base::min(.data[["trait_value"]], na.rm = TRUE),
        q25 = stats::quantile(
          .data[["trait_value"]],
          probs = 0.25,
          na.rm = TRUE,
          names = FALSE
        ),
        median = stats::median(.data[["trait_value"]], na.rm = TRUE),
        mean = base::mean(.data[["trait_value"]], na.rm = TRUE),
        q75 = stats::quantile(
          .data[["trait_value"]],
          probs = 0.75,
          na.rm = TRUE,
          names = FALSE
        ),
        max = base::max(.data[["trait_value"]], na.rm = TRUE),
        .groups = "drop"
      ) |>
      dplyr::arrange(.data[["median"]])
  }

  if (
    base::isTRUE(verbose)
  ) {
    cli::cli_inform(
      base::paste0(
        sel_rank, " comparison: ",
        if (
          !base::is.na(sel_rank_value)
        ) {
          sel_rank_value
        } else {
          "(unknown)"
        },
        " x ", sel_domain,
        " \u2014 ", base::nrow(res), " taxa with data."
      )
    )
  }

  return(res)
}
