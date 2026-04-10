#' @title Apply Manual Trait Corrections
#' @description
#' Applies human-reviewed corrections from the trait manual corrections
#' tibble to a long-format trait data frame. Rows with `action =
#' "exclude"` are removed. Rows with `action = "scale"` have their
#' `trait_value` multiplied by `scale_factor`. Correction rows whose
#' (`taxon_name` × `trait_domain_name`) combination does not match any
#' record in `data_traits` are reported via `cli::cli_warn()`.
#' @param data_traits
#' A data frame in long format with at least the columns `taxon_name`,
#' `trait_domain_name`, and `trait_value`.
#' @param data_corrections
#' A tibble of validated corrections as returned by
#' [validate_trait_corrections()]. Expected columns: `taxon_name`,
#' `trait_domain_name`, `action` (`"exclude"` | `"scale"`),
#' `scale_factor` (numeric).
#' @return
#' A tibble with the same columns as `data_traits` but with corrected
#' values: excluded records removed and scaled records multiplied by
#' `scale_factor`.
#' @details
#' Corrections that do not match any trait record are warned about but
#' do not cause an error. If `data_corrections` is empty (zero rows),
#' `data_traits` is returned unchanged.
#' @seealso [validate_trait_corrections()], [generate_trait_qc_report()]
#' @export
apply_trait_corrections <- function(data_traits, data_corrections) {
  assertthat::assert_that(
    base::is.data.frame(data_traits),
    msg = "data_traits must be a data frame."
  )

  vec_required_data_traits <-
    base::c("taxon_name", "trait_domain_name", "trait_value")

  assertthat::assert_that(
    base::all(vec_required_data_traits %in% base::colnames(data_traits)),
    msg = base::paste0(
      "data_traits is missing required columns: ",
      base::paste(
        base::setdiff(vec_required_data_traits, base::colnames(data_traits)),
        collapse = ", "
      )
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_corrections),
    msg = "data_corrections must be a data frame."
  )

  vec_required_corrections <-
    base::c("taxon_name", "trait_domain_name", "action", "scale_factor")

  assertthat::assert_that(
    base::all(vec_required_corrections %in% base::colnames(data_corrections)),
    msg = base::paste0(
      "data_corrections is missing required columns: ",
      base::paste(
        base::setdiff(vec_required_corrections, base::colnames(data_corrections)),
        collapse = ", "
      )
    )
  )

  if (
    base::nrow(data_corrections) == 0L
  ) {
    return(tibble::as_tibble(data_traits))
  }

  # Find unmatched correction rows and warn
  data_trait_keys <-
    dplyr::select(data_traits, taxon_name, trait_domain_name) |>
    dplyr::distinct()

  data_unmatched <-
    dplyr::anti_join(
      data_corrections,
      data_trait_keys,
      by = base::c("taxon_name", "trait_domain_name")
    )

  if (
    base::nrow(data_unmatched) > 0L
  ) {
    n_unmatched <-
      base::nrow(data_unmatched)

    cli::cli_warn(
      "{n_unmatched} correction{?s} did not match any trait record."
    )
  }

  # Apply exclude actions: remove matching rows
  data_excludes <-
    dplyr::filter(data_corrections, action == "exclude")

  result <-
    dplyr::anti_join(
      data_traits,
      dplyr::select(data_excludes, taxon_name, trait_domain_name),
      by = base::c("taxon_name", "trait_domain_name")
    )

  # Apply scale actions: multiply trait_value by scale_factor
  data_scales <-
    dplyr::filter(data_corrections, action == "scale")

  if (
    base::nrow(data_scales) > 0L
  ) {
    data_scale_keys <-
      dplyr::select(
        data_scales, taxon_name, trait_domain_name, scale_factor
      )

    result <-
      dplyr::left_join(
        result,
        data_scale_keys,
        by = base::c("taxon_name", "trait_domain_name")
      ) |>
      dplyr::mutate(
        trait_value = dplyr::if_else(
          !base::is.na(scale_factor),
          trait_value * scale_factor,
          trait_value
        )
      ) |>
      dplyr::select(-scale_factor)
  }

  tibble::as_tibble(result)
}
