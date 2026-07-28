#' @title Prepare Community Proportions
#' @description
#' Prepares community pollen-count data as proportions, normalising
#' each sample by its total pollen count.
#' @param data_community
#' A data frame with columns `dataset_name`, `sample_name`, `taxon`,
#' `age`, and `pollen_count`. Must contain a `pollen_count` column with
#' raw pollen counts.
#' @return
#' A data frame with the same structure as the input, but with
#' `pollen_count` replaced by `value` (pollen counts divided by
#' sample-level total). The `pollen_count` and `pollen_sum` columns are
#' dropped.
#' @details
#' Summarises per-sample totals using
#' [summarise_pollen_counts_by_sample()] and computes proportions with
#' [compute_pollen_proportions()]. The result is suitable for passing to
#' [interpolate_community_data()].
#' @seealso [interpolate_community_data()], [compute_pollen_proportions()]
#' @export
prepare_community_proportions <- function(data_community = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_community),
    msg = "data_community must be a data frame."
  )

  assertthat::assert_that(
    "pollen_count" %in% base::colnames(data_community),
    msg = "data_community must contain a 'pollen_count' column."
  )

  data_pollen_sums <-
    summarise_pollen_counts_by_sample(
      data_community = data_community
    )

  res_community_proportions <-
    compute_pollen_proportions(
      data_community = data_community,
      data_pollen_sums = data_pollen_sums
    )

  return(res_community_proportions)
}
