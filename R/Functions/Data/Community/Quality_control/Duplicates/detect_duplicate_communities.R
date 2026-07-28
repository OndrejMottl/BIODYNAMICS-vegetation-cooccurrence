#' @title Detect Duplicate Modern Communities
#' @description
#' Detects modern sample records with identical sorted community composition.
#' @param data_source
#' A long-format community data frame with `dataset_name`, `sample_name`,
#' `age`, `taxon`, and `pollen_count` columns.
#' @return
#' A tibble with one row per record involved in a duplicated community
#' signature. Returns a zero-row tibble when no duplicate communities are
#' detected.
#' @export
detect_duplicate_communities <- function(data_source = NULL) {
  data_record_signatures <-
    make_community_record_signatures(data_source = data_source)

  res <-
    data_record_signatures |>
    dplyr::group_by(community_signature) |>
    dplyr::mutate(
      n_records = dplyr::n(),
      duplicate_community_group = dplyr::cur_group_id()
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(n_records > 1L) |>
    dplyr::arrange(community_signature, dataset_name, sample_name, age) |>
    dplyr::select(
      duplicate_community_group,
      dataset_name,
      sample_name,
      age,
      community_signature,
      n_records
    )

  return(res)
}
