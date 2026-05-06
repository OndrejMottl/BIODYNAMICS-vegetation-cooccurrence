#' @title Extract Data from VegVault
#' @description
#' Extracts data from a pre-built vaultkeepr query plan by adding
#' abiotic data, filtering by variable name, adding taxa, and
#' collecting the results into a data frame.
#' @param plan
#' A vaultkeepr plan object, typically created by
#' `build_vegvault_plan()`.
#' @param sel_abiotic_var_name
#' A non-empty character vector specifying the abiotic variable
#' names to select (e.g. `"bio1"`).
#' @return
#' A data frame containing the extracted data.
#' @details
#' The function extends the supplied plan with the following steps:
#'   `get_abiotic_data()` -> `select_abiotic_var_by_name()` ->
#'   `get_taxa()` -> `extract_data()`
#'
#' Input validation and plan construction (geographic/temporal
#' filters, dataset type selection) are handled by
#' `build_vegvault_plan()`.
#' @seealso
#'   [build_vegvault_plan()],
#'   [extract_age_uncertainty_from_vegvault()]
#' @export
extract_data_from_vegvault <- function(
    plan,
    sel_abiotic_var_name = NULL) {
  `%>%` <- magrittr::`%>%`

  assertthat::assert_that(
    !base::is.null(plan),
    msg = stringr::str_c(
      "'plan' must not be NULL;",
      " use build_vegvault_plan() to create one"
    )
  )

  assertthat::assert_that(
    base::is.character(sel_abiotic_var_name) &&
      base::length(sel_abiotic_var_name) > 0L,
    msg = stringr::str_c(
      "'sel_abiotic_var_name' must be a non-empty",
      " character vector"
    )
  )

  data_extracted <-
    plan %>%
    vaultkeepr::get_abiotic_data(verbose = FALSE) %>%
    vaultkeepr::select_abiotic_var_by_name(
      sel_var_name = sel_abiotic_var_name
    ) %>%
    vaultkeepr::get_taxa() %>%
    vaultkeepr::extract_data(
      return_raw_data = FALSE,
      verbose = FALSE
    )

  return(data_extracted)
}
