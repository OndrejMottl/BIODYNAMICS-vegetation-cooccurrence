#' @title Build Trait Analysis Release
#' @description
#' Freezes corrected VegVault trait records behind an explicit six-domain
#' analysis contract and records the reviewed unit and evidence status of
#' each domain.
#' @param data_trait_records
#' Corrected classified trait records with `trait_domain_name`,
#' `trait_unit`, and a numeric `trait_value`.
#' @param data_trait_domain_units
#' The validated trait-domain unit table of the release, as returned by
#' [validate_trait_domain_units()].
#' @param vegvault_version
#' Character scalar VegVault version of the release (the `vegvault_version`
#' of the `config_vegvault_release` target).
#' @param release_id
#' Character scalar stable release identifier. It must start with
#' `vegvault_` and the version with underscores, for example
#' `vegvault_2_0_0_reviewed_2026_12_01`.
#' @param release_date
#' Character scalar release date in ISO format (`YYYY-MM-DD`).
#' @return
#' A list containing the unchanged `data_trait_records` and a
#' `data_trait_domain_status` tibble: the unit table with `release_id` and
#' `release_date` in front, one row per domain.
#' @details
#' The release stops with an error when the unit table belongs to another
#' VegVault release, when `release_id` names another release, when the
#' records or the unit table do not hold exactly the six supported domains,
#' or when a record's unit differs from the unit of its domain. The domain
#' statuses come from the reviewed unit table, not from this function.
#' @seealso [validate_trait_domain_units()], [load_trait_domain_units()]
#' @examples
#' \dontrun{
#' build_trait_analysis_release(
#'   data_trait_records = data_traits_classified_corrected,
#'   data_trait_domain_units = data_trait_domain_units_validated,
#'   vegvault_version = "2.0.0",
#'   release_id = "vegvault_2_0_0_reviewed_2026_12_01",
#'   release_date = "2026-12-01"
#' )
#' }
#' @export
build_trait_analysis_release <- function(
    data_trait_records,
    data_trait_domain_units,
    vegvault_version,
    release_id,
    release_date) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_records),
    base::all(
      base::c("trait_domain_name", "trait_unit", "trait_value") %in%
        base::names(data_trait_records)
    ),
    base::is.numeric(data_trait_records[["trait_value"]]),
    msg = stringr::str_c(
      "Trait records must contain domain, unit, and numeric value ",
      "columns."
    )
  )
  assertthat::assert_that(
    base::is.data.frame(data_trait_domain_units),
    base::all(
      base::c(
        "vegvault_version",
        "trait_domain_name",
        "trait_unit",
        "evidence_status",
        "included_in_primary"
      ) %in%
        base::names(data_trait_domain_units)
    ),
    msg = stringr::str_c(
      "The unit table must contain version, domain, unit, evidence ",
      "status, and primary-inclusion columns."
    )
  )
  assertthat::assert_that(
    base::is.character(vegvault_version),
    base::length(vegvault_version) == 1L,
    !base::is.na(vegvault_version),
    base::nzchar(vegvault_version),
    base::is.character(release_id),
    base::length(release_id) == 1L,
    !base::is.na(release_id),
    base::nzchar(release_id),
    base::is.character(release_date),
    base::length(release_date) == 1L,
    !base::is.na(release_date),
    base::nzchar(release_date),
    msg = "Release metadata must be non-empty character scalars."
  )

  date_release <-
    base::as.Date(release_date, format = "%Y-%m-%d")
  if (
    base::is.na(date_release) ||
      base::format(date_release, "%Y-%m-%d") != release_date
  ) {
    cli::cli_abort("release_date must use valid YYYY-MM-DD format.")
  }

  prefix_release_id <-
    stringr::str_c(
      "vegvault_",
      stringr::str_replace_all(vegvault_version, "[.]", "_"),
      "_"
    )
  if (
    !stringr::str_starts(release_id, stringr::fixed(prefix_release_id))
  ) {
    cli::cli_abort(
      c(
        "release_id must name VegVault {vegvault_version}.",
        "i" = "Expected a release_id starting with {.val {prefix_release_id}}."
      )
    )
  }

  if (
    base::any(
      data_trait_domain_units[["vegvault_version"]] != vegvault_version
    )
  ) {
    cli::cli_abort(
      "The unit table belongs to another VegVault release."
    )
  }

  vec_supported_domains <-
    base::c(
      "Diaspore mass",
      "Leaf Area",
      "Leaf mass per area",
      "Leaf nitrogen content per unit mass",
      "Plant heigh",
      "Stem specific density"
    )
  vec_observed_domains <-
    data_trait_records |>
    dplyr::pull("trait_domain_name") |>
    base::unique()

  if (
    !base::setequal(vec_observed_domains, vec_supported_domains) ||
      !base::setequal(
        data_trait_domain_units[["trait_domain_name"]],
        vec_supported_domains
      ) ||
      base::anyDuplicated(data_trait_domain_units[["trait_domain_name"]]) >
        0L
  ) {
    cli::cli_abort(
      stringr::str_c(
        "The release records and the unit table must contain exactly six ",
        "supported domains."
      )
    )
  }

  vec_expected_units <-
    data_trait_domain_units[["trait_unit"]][
      base::match(
        data_trait_records[["trait_domain_name"]],
        data_trait_domain_units[["trait_domain_name"]]
      )
    ]
  is_unit_mismatch <-
    base::is.na(data_trait_records[["trait_unit"]]) |
    vec_expected_units != data_trait_records[["trait_unit"]]

  if (
    base::any(is_unit_mismatch)
  ) {
    cli::cli_abort(
      c(
        "Every release record must have the unit of its domain.",
        "x" = "{base::sum(is_unit_mismatch)} record{?s} differ."
      )
    )
  }

  data_trait_domain_status <-
    data_trait_domain_units |>
    tibble::as_tibble() |>
    dplyr::mutate(
      release_id = release_id,
      release_date = release_date,
      .before = 1L
    )

  res_release <-
    base::list(
      data_trait_records = tibble::as_tibble(data_trait_records),
      data_trait_domain_status = data_trait_domain_status
    )

  return(res_release)
}
