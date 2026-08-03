#' @title Build Community Record Signatures
#' @description
#' Builds deterministic composition signatures for community records.
#' @param data_community
#' A long-format community data frame with `dataset_name`, `sample_name`,
#' `age`, `taxon`, and `pollen_count` columns.
#' @return
#' A tibble with one row per `(dataset_name, sample_name, age)` record and a
#' sorted `community_signature` column.
#' @export
build_community_record_signatures <- function(data_community = NULL) {
  validate_community_source(data_source = data_community)

  res_community_record_signatures <-
    data_community |>
    dplyr::arrange(dataset_name, sample_name, age, taxon) |>
    dplyr::mutate(
      taxon_value = stringr::str_glue("{taxon}={pollen_count}")
    ) |>
    dplyr::group_by(dataset_name, sample_name, age) |>
    dplyr::summarise(
      community_signature = stringr::str_c(
        taxon_value,
        collapse = "|"
      ),
      .groups = "drop"
    )

  return(res_community_record_signatures)
}
