#' @title Make Community Proportions
#' @description
#' Transforms community pollen count data into proportions, normalising
#' each sample by its total pollen count.
#' @param data
#' A data frame with columns `dataset_name`, `sample_name`, `taxon`,
#' `age`, and `pollen_count`. Must contain a `pollen_count` column with
#' raw pollen counts.
#' @return
#' A data frame with the same structure as the input, but with
#' `pollen_count` replaced by `pollen_prop` (pollen counts divided by
#' sample-level total). The `pollen_count` and `pollen_sum` columns are
#' dropped.
#' @details
#' Computes per-sample totals using `get_pollen_sum()` and normalises
#' counts via `transform_to_proportions()`. The result is suitable for
#' passing to `interpolate_community_data()`.
#' @seealso [interpolate_community_data()], [transform_to_proportions()]
#' @export
make_community_proportions <- function(data = NULL) {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    "pollen_count" %in% colnames(data),
    msg = "data must contain a 'pollen_count' column"
  )

  res <-
    data %>%
    transform_to_proportions(
      pollen_sum = get_pollen_sum(data)
    )

  return(res)
}
