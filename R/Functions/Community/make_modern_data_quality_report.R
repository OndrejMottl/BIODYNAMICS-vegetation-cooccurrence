#' @title Make Modern Data Quality Report
#' @description
#' Builds a compact QA report for modern community preprocessing.
#' @param data_source
#' A long-format community data frame with `dataset_name`, `sample_name`,
#' `age`, `taxon`, and `pollen_count` columns.
#' @param data_sample_ages
#' A sample-age data frame with `dataset_name`, `sample_name`, and `age`
#' columns.
#' @param data_coordinates
#' A coordinate data frame with dataset names in a `dataset_name` column or
#' row names.
#' @param abort_on_impossible
#' Logical. If `TRUE` (default), impossible values abort the QA gate.
#' @return
#' A named list containing duplicate-site, duplicate-community,
#' duplicate-key, impossible-value, and summary tables.
#' @export
make_modern_data_quality_report <- function(
    data_source = NULL,
    data_sample_ages = NULL,
    data_coordinates = NULL,
    abort_on_impossible = TRUE) {
  assertthat::assert_that(
    assertthat::is.flag(abort_on_impossible),
    msg = "abort_on_impossible must be a single logical value."
  )

  data_duplicate_sites <-
    detect_duplicate_sites(data_source = data_coordinates)

  data_duplicate_communities <-
    detect_duplicate_communities(data_source = data_source)

  data_duplicate_metadata_keys <-
    detect_duplicate_metadata_keys(
      data_source = data_source,
      data_sample_ages = data_sample_ages,
      data_coordinates = data_coordinates
    )

  data_impossible_values <-
    check_modern_data_impossible_values(
      data_source = data_source,
      data_coordinates = data_coordinates
    )

  data_summary <-
    tibble::tibble(
      issue_type = c(
        "duplicate_sites",
        "duplicate_communities",
        "duplicate_metadata_keys",
        "impossible_values"
      ),
      n_records = c(
        base::nrow(data_duplicate_sites),
        base::nrow(data_duplicate_communities),
        base::nrow(data_duplicate_metadata_keys),
        base::nrow(data_impossible_values)
      )
    )

  if (
    base::isTRUE(abort_on_impossible) &&
      base::nrow(data_impossible_values) > 0L
  ) {
    cli::cli_abort(
      c(
        "Modern preprocessing QA found impossible values.",
        "i" = stringr::str_c(
          "Inspect the `data_impossible_values` QA table before",
          " ",
          "running modern modelling."
        )
      )
    )
  }

  res <-
    base::list(
      data_duplicate_sites = data_duplicate_sites,
      data_duplicate_communities = data_duplicate_communities,
      data_duplicate_metadata_keys = data_duplicate_metadata_keys,
      data_impossible_values = data_impossible_values,
      data_summary = data_summary
    )

  return(res)
}
