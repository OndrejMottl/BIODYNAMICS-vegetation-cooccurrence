#' @title Select Top Taxa by Group Occurrence
#' @description
#' Selects the most frequently occurring taxa according to the number of
#' distinct groups in which each taxon occurs.
#' @param data_community
#' A community data frame containing `taxon` and the column named by
#' `grouping_column_name`.
#' @param maximum_taxon_count
#' A positive numeric scalar giving the maximum number of taxa to retain.
#' Defaults to `Inf`.
#' @param grouping_column_name
#' A character scalar naming the column used to count distinct occurrences.
#' Defaults to `"dataset_name"`.
#' @return
#' The input community data restricted to the selected taxa.
#' @details
#' Taxa are ranked by their number of distinct
#' `grouping_column_name` values, with taxon name used to break ties.
#' @export
select_top_taxa_by_group_occurrence <- function(
    data_community = NULL,
    maximum_taxon_count = Inf,
    grouping_column_name = "dataset_name") {
  assertthat::assert_that(
    base::is.data.frame(data_community),
    msg = "data_community must be a data frame"
  )

  assertthat::assert_that(
    base::is.character(grouping_column_name) &&
      base::length(grouping_column_name) == 1L,
    msg = "grouping_column_name must be a character scalar"
  )

  assertthat::assert_that(
    base::all(
      base::c("taxon", grouping_column_name) %in%
        base::names(data_community)
    ),
    msg = stringr::str_c(
      "data_community must contain the following columns: ",
      stringr::str_c(
        base::c("taxon", grouping_column_name),
        collapse = ", "
      )
    )
  )

  assertthat::assert_that(
    base::is.numeric(maximum_taxon_count) &&
      base::length(maximum_taxon_count) == 1L,
    msg = "maximum_taxon_count must be a numeric scalar"
  )

  assertthat::assert_that(
    maximum_taxon_count > 0,
    msg = "maximum_taxon_count must be greater than 0"
  )

  vec_selected_taxa <-
    data_community |>
    dplyr::distinct(
      taxon,
      !!rlang::sym(grouping_column_name)
    ) |>
    dplyr::group_by(taxon) |>
    dplyr::summarise(
      .groups = "drop",
      group_occurrence_count = dplyr::n()
    ) |>
    dplyr::arrange(
      dplyr::desc(group_occurrence_count),
      taxon
    ) |>
    dplyr::slice_head(n = maximum_taxon_count) |>
    dplyr::pull(taxon)

  res_community_selected <-
    data_community |>
    dplyr::filter(taxon %in% vec_selected_taxa)

  assertthat::assert_that(
    base::nrow(res_community_selected) > 0L,
    msg = stringr::str_c(
      "No taxa found in data. Please check the input data. ",
      "The number of taxa selected is too high."
    )
  )

  return(res_community_selected)
}
