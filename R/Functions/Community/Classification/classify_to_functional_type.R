#' @title Classify Community Data to Functional Types
#' @description
#' Classifies taxa in a long-format community data frame to
#' functional-type (FT) labels using a pre-computed FT
#' classification table. Aggregates pollen proportions by all
#' non-`taxon`/`value` identifier columns plus functional type.
#' Produces the same
#' output column structure as `classify_taxonomic_resolution()`
#' so it can be used as a drop-in replacement downstream.
#' @param data
#' A data frame containing community data with columns
#' `taxon`, `dataset_name`, `age`, and `value`. Other identifier
#' columns such as `sample_name` are preserved.
#' @param data_ft_classification
#' A data frame mapping taxa to functional types. Must contain
#' columns `taxon_name` (character) and `functional_type`
#' (integer). Typically produced by `cluster_functional_types()`
#' and loaded via `get_functional_type_classification()`.
#' @param verbose
#' Logical. If `TRUE` (default), informational progress messages
#' are printed to the console via `cli`. Note: the warning issued
#' when taxa are absent from `data_ft_classification` is always
#' emitted regardless of this flag.
#' @return
#' A data frame with the same column names as `data`. The
#' `taxon` column is replaced by functional-type labels of the
#' form `"FT_1"`, `"FT_2"`, etc. `value` is aggregated
#' (summed) by all original identifier columns and `taxon`. All
#' identifier combinations present after FT classification are
#' preserved (true negatives kept via a cross-reference join).
#' Taxa not found in `data_ft_classification` are dropped with
#' a `cli::cli_warn()` message.
#' @details
#' Steps performed:
#' \enumerate{
#'   \item Validate arguments.
#'   \item Left-join `data` to `data_ft_classification` on
#'     `data$taxon == data_ft_classification$taxon_name`.
#'   \item Drop unmatched taxa (NA functional type) with a
#'     warning.
#'   \item Create `taxon` labels `"FT_{functional_type}"`.
#'   \item Aggregate `value` by original identifier columns and
#'     `taxon`.
#'   \item Full-join back to an identifier/taxon cross-reference
#'     to preserve true negatives.
#' }
#' @seealso [classify_taxonomic_resolution()],
#'   [get_functional_type_classification()],
#'   [cluster_functional_types()]
#' @export
classify_to_functional_type <- function(
    data,
    data_ft_classification,
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data),
    msg = "'data' must be a data frame."
  )

  assertthat::assert_that(
    base::all(
      c("taxon", "dataset_name", "age", "value") %in%
        base::colnames(data)
    ),
    msg = "'data' must contain columns: taxon, dataset_name, age, and value."
  )

  assertthat::assert_that(
    base::is.data.frame(data_ft_classification),
    msg = "'data_ft_classification' must be a data frame."
  )

  assertthat::assert_that(
    "taxon_name" %in% base::colnames(data_ft_classification),
    msg = "'data_ft_classification' must contain column 'taxon_name'."
  )

  assertthat::assert_that(
    "functional_type" %in% base::colnames(data_ft_classification),
    msg = "'data_ft_classification' must contain column 'functional_type'."
  )

  assertthat::assert_that(
    base::is.logical(verbose) && base::length(verbose) == 1L,
    msg = "'verbose' must be a single logical value."
  )

  # Join FT classification to community data on taxon name.
  data_joined <-
    data |>
    dplyr::left_join(
      data_ft_classification |>
        dplyr::select(taxon_name, functional_type),
      by = dplyr::join_by("taxon" == "taxon_name")
    )

  # Warn and drop taxa not present in the FT classification table.
  vec_unmatched <-
    data_joined |>
    dplyr::filter(base::is.na(functional_type)) |>
    dplyr::distinct(taxon) |>
    dplyr::pull(taxon)

  n_unmatched <-
    base::length(vec_unmatched)

  if (
    n_unmatched > 0
  ) {
    cli::cli_warn(
      c(
        "!" = "{n_unmatched} taxon/taxa not found in 'data_ft_classification' and {?was/were} dropped.",
        "i" = "Check that the FT classification was built from the same taxa present in the community data."
      )
    )
  }

  data_classified <-
    data_joined |>
    dplyr::filter(!base::is.na(functional_type)) |>
    dplyr::mutate(
      taxon = stringr::str_glue("FT_{functional_type}")
    ) |>
    dplyr::select(-functional_type)

  # If all taxa were unmatched, return an empty data frame with the
  # correct column names and column types.
  if (
    base::nrow(data_classified) == 0L
  ) {
    res <-
      data[0L, base::colnames(data)]

    return(res)
  }

  vec_identifier_cols <-
    base::setdiff(
      base::colnames(data),
      c("taxon", "value")
    )

  # Build a cross-reference of all identifier/taxon combinations
  # present after classification. This is used in the full-join below
  # to preserve true-negative cells.
  data_dataset_age_cross_ref <-
    data_classified |>
    dplyr::distinct(
      dplyr::across(
        dplyr::all_of(
          c(vec_identifier_cols, "taxon")
        )
      )
    )

  # Aggregate pollen proportions by identifier columns and FT taxon,
  # then restore true-negative cells via a full join.
  res <-
    data_classified |>
    tidyr::drop_na(value) |>
    dplyr::group_by(
      dplyr::across(
        dplyr::all_of(
          c(vec_identifier_cols, "taxon")
        )
      )
    ) |>
    dplyr::summarise(
      .groups = "drop",
      value = base::sum(value, na.rm = TRUE)
    ) |>
    dplyr::full_join(
      data_dataset_age_cross_ref,
      by = c(vec_identifier_cols, "taxon")
    ) |>
    dplyr::arrange(
      dplyr::across(
        dplyr::all_of(
          c(vec_identifier_cols, "taxon")
        )
      )
    ) |>
    dplyr::select(
      base::colnames(data)
    )

  return(res)
}
