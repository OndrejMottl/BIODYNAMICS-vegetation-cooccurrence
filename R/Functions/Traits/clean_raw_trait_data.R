#' @title Clean Raw Trait Data
#' @description
#' Selects the required columns from a raw trait data frame and
#' removes rows where `taxon_id` or `trait_value` is `NA`.
#' @param data_raw
#' A data frame returned by [extract_traits_from_vegvault()].
#' Expected to contain at least the columns `taxon_id`,
#' `trait_domain_name`, `trait_name`, and `trait_value`.
#' @return
#' A tibble with columns `taxon_id`, `trait_domain_name`,
#' `trait_name`, and `trait_value`, with all rows where `taxon_id`
#' or `trait_value` is `NA` removed.
#' @details
#' Uses [dplyr::any_of()] for the column selection so the function
#' tolerates input data frames that already lack one of the optional
#' columns without error.
#' @seealso [extract_traits_from_vegvault()],
#'   [resolve_trait_taxon_ids()]
#' @export
clean_raw_trait_data <- function(data_raw) {
  assertthat::assert_that(
    base::is.data.frame(data_raw),
    msg = "'data_raw' must be a data frame."
  )

  res <-
    data_raw |>
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

  return(res)
}
