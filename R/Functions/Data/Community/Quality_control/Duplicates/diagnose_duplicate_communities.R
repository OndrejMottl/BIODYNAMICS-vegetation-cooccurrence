#' @title Diagnose Duplicate Modern Communities
#' @description
#' Returns modern sample records with identical sorted community composition.
#' @param data_community
#' A long-format community data frame with `dataset_name`, `sample_name`,
#' `age`, `taxon`, and `pollen_count` columns.
#' @return
#' A tibble with one row per record involved in a duplicated community
#' signature. Returns a zero-row tibble when no duplicate communities are
#' detected.
#' @export
diagnose_duplicate_communities <- function(data_community = NULL) {
  data_record_signatures <-
    build_community_record_signatures(
      data_community = data_community
    )

  res_duplicate_communities <-
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

  return(res_duplicate_communities)
}
