#' @title Generate Trait QC Report
#' @description
#' Computes per-domain and per-domain×taxon summary statistics for raw
#' trait data and identifies suspected outlier taxa at two levels: a
#' lenient domain-level check and a stricter within-taxon check. Writes a
#' human-readable CSV report to `Data/Temp/` as a side effect. If the
#' corrections template file at `path_corrections` does not yet exist, a
#' header-only template is written there so a human can fill it in;
#' if the file already exists it is left untouched.
#' @param data_traits
#' A data frame in long format with at least the columns
#' `taxon_name`, `trait_domain_name`, `trait_name`, and
#' `trait_value`.
#' @param path_corrections
#' Character scalar. Path to `trait_manual_corrections.csv`.
#' Default: `here::here("Data/Input/trait_manual_corrections.csv")`.
#' @param path_qc_report
#' Character scalar or `NULL`. Optional path to the CSV QC report.
#' If `NULL` (default), the function writes a date-stamped file to
#' `Data/Temp/trait_qc_report_{YYYY-MM-DD}.csv`.
#' @param outlier_iqr_multiplier
#' Positive numeric scalar. A domain value is flagged as a suspected
#' outlier when `|trait_value - median| > outlier_iqr_multiplier * IQR`,
#' computed across all records in that domain regardless of taxon.
#' Default: `3`. The default follows Tukey's "extreme outlier" fence
#' (3 × IQR), which reliably catches unit mix-ups (e.g. mm vs. cm,
#' a 10 × scale difference) while remaining more conservative than
#' the classic 1.5 × whisker rule.
#' @param outlier_iqr_multiplier_taxon
#' Positive numeric scalar. The stricter IQR multiplier applied
#' within each taxon × domain group. A record is flagged when
#' `|trait_value - taxon_median| > outlier_iqr_multiplier_taxon * taxon_IQR`
#' and the taxon has at least `min_records_per_taxon` records in the domain.
#' Default: `1.5` (Tukey's standard whisker fence). This is tighter than
#' the domain-level `outlier_iqr_multiplier` because within-taxon
#' variability should be far smaller than cross-taxon variability;
#' any record deviating by more than 1.5 × the within-taxon IQR is
#' suspicious even when it is not an extreme cross-domain outlier.
#' @param min_records_per_taxon
#' Positive integer scalar. Minimum number of records a taxon must
#' have within a domain before the per-taxon IQR check is applied.
#' Taxa with fewer records are skipped at the taxon level (IQR cannot
#' be estimated reliably from very small samples). Default: `10L`.
#' @return
#' A named list with four elements:
#' \describe{
#'   \item{`summary_by_domain`}{A tibble with one row per
#'     `trait_domain_name` containing: `n_records`, `n_taxa`,
#'     `mean`, `median`, `sd`, `lwr_90`, `upr_90`, `IQR`,
#'     `n_suspected_outliers`.}
#'   \item{`summary_by_domain_taxon`}{A tibble with one row per
#'     `trait_domain_name × taxon_name` combination where the taxon
#'     has at least `min_records_per_taxon` records in that domain,
#'     containing: `n_records`, `mean`, `median`, `sd`, `IQR`,
#'     `n_suspected_outliers_taxon`.}
#'   \item{`suspected_outlier_taxa_domain`}{A character vector of taxon
#'     names whose trait value in any domain falls more than
#'     `outlier_iqr_multiplier` × IQR from the domain median
#'     (cross-taxon check).}
#'   \item{`suspected_outlier_taxa_taxon`}{A character vector of taxon
#'     names that have at least `min_records_per_taxon` records in a
#'     domain and whose trait value falls more than
#'     `outlier_iqr_multiplier_taxon` × IQR from their own taxon median
#'     (within-taxon check).}
#' }
#' @details
#' Two outlier detection levels are applied:
#' \enumerate{
#'   \item **Domain level** (`suspected_outlier_taxa_domain`): flags values
#'     where
#'     `|trait_value - domain_median| > outlier_iqr_multiplier * domain_IQR`
#'     (default 3, Tukey's extreme-outlier fence). Applied to all records.
#'   \item **Taxon level** (`suspected_outlier_taxa_taxon`): flags values
#'     where
#'     `|trait_value - taxon_median| > outlier_iqr_multiplier_taxon * taxon_IQR`
#'     (default 1.5, standard Tukey whisker). Applied only when the taxon
#'     has at least `min_records_per_taxon` records in the domain and when
#'     `taxon_IQR > 0`. This stricter check catches within-taxon
#'     inconsistencies that the cross-taxon check would miss.
#' }
#' The CSV report contains the per-domain×taxon summary. By default it is
#' written to `Data/Temp/trait_qc_report_{YYYY-MM-DD}.csv`, but an
#' explicit `path_qc_report` can be supplied when the caller needs an
#' isolated output location. The corrections template written when absent
#' contains the columns: `taxon_name`, `trait_domain_name`, `action`,
#' `scale_factor`, `notes`, `CHECKED`.
#' @examples
#' data_traits <-
#'   tibble::tibble(
#'     taxon_name = base::rep("Quercus", 12L),
#'     trait_domain_name = base::rep("SLA", 12L),
#'     trait_name = base::rep("LMA", 12L),
#'     trait_value = base::seq(10, 21, by = 1)
#'   )
#'
#' path_corrections <-
#'   base::tempfile(fileext = ".csv")
#'
#' path_qc_report <-
#'   base::tempfile(fileext = ".csv")
#'
#' generate_trait_qc_report(
#'   data_traits = data_traits,
#'   path_corrections = path_corrections,
#'   path_qc_report = path_qc_report
#' )
#'
#' generate_trait_qc_report(
#'   data_traits = data_traits,
#'   path_corrections = path_corrections
#' )
#' @seealso [validate_trait_corrections()], [apply_trait_corrections()]
#' @export
generate_trait_qc_report <- function(
    data_traits,
    path_corrections = here::here(
      "Data/Input/trait_manual_corrections.csv"
    ),
    path_qc_report = NULL,
    outlier_iqr_multiplier = 3,
    outlier_iqr_multiplier_taxon = 1.5,
    min_records_per_taxon = 10L) {
  assertthat::assert_that(
    base::is.data.frame(data_traits),
    msg = "data_traits must be a data frame."
  )

  vec_required_cols <-
    base::c("taxon_name", "trait_domain_name", "trait_name", "trait_value")

  assertthat::assert_that(
    base::all(vec_required_cols %in% base::colnames(data_traits)),
    msg = base::paste0(
      "data_traits is missing required columns: ",
      base::paste(
        base::setdiff(vec_required_cols, base::colnames(data_traits)),
        collapse = ", "
      )
    )
  )

  assertthat::assert_that(
    base::is.character(path_corrections),
    msg = "path_corrections must be a character string."
  )

  assertthat::assert_that(
    base::length(path_corrections) == 1L,
    msg = "path_corrections must be a scalar (length 1)."
  )

  assertthat::assert_that(
    base::is.null(path_qc_report) || base::is.character(path_qc_report),
    msg = "path_qc_report must be NULL or a character string."
  )

  if (
    !base::is.null(path_qc_report)
  ) {
    assertthat::assert_that(
      base::length(path_qc_report) == 1L,
      msg = "path_qc_report must be a scalar (length 1)."
    )
  }

  assertthat::assert_that(
    base::is.numeric(outlier_iqr_multiplier),
    msg = "outlier_iqr_multiplier must be numeric."
  )

  assertthat::assert_that(
    base::length(outlier_iqr_multiplier) == 1L,
    msg = "outlier_iqr_multiplier must be a scalar (length 1)."
  )

  assertthat::assert_that(
    outlier_iqr_multiplier > 0,
    msg = "outlier_iqr_multiplier must be positive."
  )

  assertthat::assert_that(
    base::is.numeric(outlier_iqr_multiplier_taxon),
    msg = "outlier_iqr_multiplier_taxon must be numeric."
  )

  assertthat::assert_that(
    base::length(outlier_iqr_multiplier_taxon) == 1L,
    msg = "outlier_iqr_multiplier_taxon must be a scalar (length 1)."
  )

  assertthat::assert_that(
    outlier_iqr_multiplier_taxon > 0,
    msg = "outlier_iqr_multiplier_taxon must be positive."
  )

  assertthat::assert_that(
    base::is.numeric(min_records_per_taxon),
    msg = "min_records_per_taxon must be numeric."
  )

  assertthat::assert_that(
    base::length(min_records_per_taxon) == 1L,
    msg = "min_records_per_taxon must be a scalar (length 1)."
  )

  assertthat::assert_that(
    min_records_per_taxon >= 1,
    msg = "min_records_per_taxon must be at least 1."
  )

  # Compute per-domain stats with outlier flags
  data_with_outlier_flag <-
    data_traits |>
    dplyr::group_by(trait_domain_name) |>
    add_iqr_outlier_flag(
      col_value = "trait_value",
      multiplier = outlier_iqr_multiplier
    )

  data_summary <-
    data_with_outlier_flag |>
    dplyr::group_by(trait_domain_name) |>
    dplyr::summarize(
      n_records = dplyr::n(),
      n_taxa = dplyr::n_distinct(taxon_name),
      mean = base::mean(trait_value, na.rm = TRUE),
      median = stats::median(trait_value, na.rm = TRUE),
      sd = stats::sd(trait_value, na.rm = TRUE),
      lwr_90 = stats::quantile(trait_value, probs = 0.05, na.rm = TRUE),
      upr_90 = stats::quantile(trait_value, probs = 0.95, na.rm = TRUE),
      IQR = stats::IQR(trait_value, na.rm = TRUE),
      n_suspected_outliers = base::sum(is_outlier, na.rm = TRUE),
      .groups = "drop"
    )

  vec_outlier_taxa_domain <-
    data_with_outlier_flag |>
    dplyr::filter(is_outlier) |>
    dplyr::pull(taxon_name) |>
    base::unique()

  # Compute per-domain x taxon stats with stricter outlier flags.
  # Applied only when n_group >= min_records_per_taxon and IQR > 0
  # (IQR = 0 means all values are identical; no meaningful outlier).
  data_with_taxon_outlier_flag <-
    data_traits |>
    dplyr::group_by(trait_domain_name, taxon_name) |>
    add_iqr_outlier_flag(
      col_value = "trait_value",
      multiplier = outlier_iqr_multiplier_taxon,
      min_n = min_records_per_taxon
    )

  data_summary_taxon <-
    data_with_taxon_outlier_flag |>
    dplyr::filter(n_group >= min_records_per_taxon) |>
    dplyr::group_by(trait_domain_name, taxon_name) |>
    dplyr::summarize(
      n_records = dplyr::n(),
      mean = base::mean(trait_value, na.rm = TRUE),
      median = stats::median(trait_value, na.rm = TRUE),
      sd = stats::sd(trait_value, na.rm = TRUE),
      IQR = stats::IQR(trait_value, na.rm = TRUE),
      n_suspected_outliers_taxon = base::sum(is_outlier, na.rm = TRUE),
      .groups = "drop"
    )

  vec_outlier_taxa_taxon <-
    data_with_taxon_outlier_flag |>
    dplyr::filter(is_outlier) |>
    dplyr::pull(taxon_name) |>
    base::unique()

  # Write QC report to Data/Temp/
  str_date <-
    base::format(base::Sys.Date(), "%Y-%m-%d")

  if (
    base::is.null(path_qc_report)
  ) {
    path_temp_dir <-
      here::here("Data/Temp")

    if (
      !base::dir.exists(path_temp_dir)
    ) {
      base::dir.create(path_temp_dir, showWarnings = FALSE, recursive = TRUE)
    }

    path_qc_report <-
      here::here(
        "Data/Temp",
        base::paste0("trait_qc_report_", str_date, ".csv")
      )
  }

  path_qc_report_dir <-
    base::dirname(path_qc_report)

  if (
    !base::dir.exists(path_qc_report_dir)
  ) {
    base::dir.create(
      path = path_qc_report_dir,
      showWarnings = FALSE,
      recursive = TRUE
    )
  }

  readr::write_csv(data_summary_taxon, path_qc_report)

  # Write corrections template if it does not already exist
  if (
    !base::file.exists(path_corrections)
  ) {
    data_template <-
      tibble::tibble(
        taxon_name = base::character(),
        trait_domain_name = base::character(),
        action = base::character(),
        scale_factor = base::numeric(),
        notes = base::character(),
        CHECKED = base::logical()
      )

    readr::write_csv(data_template, path_corrections)
  }

  return(
    base::list(
      summary_by_domain = data_summary,
      summary_by_domain_taxon = data_summary_taxon,
      suspected_outlier_taxa_domain = vec_outlier_taxa_domain,
      suspected_outlier_taxa_taxon = vec_outlier_taxa_taxon
    )
  )
}
