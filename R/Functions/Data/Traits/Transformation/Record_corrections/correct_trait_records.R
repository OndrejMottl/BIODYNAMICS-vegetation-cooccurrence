#' @title Correct Trait Records
#' @description
#' Corrects a long-format trait-record table using human-approved
#' correction instructions. Rows with `action = "exclude"` are
#' removed. Rows with `action = "scale"` have their `trait_value`
#' multiplied by `scale_factor`. Correction rows whose
#' (`taxon_name` × `trait_domain_name`) combination does not match any
#' record in `data_trait_records` are reported via `cli::cli_warn()`.
#' @param data_trait_records
#' A data frame in long format with at least the columns `taxon_name`,
#' `trait_domain_name`, and `trait_value`.
#' @param data_trait_corrections
#' A tibble of approved corrections as returned by
#' [validate_trait_corrections()]. Expected columns: `taxon_name`,
#' `trait_domain_name`, `action` (`"exclude"` | `"scale"`),
#' `scale_factor` (numeric).
#' @return
#' A tibble with the same columns as `data_trait_records`, with
#' excluded records removed and scaled records multiplied by
#' `scale_factor`.
#' @details
#' Corrections that do not match any trait record are warned about but
#' do not cause an error. If `data_trait_corrections` is empty,
#' `data_trait_records` is returned unchanged.
#' @seealso [load_trait_corrections()],
#'   [validate_trait_corrections()], [generate_trait_qc_report()]
#' @export
correct_trait_records <- function(
    data_trait_records,
    data_trait_corrections) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_records),
    msg = "data_trait_records must be a data frame."
  )

  vec_required_trait_columns <-
    base::c("taxon_name", "trait_domain_name", "trait_value")

  assertthat::assert_that(
    base::all(
      vec_required_trait_columns %in%
        base::colnames(data_trait_records)
    ),
    msg = base::paste0(
      "data_trait_records is missing required columns: ",
      base::paste(
        base::setdiff(
          vec_required_trait_columns,
          base::colnames(data_trait_records)
        ),
        collapse = ", "
      )
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_trait_corrections),
    msg = "data_trait_corrections must be a data frame."
  )

  vec_required_correction_columns <-
    base::c("taxon_name", "trait_domain_name", "action", "scale_factor")

  assertthat::assert_that(
    base::all(
      vec_required_correction_columns %in%
        base::colnames(data_trait_corrections)
    ),
    msg = base::paste0(
      "data_trait_corrections is missing required columns: ",
      base::paste(
        base::setdiff(
          vec_required_correction_columns,
          base::colnames(data_trait_corrections)
        ),
        collapse = ", "
      )
    )
  )

  if (
    base::nrow(data_trait_corrections) == 0L
  ) {
    return(tibble::as_tibble(data_trait_records))
  }

  data_trait_record_keys <-
    dplyr::select(
      data_trait_records,
      "taxon_name",
      "trait_domain_name"
    ) |>
    dplyr::distinct()

  data_unmatched_corrections <-
    dplyr::anti_join(
      data_trait_corrections,
      data_trait_record_keys,
      by = base::c("taxon_name", "trait_domain_name")
    )

  if (
    base::nrow(data_unmatched_corrections) > 0L
  ) {
    n_unmatched_corrections <-
      base::nrow(data_unmatched_corrections)

    cli::cli_warn(
      base::paste0(
        "{n_unmatched_corrections} correction{?s} ",
        "did not match any trait record."
      )
    )
  }

  data_exclusion_corrections <-
    dplyr::filter(
      data_trait_corrections,
      .data[["action"]] == "exclude"
    )

  data_trait_records_corrected <-
    dplyr::anti_join(
      data_trait_records,
      dplyr::select(
        data_exclusion_corrections,
        "taxon_name",
        "trait_domain_name"
      ),
      by = base::c("taxon_name", "trait_domain_name")
    )

  data_scaling_corrections <-
    dplyr::filter(
      data_trait_corrections,
      .data[["action"]] == "scale"
    )

  if (
    base::nrow(data_scaling_corrections) > 0L
  ) {
    data_scaling_keys <-
      dplyr::select(
        data_scaling_corrections,
        "taxon_name",
        "trait_domain_name",
        "scale_factor"
      )

    data_trait_records_corrected <-
      dplyr::left_join(
        data_trait_records_corrected,
        data_scaling_keys,
        by = base::c("taxon_name", "trait_domain_name")
      ) |>
      dplyr::mutate(
        trait_value = dplyr::if_else(
          !base::is.na(.data[["scale_factor"]]),
          .data[["trait_value"]] * .data[["scale_factor"]],
          .data[["trait_value"]]
        )
      ) |>
      dplyr::select(-"scale_factor")
  }

  data_trait_records_corrected <-
    tibble::as_tibble(data_trait_records_corrected)

  return(data_trait_records_corrected)
}
