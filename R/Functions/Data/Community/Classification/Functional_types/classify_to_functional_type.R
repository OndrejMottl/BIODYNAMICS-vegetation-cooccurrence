#' @title Classify Community Data to Functional Types
#' @description
#' Classifies taxa in a long-format community data frame to
#' functional-type (FT) labels using a pre-computed FT
#' classification table. Aggregates pollen proportions by all
#' non-`taxon`/`value` identifier columns plus functional type.
#' Produces the same
#' output column structure as `classify_taxonomic_resolution()`
#' so it can be used as a drop-in replacement downstream.
#' @param data_source
#' A data frame containing community data with columns
#' `taxon`, `dataset_name`, `age`, and `value`. Other identifier
#' columns such as `sample_name` are preserved.
#' @param data_functional_type_classification
#' A data frame mapping taxa to functional types. Must contain
#' columns `taxon_name` (character) and `functional_type`
#' (integer). Typically produced by `assign_functional_type_clusters()`
#' and loaded via `load_latest_functional_type_classification()`.
#' @param verbose
#' Logical. Reserved for informational progress messages. The warning
#' emitted when unmatched taxa are dropped is always shown because it
#' reports data loss.
#' @return
#' A data frame with the same column names as `data_source`. The
#' `taxon` column is replaced by functional-type labels of the
#' form `"FT_1"`, `"FT_2"`, etc. `value` is aggregated
#' (summed) by all original identifier columns and `taxon`. All
#' identifier combinations present after FT classification are
#' preserved (true negatives kept via a cross-reference join).
#' Taxa not found in `data_functional_type_classification` are dropped with
#' a `cli::cli_warn()` message.
#' @details
#' Steps performed:
#' \enumerate{
#'   \item Validate arguments.
#'   \item Left-join `data_source` to
#'     `data_functional_type_classification` on their taxon names.
#'   \item Drop unmatched taxa (NA functional type) with a
#'     warning.
#'   \item Create `taxon` labels `"FT_{functional_type}"`.
#'   \item Aggregate `value` by original identifier columns and
#'     `taxon`.
#'   \item Full-join back to an identifier/taxon cross-reference
#'     to preserve true negatives.
#' }
#' @seealso [classify_taxonomic_resolution()],
#'   [load_latest_functional_type_classification()],
#'   [assign_functional_type_clusters()]
#' @export
classify_to_functional_type <- function(
    data_source,
    data_functional_type_classification,
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data_source),
    msg = "'data_source' must be a data frame."
  )

  assertthat::assert_that(
    base::all(
      c("taxon", "dataset_name", "age", "value") %in%
        base::colnames(data_source)
    ),
    msg = stringr::str_c(
      "'data_source' must contain columns: taxon, dataset_name, ",
      "age, and value."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_functional_type_classification),
    msg = "'data_functional_type_classification' must be a data frame."
  )

  assertthat::assert_that(
    "taxon_name" %in%
      base::colnames(data_functional_type_classification),
    msg = stringr::str_c(
      "'data_functional_type_classification' must contain column ",
      "'taxon_name'."
    )
  )

  assertthat::assert_that(
    "functional_type" %in%
      base::colnames(data_functional_type_classification),
    msg = stringr::str_c(
      "'data_functional_type_classification' must contain column ",
      "'functional_type'."
    )
  )

  assertthat::assert_that(
    base::is.logical(verbose) &&
      base::length(verbose) == 1L,
    msg = "'verbose' must be a single logical value."
  )

  # Join FT classification to community data on taxon name.
  data_community_joined <-
    data_source |>
    dplyr::left_join(
      data_functional_type_classification |>
        dplyr::select(taxon_name, functional_type),
      by = dplyr::join_by("taxon" == "taxon_name")
    )

  # Warn and drop taxa not present in the FT classification table.
  vec_unmatched_taxa <-
    data_community_joined |>
    dplyr::filter(base::is.na(functional_type)) |>
    dplyr::distinct(taxon) |>
    dplyr::pull(taxon)

  n_unmatched_taxa <-
    base::length(vec_unmatched_taxa)

  if (
    n_unmatched_taxa > 0
  ) {
    cli::cli_warn(
      c(
        "!" = stringr::str_c(
          n_unmatched_taxa,
          " taxon/taxa not found in ",
          "'data_functional_type_classification'; unmatched rows were dropped."
        ),
        "i" = stringr::str_c(
          "Check that the functional-type classification was built from ",
          "the same taxa present in the community data."
        )
      )
    )
  }

  data_community_with_functional_types <-
    data_community_joined |>
    dplyr::filter(!base::is.na(functional_type)) |>
    dplyr::mutate(
      taxon = stringr::str_glue("FT_{functional_type}")
    ) |>
    dplyr::select(-functional_type)

  # If all taxa were unmatched, return an empty data frame with the
  # correct column names and column types.
  if (
    base::nrow(data_community_with_functional_types) == 0L
  ) {
    res_community_classified <-
      data_source[0L, base::colnames(data_source)]

    return(res_community_classified)
  }

  vec_identifier_columns <-
    base::setdiff(
      base::colnames(data_source),
      c("taxon", "value")
    )

  # Build a cross-reference of all identifier/taxon combinations
  # present after classification. This is used in the full-join below
  # to preserve true-negative cells.
  data_dataset_age_cross_reference <-
    data_community_with_functional_types |>
    dplyr::distinct(
      dplyr::across(
        dplyr::all_of(
          c(vec_identifier_columns, "taxon")
        )
      )
    )

  # Aggregate pollen proportions by identifier columns and FT taxon,
  # then restore true-negative cells via a full join.
  res_community_classified <-
    data_community_with_functional_types |>
    tidyr::drop_na(value) |>
    dplyr::group_by(
      dplyr::across(
        dplyr::all_of(
          c(vec_identifier_columns, "taxon")
        )
      )
    ) |>
    dplyr::summarise(
      .groups = "drop",
      value = base::sum(value, na.rm = TRUE)
    ) |>
    dplyr::full_join(
      data_dataset_age_cross_reference,
      by = c(vec_identifier_columns, "taxon")
    ) |>
    dplyr::arrange(
      dplyr::across(
        dplyr::all_of(
          c(vec_identifier_columns, "taxon")
        )
      )
    ) |>
    dplyr::select(
      base::colnames(data_source)
    )

  return(res_community_classified)
}
