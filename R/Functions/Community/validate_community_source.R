#' @title Validate Community Source
#' @description
#' Validates the standard long-format community data contract.
#' @param data_source
#' A long-format community data frame with `dataset_name`, `sample_name`,
#' `age`, `taxon`, and `pollen_count` columns.
#' @param check_numeric
#' Logical. If `TRUE` (default), `age` and `pollen_count` must be numeric.
#' @return
#' The input data frame, invisibly, when validation succeeds.
#' @export
validate_community_source <- function(
    data_source = NULL,
    check_numeric = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data_source),
    msg = "data_source must be a data frame."
  )
  assertthat::assert_that(
    assertthat::is.flag(check_numeric),
    msg = "check_numeric must be a single logical value."
  )

  assertthat::assert_that(
    base::all(
      c(
        "dataset_name",
        "sample_name",
        "age",
        "taxon",
        "pollen_count"
      ) %in% base::names(data_source)
    ),
    msg = stringr::str_c(
      "data_source must contain columns: ",
      "dataset_name, sample_name, age, taxon, and pollen_count."
    )
  )

  if (
    base::isTRUE(check_numeric)
  ) {
    assertthat::assert_that(
      base::is.numeric(dplyr::pull(data_source, pollen_count)),
      msg = "pollen_count must be numeric."
    )
    assertthat::assert_that(
      base::is.numeric(dplyr::pull(data_source, age)),
      msg = "age must be numeric."
    )
  }

  return(base::invisible(data_source))
}
