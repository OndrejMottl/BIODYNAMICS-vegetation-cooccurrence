#' @title Evaluate Modern Data Quality
#' @description
#' Evaluates modern community preprocessing and returns a compact QA report.
#' @param data_community
#' A long-format community data frame with `dataset_name`, `sample_name`,
#' `age`, `taxon`, and `pollen_count` columns.
#' @param data_sample_ages
#' A sample-age data frame with `dataset_name`, `sample_name`, and `age`
#' columns.
#' @param data_coordinates
#' A coordinate data frame with dataset names in a `dataset_name` column or
#' row names.
#' @param flag_abort_on_impossible_values
#' Logical. If `TRUE` (default), impossible values abort the QA gate.
#' @return
#' A named list containing duplicate-site, duplicate-community,
#' duplicate-key, impossible-value, and summary tables.
#' @export
evaluate_modern_data_quality <- function(
    data_community = NULL,
    data_sample_ages = NULL,
    data_coordinates = NULL,
    flag_abort_on_impossible_values = TRUE) {
  assertthat::assert_that(
    assertthat::is.flag(flag_abort_on_impossible_values),
    msg = stringr::str_c(
      "flag_abort_on_impossible_values must be a single logical value."
    )
  )

  data_duplicate_sites <-
    diagnose_duplicate_sites(data_coordinates = data_coordinates)

  data_duplicate_communities <-
    diagnose_duplicate_communities(data_community = data_community)

  data_duplicate_metadata_keys <-
    diagnose_duplicate_metadata_keys(
      data_community = data_community,
      data_sample_ages = data_sample_ages,
      data_coordinates = data_coordinates
    )

  data_impossible_values <-
    diagnose_modern_data_impossible_values(
      data_community = data_community,
      data_coordinates = data_coordinates
    )

  data_quality_summary <-
    tibble::tibble(
      issue_type = base::c(
        "duplicate_sites",
        "duplicate_communities",
        "duplicate_metadata_keys",
        "impossible_values"
      ),
      n_records = base::c(
        base::nrow(data_duplicate_sites),
        base::nrow(data_duplicate_communities),
        base::nrow(data_duplicate_metadata_keys),
        base::nrow(data_impossible_values)
      )
    )

  if (
    base::isTRUE(flag_abort_on_impossible_values) &&
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

  res_modern_data_quality <-
    base::list(
      data_duplicate_sites = data_duplicate_sites,
      data_duplicate_communities = data_duplicate_communities,
      data_duplicate_metadata_keys = data_duplicate_metadata_keys,
      data_impossible_values = data_impossible_values,
      data_summary = data_quality_summary
    )

  return(res_modern_data_quality)
}
