#' @title Evaluate a Functional-Type Classification Change
#' @description
#' Compares two functional-type classifications by taxon, raw cluster
#' labels, label-invariant co-clustering relationships, and silhouette
#' widths. The partition comparison is invariant to arbitrary integer
#' relabelling of otherwise identical clusters.
#' @param data_reference
#' A data frame with unique `taxon_name` values and columns
#' `functional_type` and `silhouette_width`.
#' @param data_candidate
#' A data frame with the same required columns as `data_reference`.
#' @return
#' A named list with `data_summary`, a one-row tibble of comparison
#' counts, and `data_taxon_comparison`, a taxon-level full join of both
#' classifications.
#' @details
#' Label-invariant partition differences are counted from cluster-size
#' and contingency-table combinations. This avoids constructing a
#' quadratic taxon-by-taxon matrix while counting pairs that are in the
#' same cluster in exactly one classification.
#' @examples
#' data_reference <- tibble::tibble(
#'   taxon_name = c("a", "b", "c"),
#'   functional_type = c(1L, 1L, 2L),
#'   silhouette_width = c(0.4, 0.5, 0.6)
#' )
#' data_candidate <- tibble::tibble(
#'   taxon_name = c("a", "b", "c"),
#'   functional_type = c(2L, 2L, 1L),
#'   silhouette_width = c(0.4, 0.5, 0.6)
#' )
#' evaluate_functional_type_classification_change(
#'   data_reference,
#'   data_candidate
#' )
#' @export
evaluate_functional_type_classification_change <- function(
    data_reference,
    data_candidate) {
  vec_required_columns <-
    base::c(
      "taxon_name",
      "functional_type",
      "silhouette_width"
    )

  assertthat::assert_that(
    base::is.data.frame(data_reference),
    msg = "`data_reference` must be a data frame."
  )
  assertthat::assert_that(
    base::is.data.frame(data_candidate),
    msg = "`data_candidate` must be a data frame."
  )
  assertthat::assert_that(
    base::all(
      vec_required_columns %in% base::colnames(data_reference)
    ),
    msg = "`data_reference` is missing required columns."
  )
  assertthat::assert_that(
    base::all(
      vec_required_columns %in% base::colnames(data_candidate)
    ),
    msg = "`data_candidate` is missing required columns."
  )
  assertthat::assert_that(
    !base::any(base::is.na(data_reference[["taxon_name"]])) &&
      !base::any(base::duplicated(data_reference[["taxon_name"]])),
    msg = "`data_reference$taxon_name` must contain unique values."
  )
  assertthat::assert_that(
    !base::any(base::is.na(data_candidate[["taxon_name"]])) &&
      !base::any(base::duplicated(data_candidate[["taxon_name"]])),
    msg = "`data_candidate$taxon_name` must contain unique values."
  )
  assertthat::assert_that(
    !base::any(base::is.na(data_reference[["functional_type"]])) &&
      !base::any(base::is.na(data_candidate[["functional_type"]])),
    msg = "`functional_type` values must not be missing."
  )
  assertthat::assert_that(
    base::is.numeric(data_reference[["silhouette_width"]]) &&
      base::is.numeric(data_candidate[["silhouette_width"]]),
    msg = "`silhouette_width` values must be numeric."
  )

  data_reference_selected <-
    data_reference |>
    dplyr::select(dplyr::all_of(vec_required_columns)) |>
    dplyr::rename(
      functional_type_reference = "functional_type",
      silhouette_width_reference = "silhouette_width"
    )

  data_candidate_selected <-
    data_candidate |>
    dplyr::select(dplyr::all_of(vec_required_columns)) |>
    dplyr::rename(
      functional_type_candidate = "functional_type",
      silhouette_width_candidate = "silhouette_width"
    )

  data_taxon_comparison <-
    dplyr::full_join(
      data_reference_selected,
      data_candidate_selected,
      by = dplyr::join_by(taxon_name)
    ) |>
    dplyr::mutate(
      taxon_status = dplyr::case_when(
        base::is.na(.data[["functional_type_reference"]]) ~ "added",
        base::is.na(.data[["functional_type_candidate"]]) ~ "removed",
        TRUE ~ "shared"
      ),
      raw_assignment_changed = dplyr::if_else(
        .data[["taxon_status"]] == "shared",
        .data[["functional_type_reference"]] !=
          .data[["functional_type_candidate"]],
        NA
      ),
      silhouette_delta = .data[["silhouette_width_candidate"]] -
        .data[["silhouette_width_reference"]]
    ) |>
    dplyr::arrange(.data[["taxon_name"]])

  data_shared <-
    data_taxon_comparison |>
    dplyr::filter(.data[["taxon_status"]] == "shared")

  reference_same_pair_count <-
    data_shared |>
    dplyr::count(.data[["functional_type_reference"]]) |>
    dplyr::summarise(
      pair_count = base::sum(.data[["n"]] * (.data[["n"]] - 1) / 2)
    ) |>
    dplyr::pull("pair_count")

  candidate_same_pair_count <-
    data_shared |>
    dplyr::count(.data[["functional_type_candidate"]]) |>
    dplyr::summarise(
      pair_count = base::sum(.data[["n"]] * (.data[["n"]] - 1) / 2)
    ) |>
    dplyr::pull("pair_count")

  shared_same_pair_count <-
    data_shared |>
    dplyr::count(
      .data[["functional_type_reference"]],
      .data[["functional_type_candidate"]]
    ) |>
    dplyr::summarise(
      pair_count = base::sum(.data[["n"]] * (.data[["n"]] - 1) / 2)
    ) |>
    dplyr::pull("pair_count")

  partition_pair_difference_count <-
    reference_same_pair_count + candidate_same_pair_count -
    2 * shared_same_pair_count

  vec_silhouette_delta <-
    data_shared |>
    dplyr::pull("silhouette_delta")

  maximum_absolute_silhouette_delta <-
    if (
      base::length(vec_silhouette_delta) == 0L
    ) {
      NA_real_
    } else {
      base::max(base::abs(vec_silhouette_delta), na.rm = TRUE)
    }

  data_summary <-
    tibble::tibble(
      reference_taxon_count = base::nrow(data_reference_selected),
      candidate_taxon_count = base::nrow(data_candidate_selected),
      shared_taxon_count = base::nrow(data_shared),
      added_taxon_count = base::sum(
        data_taxon_comparison[["taxon_status"]] == "added"
      ),
      removed_taxon_count = base::sum(
        data_taxon_comparison[["taxon_status"]] == "removed"
      ),
      reference_group_count = dplyr::n_distinct(
        data_reference_selected[["functional_type_reference"]]
      ),
      candidate_group_count = dplyr::n_distinct(
        data_candidate_selected[["functional_type_candidate"]]
      ),
      raw_assignment_difference_count = base::sum(
        data_shared[["raw_assignment_changed"]]
      ),
      partition_pair_difference_count = partition_pair_difference_count,
      partition_identical = partition_pair_difference_count == 0,
      silhouette_difference_count = base::sum(
        vec_silhouette_delta != 0,
        na.rm = TRUE
      ),
      maximum_absolute_silhouette_delta =
        maximum_absolute_silhouette_delta
    )

  res <-
    base::list(
      data_summary = data_summary,
      data_taxon_comparison = data_taxon_comparison
    )

  return(res)
}
