#' @title Prepare Trait Matrix for Dissimilarity
#' @description
#' Applies an explicit named transformation contract to numeric trait columns
#' while preserving the taxon identifier and missing values. Traits omitted
#' from the contract are excluded from the returned sensitivity matrix.
#' @param data_trait_table Wide taxon-by-trait data frame.
#' @param vec_trait_transformations Named character vector selecting one or
#' more available trait columns. Supported values are `"identity"` and
#' `"log10"`.
#' @param taxon_column Character scalar naming the taxon identifier column.
#' @return A transformed tibble containing the taxon and selected traits.
#' @examples
#' prepare_trait_matrix_for_dissimilarity(
#'   data_trait_table = tibble::tibble(
#'     taxon_name = c("A", "B"),
#'     `Plant heigh` = c(10, 100)
#'   ),
#'   vec_trait_transformations = c(`Plant heigh` = "log10")
#' )
#' @export
prepare_trait_matrix_for_dissimilarity <- function(
    data_trait_table,
    vec_trait_transformations,
    taxon_column = "taxon_name") {
  assertthat::assert_that(
    base::is.data.frame(data_trait_table),
    base::is.character(taxon_column),
    base::length(taxon_column) == 1L,
    taxon_column %in% base::names(data_trait_table),
    msg = "Trait table and taxon column are invalid."
  )
  vec_available_trait_columns <-
    base::setdiff(base::names(data_trait_table), taxon_column)
  assertthat::assert_that(
    base::length(vec_available_trait_columns) > 0L,
    base::all(
      purrr::map_lgl(
        data_trait_table[vec_available_trait_columns],
        base::is.numeric
      )
    ),
    msg = "Every trait column must be numeric."
  )
  assertthat::assert_that(
    base::is.character(vec_trait_transformations),
    !base::is.null(base::names(vec_trait_transformations)),
    base::length(vec_trait_transformations) > 0L,
    !base::anyDuplicated(base::names(vec_trait_transformations)),
    base::all(
      base::names(vec_trait_transformations) %in%
        vec_available_trait_columns
    ),
    msg = "The transformation contract must select available traits."
  )
  vec_trait_columns <-
    base::names(vec_trait_transformations)
  assertthat::assert_that(
    base::all(
      vec_trait_transformations %in% base::c("identity", "log10")
    ),
    msg = "Trait transformations must be identity or log10."
  )

  for (
    trait_domain_name in vec_trait_columns
  ) {
    vec_trait_values <-
      data_trait_table[[trait_domain_name]]
    vec_trait_values_observed <-
      vec_trait_values[!base::is.na(vec_trait_values)]
    assertthat::assert_that(
      base::all(base::is.finite(vec_trait_values_observed)),
      msg = stringr::str_glue(
        "Trait '{trait_domain_name}' contains non-finite values."
      )
    )
    if (
      vec_trait_transformations[[trait_domain_name]] == "log10"
    ) {
      assertthat::assert_that(
        base::all(vec_trait_values_observed > 0),
        msg = stringr::str_glue(
          "Log10 trait '{trait_domain_name}' must be strictly positive."
        )
      )
    }
  }

  data_trait_table_prepared <-
    purrr::reduce(
      vec_trait_columns,
      function(data_accumulator, trait_domain_name) {
        transformation <-
          vec_trait_transformations[[trait_domain_name]]
        vec_trait_values <-
          data_accumulator[[trait_domain_name]]
        vec_trait_values_prepared <-
          if (
            transformation == "log10"
          ) {
            base::log10(vec_trait_values)
          } else {
            vec_trait_values
          }
        dplyr::mutate(
          data_accumulator,
          !!trait_domain_name := vec_trait_values_prepared
        )
      },
      .init = data_trait_table |>
        dplyr::select(
          dplyr::all_of(
            base::c(taxon_column, vec_trait_columns)
          )
        ) |>
        tibble::as_tibble()
    )

  return(data_trait_table_prepared)
}
