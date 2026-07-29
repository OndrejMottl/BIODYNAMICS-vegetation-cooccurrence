#' @title Filter Complete Trait Records
#' @description
#' Selects the required columns from a raw trait data frame and
#' removes rows where `taxon_id` or `trait_value` is `NA`.
#' @param data_trait_records_raw
#' A data frame returned by [load_trait_records_from_vegvault()].
#' Expected to contain at least the columns `taxon_id`,
#' `trait_domain_name`, `trait_name`, and `trait_value`.
#' @return
#' A tibble with columns `taxon_id`, `trait_domain_name`,
#' `trait_name`, and `trait_value`, with all rows where `taxon_id`
#' or `trait_value` is `NA` removed.
#' @details
#' Uses [dplyr::any_of()] for column selection so the function
#' tolerates input data frames that already lack one of the optional
#' columns without error.
#' @seealso [load_trait_records_from_vegvault()],
#'   [resolve_trait_taxon_ids()]
#' @export
filter_complete_trait_records <- function(data_trait_records_raw) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_records_raw),
    msg = "'data_trait_records_raw' must be a data frame."
  )

  data_trait_records_complete <-
    data_trait_records_raw |>
    dplyr::select(
      dplyr::any_of(
        base::c(
          "taxon_id",
          "trait_domain_name",
          "trait_name",
          "trait_value"
        )
      )
    ) |>
    dplyr::filter(
      !base::is.na(.data[["taxon_id"]]),
      !base::is.na(.data[["trait_value"]])
    )

  return(data_trait_records_complete)
}
