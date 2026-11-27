#' @title Save Trait Source Scale Report
#' @description
#' Writes a durable Markdown audit and source-domain-taxon count table for
#' the approved VegVault source-scaling rules of one VegVault release.
#' @param data_trait_source_scale_rule_audit
#' Rule-level audit from [apply_trait_source_scale_rules()].
#' @param data_trait_source_scale_record_audit
#' Record-level audit from [apply_trait_source_scale_rules()].
#' @param data_trait_review_application_audit
#' Review-layer application audit with `n_source_satisfied`.
#' @param vegvault_version
#' A single character string with the VegVault release the rules belong to
#' (the `vegvault_version` of the `config_vegvault_release` target).
#' @param path_report
#' Output path for the Markdown report.
#' @param path_taxon_counts
#' Output path for the source-domain-taxon count CSV.
#' @return
#' Character vector containing both written paths.
#' @details
#' When no approved rule applies, the rule-level audit has no rows and the
#' report states that the release has no approved source-scale rules. The
#' count table is then written with its header only.
#' @seealso [apply_trait_source_scale_rules()],
#'   [validate_trait_source_scale_rules()]
#' @export
save_trait_source_scale_report <- function(
    data_trait_source_scale_rule_audit,
    data_trait_source_scale_record_audit,
    data_trait_review_application_audit,
    vegvault_version,
    path_report,
    path_taxon_counts) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_source_scale_rule_audit),
    base::is.data.frame(data_trait_source_scale_record_audit),
    base::is.data.frame(data_trait_review_application_audit),
    msg = "Source-scale report inputs must be data frames."
  )
  assertthat::assert_that(
    base::is.character(vegvault_version) &&
      base::length(vegvault_version) == 1L &&
      !base::is.na(vegvault_version),
    msg = stringr::str_c(
      "'vegvault_version' must be a single non-missing character ",
      "string."
    )
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

  flag_has_rules <-
    base::nrow(data_trait_source_scale_rule_audit) > 0L

  if (
    flag_has_rules
  ) {
    vec_rule_lines <-
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
      knitr::kable(format = "pipe") |>
      base::as.character()
  } else {
    vec_rule_lines <-
      stringr::str_glue(
        "No approved source-scale rules for VegVault {vegvault_version}."
      )
  }

  vec_report_lines <-
    base::c(
      stringr::str_glue(
        "# VegVault {vegvault_version} source-scaling report"
      ),
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
        base::character()
      },
      "",
      "## Approved source rules",
      "",
      vec_rule_lines,
      "",
      "## Detailed counts",
      "",
      stringr::str_glue(
        "Counts by source, trait domain, and taxon are in ",
        "`{base::basename(path_taxon_counts)}`."
      ),
      "",
      "## Release guard",
      "",
      stringr::str_glue(
        "These rules apply to VegVault {vegvault_version} only. Another ",
        "release stops the pipeline until a rule set for that release ",
        "exists."
      )
    )
  readr::write_lines(vec_report_lines, path_report)

  return(base::c(path_report, path_taxon_counts))
}
