#' @title Apply Trait Source Scale Rules
#' @description
#' Applies approved whole-source scaling rules once and records each changed
#' trait value with its stable VegVault identifiers.
#' @param data_trait_records
#' Untouched trait records containing source and record identifiers.
#' @param data_trait_source_scale_rules
#' Validated source-scale rules.
#' @return
#' A named list with source-scaled records and rule- and record-level audits.
#' @export
apply_trait_source_scale_rules <- function(
    data_trait_records,
    data_trait_source_scale_rules) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_records),
    base::is.data.frame(data_trait_source_scale_rules),
    msg = "Trait records and source rules must be data frames."
  )
  record_id_columns <-
    base::c("dataset_id", "sample_id", "trait_id", "taxon_id")
  required_record_columns <-
    base::c(
      record_id_columns,
      "taxon_name",
      "data_source_id",
      "trait_domain_name",
      "trait_name",
      "trait_value"
    )
  required_rule_columns <-
    base::c(
      "source_scale_rule_id",
      "data_source_id",
      "trait_domain_name",
      "trait_name",
      "scale_factor",
      "review_status"
    )
  assertthat::assert_that(
    base::all(required_record_columns %in% base::names(data_trait_records)),
    base::all(
      required_rule_columns %in%
        base::names(data_trait_source_scale_rules)
    ),
    msg = "Trait records or source rules are missing required columns."
  )
  vec_record_keys <-
    data_trait_records |>
    dplyr::transmute(
      record_key = stringr::str_c(
        .data[["dataset_id"]],
        .data[["sample_id"]],
        .data[["trait_id"]],
        .data[["taxon_id"]],
        sep = "|"
      )
    ) |>
    dplyr::pull("record_key")
  assertthat::assert_that(
    !base::any(base::is.na(vec_record_keys)),
    !base::anyDuplicated(vec_record_keys),
    msg = "Source scaling requires unique record identifiers."
  )

  data_approved_rules <-
    data_trait_source_scale_rules |>
    dplyr::filter(.data[["review_status"]] == "approved")
  data_corrected <- data_trait_records
  rule_audit_rows <-
    base::vector("list", base::nrow(data_approved_rules))
  record_audit_rows <-
    base::vector("list", base::nrow(data_approved_rules))

  for (
    rule_index in base::seq_len(base::nrow(data_approved_rules))
  ) {
    rule <- data_approved_rules[rule_index, , drop = FALSE]
    is_match <-
      data_corrected[["data_source_id"]] ==
        rule[["data_source_id"]][[1L]] &
      data_corrected[["trait_domain_name"]] ==
        rule[["trait_domain_name"]][[1L]]
    trait_name <- rule[["trait_name"]][[1L]]
    if (
      !base::is.na(trait_name) && trait_name != ""
    ) {
      is_match <-
        is_match & data_corrected[["trait_name"]] == trait_name
    }
    is_match[base::is.na(is_match)] <- FALSE
    values_before <- data_corrected[["trait_value"]][is_match]
    scale_factor <- rule[["scale_factor"]][[1L]]
    values_after <- values_before * scale_factor
    data_corrected[["trait_value"]][is_match] <- values_after

    data_record_audit <-
      data_corrected[is_match, , drop = FALSE] |>
      dplyr::transmute(
        source_scale_rule_id =
          rule[["source_scale_rule_id"]][[1L]],
        dplyr::across(dplyr::all_of(record_id_columns)),
        taxon_name = .data[["taxon_name"]],
        data_source_id = .data[["data_source_id"]],
        trait_domain_name = .data[["trait_domain_name"]],
        trait_name = .data[["trait_name"]],
        trait_value_before = values_before,
        trait_value_after = values_after,
        scale_factor = scale_factor
      ) |>
      dplyr::mutate(
        source_scale_record_id = purrr::map_chr(
          vec_record_keys[is_match],
          ~ digest::digest(
            .x,
            algo = "sha256",
            serialize = FALSE
          )
        ),
        .before = 1L
      )
    record_audit_rows[[rule_index]] <- data_record_audit
    rule_audit_rows[[rule_index]] <-
      tibble::tibble(
        source_scale_rule_id =
          rule[["source_scale_rule_id"]][[1L]],
        data_source_id = rule[["data_source_id"]][[1L]],
        trait_domain_name = rule[["trait_domain_name"]][[1L]],
        trait_name = rule[["trait_name"]][[1L]],
        scale_factor = scale_factor,
        n_matched = base::as.integer(base::sum(is_match)),
        n_scaled = base::as.integer(base::sum(is_match)),
        value_min_before = base::min(values_before),
        value_max_before = base::max(values_before),
        value_min_after = base::min(values_after),
        value_max_after = base::max(values_after)
      )
  }

  data_rule_audit <- dplyr::bind_rows(rule_audit_rows)
  data_record_audit <- dplyr::bind_rows(record_audit_rows)
  return(
    base::list(
      data_trait_records_source_scaled = data_corrected,
      data_source_scale_rule_audit = data_rule_audit,
      data_source_scale_record_audit = data_record_audit
    )
  )
}
