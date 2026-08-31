#' @title Build Interim Trait Analysis Release
#' @description
#' Freezes corrected VegVault 1.0.0 records behind an explicit six-domain
#' analysis contract and records domain-level evidence status.
#' @param data_trait_records Corrected classified trait records.
#' @param vegvault_version Character scalar VegVault version.
#' @param release_id Character scalar stable interim release identifier.
#' @param release_date Character scalar release date in ISO format.
#' @return A list containing unchanged data_trait_records and a
#' data_trait_domain_status tibble.
#' @details
#' Leaf mass per area and leaf nitrogen content per unit mass remain available
#' in the primary six-trait analysis but are marked as provisional because
#' their original source units have not been fully reconstructed. A different
#' VegVault version fails closed so a future corrected release must explicitly
#' replace this compatibility contract.
#' @examples
#' \dontrun{
#' build_trait_analysis_release(
#'   data_trait_records = data_traits_classified_corrected,
#'   vegvault_version = "1.0.0",
#'   release_id = "vegvault_1_0_0_interim_2026_08_31",
#'   release_date = "2026-08-31"
#' )
#' }
#' @export
build_trait_analysis_release <- function(
    data_trait_records,
    vegvault_version,
    release_id,
    release_date) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_records),
    base::all(
      base::c("trait_domain_name", "trait_value") %in%
        base::names(data_trait_records)
    ),
    base::is.numeric(data_trait_records[["trait_value"]]),
    msg = "Trait records must contain domain and numeric value columns."
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

  if (
    vegvault_version != "1.0.0"
  ) {
    cli::cli_abort(
      "The interim trait release is restricted to VegVault 1.0.0."
    )
  }

  date_release <-
    base::suppressWarnings(
      base::as.Date(release_date)
    )
  if (
    base::is.na(date_release) ||
      base::format(date_release, "%Y-%m-%d") != release_date
  ) {
    cli::cli_abort("release_date must use valid YYYY-MM-DD format.")
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
    !base::setequal(vec_observed_domains, vec_supported_domains)
  ) {
    cli::cli_abort(
      "The interim release must contain exactly six supported domains."
    )
  }

  vec_evidence_status <-
    dplyr::case_when(
      vec_supported_domains %in%
        base::c(
          "Leaf mass per area",
          "Leaf nitrogen content per unit mass"
        ) ~ "provisional_units",
      vec_supported_domains == "Stem specific density" ~
        "interim_source_uncertainty",
      TRUE ~ "interim_reviewed"
    )
  data_trait_domain_status <-
    tibble::tibble(
      release_id = release_id,
      release_date = release_date,
      vegvault_version = vegvault_version,
      trait_domain_name = vec_supported_domains,
      evidence_status = vec_evidence_status,
      included_in_primary = TRUE
    )
  res_release <-
    base::list(
      data_trait_records = tibble::as_tibble(data_trait_records),
      data_trait_domain_status = data_trait_domain_status
    )

  return(res_release)
}
