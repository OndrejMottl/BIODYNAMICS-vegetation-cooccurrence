#' @title Select N Taxa
#' @description
#' Selects the top N taxa based on their occurrence across datasets.
#' @param data
#' A data frame containing the input data. Must include columns "taxon" and
#' the column specified in the `per` parameter.
#' @param n_taxa
#' A numeric value specifying the number of taxa to select. Default is Inf.
#' @param per
#' A character string specifying the column name to group by. Default is
#' "dataset_name".
#' @return
#' A data frame containing the filtered data with the top N taxa.
#' @details
#' The function identifies the most common taxa across datasets by counting
#' their occurrences. It then filters the input data to include only the
#' selected taxa. If no taxa are found, an error is raised.
#' @export
select_n_taxa <- function(
    data = NULL,
    n_taxa = Inf,
    per = "dataset_name") {
  assertthat::assert_that(
    is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    is.character(per) && length(per) == 1,
    msg = "per must be a single character string"
  )

  assertthat::assert_that(
    all(
      c("taxon", per) %in% names(data)
    ),
    msg = paste(
      "data must contain the following columns:",
      paste(c("taxon", per), collapse = ", ")
    )
  )

  assertthat::assert_that(
    is.numeric(n_taxa),
    msg = "n_taxa must be a number"
  )

  assertthat::assert_that(
    n_taxa > 0,
    msg = "n_taxa must be greater than 0"
  )


  vec_common_taxa <-
    data %>%
    dplyr::distinct(taxon, !!rlang::sym(per)) %>%
    dplyr::group_by(taxon) %>%
    dplyr::summarise(
      .groups = "drop",
      n_datasets = dplyr::n()
    ) %>%
    dplyr::slice_max(n_datasets, n = n_taxa) %>%
    dplyr::pull(taxon)

  res <-
    data %>%
    dplyr::filter(taxon %in% vec_common_taxa)


  assertthat::assert_that(
    nrow(res) > 0,
    msg = paste(
      "No taxa found in data. Please check the input data.",
      "The number of taxa selected is too high."
    )
  )

  return(res)
}
