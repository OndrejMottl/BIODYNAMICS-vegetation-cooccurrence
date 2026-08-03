#' @title Write a Trait Quality-Control Report
#' @description
#' Computes per-domain and per-domain×taxon summary statistics for raw
#' trait data and identifies suspected outlier taxa at two levels: a
#' lenient domain-level check and a stricter within-taxon check.
#' Writes the per-taxon summary as a human-readable CSV report and creates
#' a header-only corrections template when that template does not yet exist.
#' @param data_trait_records
#' A data frame in long format with at least the columns
#' `taxon_name`, `trait_domain_name`, `trait_name`, and
#' `trait_value`.
#' @param path_trait_corrections
#' Character scalar. Path to `trait_manual_corrections.csv`.
#' Default: `here::here("Data/Input/trait_manual_corrections.csv")`.
#' @param path_trait_quality_control_report
#' Character scalar or `NULL`. Optional path to the CSV quality-control report.
#' If `NULL` (default), the function writes a date-stamped file to
#' `Data/Temp/trait_qc_report_{YYYY-MM-DD}.csv`.
#' @param domain_iqr_multiplier
#' Positive numeric scalar. A domain value is flagged as a suspected
#' outlier when `|trait_value - median| > domain_iqr_multiplier * IQR`,
#' computed across all records in that domain regardless of taxon.
#' Default: `3`. This conservative symmetric median-IQR screen is
#' intended to catch unit mix-ups while tolerating broad cross-taxon
#' variation.
#' @param taxon_iqr_multiplier
#' Positive numeric scalar. The stricter IQR multiplier applied
#' within each taxon × domain group. A record is flagged when
#' `|trait_value - taxon_median| > taxon_iqr_multiplier * taxon_IQR`
#' and the taxon has at least `minimum_taxon_records` records in the domain.
#' Default: `1.5`. This is tighter than the domain-level
#' `domain_iqr_multiplier` because within-taxon
#' variability should be far smaller than cross-taxon variability;
#' any record deviating by more than 1.5 × the within-taxon IQR is
#' suspicious even when it is not an extreme cross-domain outlier.
#' @param minimum_taxon_records
#' Positive integer scalar. Minimum number of records a taxon must
#' have within a domain before the per-taxon IQR check is applied.
#' Taxa with fewer records are skipped at the taxon level (IQR cannot
#' be estimated reliably from very small samples). Default: `10L`.
#' @return
#' A named list with four computed quality-control elements:
#' \describe{
#'   \item{`summary_by_domain`}{A tibble with one row per
#'     `trait_domain_name` containing: `n_records`, `n_taxa`,
#'     `mean`, `median`, `sd`, `lwr_90`, `upr_90`, `IQR`,
#'     `n_suspected_outliers`.}
#'   \item{`summary_by_domain_taxon`}{A tibble with one row per
#'     `trait_domain_name × taxon_name` combination where the taxon
#'     has at least `minimum_taxon_records` records in that domain,
#'     containing: `n_records`, `mean`, `median`, `sd`, `IQR`,
#'     `n_suspected_outliers_taxon`.}
#'   \item{`suspected_outlier_taxa_domain`}{A character vector of taxon
#'     names whose trait value in any domain falls more than
#'     `domain_iqr_multiplier` × IQR from the domain median
#'     (cross-taxon check).}
#'   \item{`suspected_outlier_taxa_taxon`}{A character vector of taxon
#'     names that have at least `minimum_taxon_records` records in a
#'     domain and whose trait value falls more than
#'     `taxon_iqr_multiplier` × IQR from their own taxon median
#'     (within-taxon check).}
#' }
#' @details
#' Two outlier detection levels are applied:
#' \enumerate{
#'   \item **Domain level** (`suspected_outlier_taxa_domain`): flags values
#'     where
#'     `|trait_value - domain_median| > domain_iqr_multiplier * domain_IQR`
#'     (default 3). Applied to all records.
#'   \item **Taxon level** (`suspected_outlier_taxa_taxon`): flags values
#'     where
#'     `|trait_value - taxon_median| > taxon_iqr_multiplier * taxon_IQR`
#'     (default 1.5). Applied only when the taxon
#'     has at least `minimum_taxon_records` records in the domain and when
#'     `taxon_IQR > 0`. This stricter check catches within-taxon
#'     inconsistencies that the cross-taxon check would miss.
#' }
#' The CSV report contains the per-domain×taxon summary. By default it is
#' written to `Data/Temp/trait_qc_report_{YYYY-MM-DD}.csv`, but an
#' explicit `path_trait_quality_control_report` can be supplied when the
#' caller needs an isolated output location.
#' The corrections template written when absent
#' contains the columns: `taxon_name`, `trait_domain_name`, `action`,
#' `scale_factor`, `notes`, `CHECKED`.
#' @examples
#' data_trait_records <-
#'   tibble::tibble(
#'     taxon_name = base::rep("Quercus", 12L),
#'     trait_domain_name = base::rep("SLA", 12L),
#'     trait_name = base::rep("LMA", 12L),
#'     trait_value = base::seq(10, 21, by = 1)
#'   )
#'
#' path_trait_corrections <-
#'   base::tempfile(fileext = ".csv")
#'
#' path_trait_quality_control_report <-
#'   base::tempfile(fileext = ".csv")
#'
#' write_trait_quality_control_report(
#'   data_trait_records = data_trait_records,
#'   path_trait_corrections = path_trait_corrections,
#'   path_trait_quality_control_report = path_trait_quality_control_report
#' )
#'
#' write_trait_quality_control_report(
#'   data_trait_records = data_trait_records,
#'   path_trait_corrections = path_trait_corrections
#' )
#' @seealso [flag_trait_outliers()], [load_trait_corrections()],
#'   [validate_trait_corrections()], [correct_trait_records()]
#' @export
write_trait_quality_control_report <- function(
    data_trait_records,
    path_trait_corrections = here::here(
      "Data/Input/trait_manual_corrections.csv"
    ),
    path_trait_quality_control_report = NULL,
    domain_iqr_multiplier = 3,
    taxon_iqr_multiplier = 1.5,
    minimum_taxon_records = 10L) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_records),
    msg = "data_trait_records must be a data frame."
  )

  required_columns <-
    base::c("taxon_name", "trait_domain_name", "trait_name", "trait_value")

  missing_required_columns <-
    base::setdiff(
      required_columns,
      base::colnames(data_trait_records)
    )

  assertthat::assert_that(
    base::length(missing_required_columns) == 0L,
    msg = stringr::str_c(
      "data_trait_records is missing required columns: ",
      stringr::str_c(missing_required_columns, collapse = ", ")
    )
  )

  assertthat::assert_that(
    base::is.character(path_trait_corrections),
    msg = "path_trait_corrections must be a character string."
  )

  assertthat::assert_that(
    base::length(path_trait_corrections) == 1L,
    msg = "path_trait_corrections must be a scalar (length 1)."
  )

  assertthat::assert_that(
    base::is.null(path_trait_quality_control_report) ||
      base::is.character(path_trait_quality_control_report),
    msg = stringr::str_c(
      "path_trait_quality_control_report must be NULL or a ",
      "character string."
    )
  )

  if (
    !base::is.null(path_trait_quality_control_report)
  ) {
    assertthat::assert_that(
      base::length(path_trait_quality_control_report) == 1L,
      msg = "path_trait_quality_control_report must be a scalar (length 1)."
    )
  }

  assertthat::assert_that(
    base::is.numeric(domain_iqr_multiplier),
    msg = "domain_iqr_multiplier must be numeric."
  )

  assertthat::assert_that(
    base::length(domain_iqr_multiplier) == 1L,
    msg = "domain_iqr_multiplier must be a scalar (length 1)."
  )

  assertthat::assert_that(
    domain_iqr_multiplier > 0,
    msg = "domain_iqr_multiplier must be positive."
  )

  assertthat::assert_that(
    base::is.numeric(taxon_iqr_multiplier),
    msg = "taxon_iqr_multiplier must be numeric."
  )

  assertthat::assert_that(
    base::length(taxon_iqr_multiplier) == 1L,
    msg = "taxon_iqr_multiplier must be a scalar (length 1)."
  )

  assertthat::assert_that(
    taxon_iqr_multiplier > 0,
    msg = "taxon_iqr_multiplier must be positive."
  )

  assertthat::assert_that(
    base::is.numeric(minimum_taxon_records),
    msg = "minimum_taxon_records must be numeric."
  )

  assertthat::assert_that(
    base::length(minimum_taxon_records) == 1L,
    msg = "minimum_taxon_records must be a scalar (length 1)."
  )

  assertthat::assert_that(
    minimum_taxon_records >= 1,
    msg = "minimum_taxon_records must be at least 1."
  )

  data_domain_outlier_flags <-
    data_trait_records |>
    dplyr::group_by(.data[["trait_domain_name"]]) |>
    flag_trait_outliers(
      trait_value_column = "trait_value",
      iqr_multiplier = domain_iqr_multiplier
    )

  data_domain_summary <-
    data_domain_outlier_flags |>
    dplyr::group_by(.data[["trait_domain_name"]]) |>
    dplyr::summarise(
      n_records = dplyr::n(),
      n_taxa = dplyr::n_distinct(.data[["taxon_name"]]),
      mean = base::mean(.data[["trait_value"]], na.rm = TRUE),
      median = stats::median(.data[["trait_value"]], na.rm = TRUE),
      sd = stats::sd(.data[["trait_value"]], na.rm = TRUE),
      lwr_90 = stats::quantile(
        .data[["trait_value"]],
        probs = 0.05,
        na.rm = TRUE,
        names = FALSE
      ),
      upr_90 = stats::quantile(
        .data[["trait_value"]],
        probs = 0.95,
        na.rm = TRUE,
        names = FALSE
      ),
      IQR = stats::IQR(.data[["trait_value"]], na.rm = TRUE),
      n_suspected_outliers = base::sum(
        .data[["is_trait_outlier"]],
        na.rm = TRUE
      ),
      .groups = "drop"
    )

  suspected_domain_outlier_taxa <-
    data_domain_outlier_flags |>
    dplyr::filter(.data[["is_trait_outlier"]]) |>
    dplyr::pull(.data[["taxon_name"]]) |>
    base::unique()

  data_taxon_outlier_flags <-
    data_trait_records |>
    dplyr::group_by(
      .data[["trait_domain_name"]],
      .data[["taxon_name"]]
    ) |>
    flag_trait_outliers(
      trait_value_column = "trait_value",
      iqr_multiplier = taxon_iqr_multiplier,
      minimum_group_size = minimum_taxon_records
    )

  data_taxon_summary <-
    data_taxon_outlier_flags |>
    dplyr::filter(
      .data[["n_group_records"]] >= minimum_taxon_records
    ) |>
    dplyr::group_by(
      .data[["trait_domain_name"]],
      .data[["taxon_name"]]
    ) |>
    dplyr::summarise(
      n_records = dplyr::n(),
      mean = base::mean(.data[["trait_value"]], na.rm = TRUE),
      median = stats::median(.data[["trait_value"]], na.rm = TRUE),
      sd = stats::sd(.data[["trait_value"]], na.rm = TRUE),
      IQR = stats::IQR(.data[["trait_value"]], na.rm = TRUE),
      n_suspected_outliers_taxon = base::sum(
        .data[["is_trait_outlier"]],
        na.rm = TRUE
      ),
      .groups = "drop"
    )

  suspected_taxon_outlier_taxa <-
    data_taxon_outlier_flags |>
    dplyr::filter(.data[["is_trait_outlier"]]) |>
    dplyr::pull(.data[["taxon_name"]]) |>
    base::unique()

  report_date <-
    base::format(base::Sys.Date(), "%Y-%m-%d")

  if (
    base::is.null(path_trait_quality_control_report)
  ) {
    path_temporary_directory <-
      here::here("Data/Temp")

    if (
      !base::dir.exists(path_temporary_directory)
    ) {
      base::dir.create(
        path_temporary_directory,
        showWarnings = FALSE,
        recursive = TRUE
      )
    }

    path_trait_quality_control_report <-
      here::here(
        "Data/Temp",
        stringr::str_glue("trait_qc_report_{report_date}.csv")
      )
  }

  path_report_directory <-
    base::dirname(path_trait_quality_control_report)

  if (
    !base::dir.exists(path_report_directory)
  ) {
    base::dir.create(
      path = path_report_directory,
      showWarnings = FALSE,
      recursive = TRUE
    )
  }

  readr::write_csv(
    data_taxon_summary,
    path_trait_quality_control_report
  )

  if (
    !base::file.exists(path_trait_corrections)
  ) {
    data_corrections_template <-
      tibble::tibble(
        taxon_name = base::character(),
        trait_domain_name = base::character(),
        action = base::character(),
        scale_factor = base::numeric(),
        notes = base::character(),
        CHECKED = base::logical()
      )

    readr::write_csv(
      data_corrections_template,
      path_trait_corrections
    )
  }

  return(
    base::list(
      summary_by_domain = data_domain_summary,
      summary_by_domain_taxon = data_taxon_summary,
      suspected_outlier_taxa_domain = suspected_domain_outlier_taxa,
      suspected_outlier_taxa_taxon = suspected_taxon_outlier_taxa
    )
  )
}
