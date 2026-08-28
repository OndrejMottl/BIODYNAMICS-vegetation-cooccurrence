#' @title Save Trait Source Scale Report
#' @description
#' Writes a durable Markdown audit and source-domain-taxon count table for
#' interim VegVault source scaling, including the provisional TRY LMA warning.
#' @param data_trait_records_raw
#' Untouched extracted trait records.
#' @param data_trait_records_source_scaled
#' Records after approved source scaling.
#' @param data_trait_source_scale_rule_audit
#' Rule-level audit from [apply_trait_source_scale_rules()].
#' @param data_trait_source_scale_record_audit
#' Record-level audit from [apply_trait_source_scale_rules()].
#' @param data_trait_review_application_audit
#' Review-layer application audit with `n_source_satisfied`.
#' @param path_vegvault
#' Character scalar path to the VegVault SQLite database.
#' @param path_report
#' Output path for the Markdown report.
#' @param path_taxon_counts
#' Output path for the source-domain-taxon count CSV.
#' @return
#' Character vector containing both written paths.
#' @export
save_trait_source_scale_report <- function(
    data_trait_records_raw,
    data_trait_records_source_scaled,
    data_trait_source_scale_rule_audit,
    data_trait_source_scale_record_audit,
    data_trait_review_application_audit,
    path_vegvault,
    path_report,
    path_taxon_counts) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_records_raw),
    base::is.data.frame(data_trait_records_source_scaled),
    base::is.data.frame(data_trait_source_scale_rule_audit),
    base::is.data.frame(data_trait_source_scale_record_audit),
    base::is.data.frame(data_trait_review_application_audit),
    base::file.exists(path_vegvault),
    msg = "Source-scale report inputs are invalid."
  )
  base::dir.create(
    base::dirname(path_report),
    recursive = TRUE,
    showWarnings = FALSE
  )
  base::dir.create(
    base::dirname(path_taxon_counts),
    recursive = TRUE,
    showWarnings = FALSE
  )

  connection_vegvault <-
    DBI::dbConnect(RSQLite::SQLite(), path_vegvault)
  base::on.exit(
    DBI::dbDisconnect(connection_vegvault),
    add = TRUE
  )
  vec_try_source_ids <-
    DBI::dbGetQuery(
      connection_vegvault,
      paste0(
        "SELECT DISTINCT data_source_id FROM Datasets ",
        "WHERE data_source_type_id = 4"
      )
    )[["data_source_id"]]
  raw_is_try_lma <-
    data_trait_records_raw[["data_source_id"]] %in%
      vec_try_source_ids &
    data_trait_records_raw[["trait_domain_name"]] ==
      "Leaf mass per area"
  scaled_is_try_lma <-
    data_trait_records_source_scaled[["data_source_id"]] %in%
      vec_try_source_ids &
    data_trait_records_source_scaled[["trait_domain_name"]] ==
      "Leaf mass per area"
  vec_raw_try_lma <-
    data_trait_records_raw[["trait_value"]][raw_is_try_lma]
  vec_scaled_try_lma <-
    data_trait_records_source_scaled[["trait_value"]][scaled_is_try_lma]
  assertthat::assert_that(
    base::identical(vec_raw_try_lma, vec_scaled_try_lma),
    msg = "TRY-derived Leaf mass per area changed during source scaling."
  )

  data_taxon_counts <-
    data_trait_source_scale_record_audit |>
    dplyr::count(
      .data[["data_source_id"]],
      .data[["trait_domain_name"]],
      .data[["taxon_name"]],
      name = "n_scaled_records"
    ) |>
    dplyr::arrange(
      .data[["data_source_id"]],
      .data[["trait_domain_name"]],
      .data[["taxon_name"]]
    )
  readr::write_csv(data_taxon_counts, path_taxon_counts)

  n_source_scaled <-
    base::nrow(data_trait_source_scale_record_audit)
  n_review_deduplicated <-
    base::sum(
      data_trait_review_application_audit[["n_source_satisfied"]]
    )
  if (
    "n_scaled" %in%
      base::names(data_trait_review_application_audit)
  ) {
    n_residual_review_scaled <-
      base::sum(data_trait_review_application_audit[["n_scaled"]])
    n_uniquely_scaled <- n_source_scaled + n_residual_review_scaled
  } else {
    n_residual_review_scaled <- NA_integer_
    n_uniquely_scaled <- NA_integer_
  }
  rule_table <-
    data_trait_source_scale_rule_audit |>
    dplyr::select(
      "data_source_id",
      "trait_domain_name",
      "scale_factor",
      "n_scaled",
      "value_min_before",
      "value_max_before",
      "value_min_after",
      "value_max_after"
    ) |>
    knitr::kable(format = "pipe")
  vec_report_lines <-
    base::c(
      "# Interim VegVault source-scaling report",
      "",
      "## Status",
      "",
      stringr::str_glue(
        "Approved source rules scaled ",
        "{scales::comma(n_source_scaled, accuracy = 1)} records."
      ),
      "",
      stringr::str_glue(
        "The review layer recognized ",
        "{scales::comma(n_review_deduplicated, accuracy = 1)} ",
        "review-layer matches as already satisfied by source scaling."
      ),
      "",
      if (
        base::is.finite(n_residual_review_scaled)
      ) {
        stringr::str_glue(
          "Approved residual taxon rules scaled ",
          "{scales::comma(n_residual_review_scaled, accuracy = 1)} ",
          "additional records, yielding ",
          "{scales::comma(n_uniquely_scaled, accuracy = 1)} ",
          "uniquely scaled records overall."
        )
      } else {
        character()
      },
      "",
      "## Approved source rules",
      "",
      rule_table,
      "",
      "## Provisional Leaf mass per area warning",
      "",
      stringr::str_glue(
        "**PROVISIONAL:** All ",
        "{scales::comma(base::length(vec_raw_try_lma), accuracy = 1)} ",
        "TRY-derived ",
        "Leaf mass per area records remain unchanged because their original ",
        "units have not been reconstructed. They remain available only as ",
        "an interim input pending the corrected VegVault release."
      ),
      "",
      "## Detailed counts",
      "",
      stringr::str_glue(
        "Counts by source, trait domain, and taxon are in ",
        "`{base::basename(path_taxon_counts)}`."
      ),
      "",
      "## Retirement guard",
      "",
      stringr::str_c(
        "These compatibility rules are version-bound. A VegVault release ",
        "other than 1.0.0 must fail validation until the rules are ",
        "explicitly removed or replaced."
      )
    )
  readr::write_lines(vec_report_lines, path_report)

  return(base::c(path_report, path_taxon_counts))
}
