#' @title Validate Trait Source Scale Rules
#' @description
#' Fails closed unless source-scale rules match the active VegVault version,
#' source metadata, selectors, and expected record counts exactly.
#' @param data_trait_source_scale_rules
#' Rules loaded by [load_trait_source_scale_rules()].
#' @param data_trait_records
#' Untouched extracted trait records containing `data_source_id`.
#' @param path_vegvault
#' Character scalar path to the VegVault SQLite database.
#' @return
#' The validated source-scale rule tibble.
#' @export
validate_trait_source_scale_rules <- function(
    data_trait_source_scale_rules,
    data_trait_records,
    path_vegvault) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_source_scale_rules),
    base::is.data.frame(data_trait_records),
    base::is.character(path_vegvault),
    base::length(path_vegvault) == 1L,
    base::file.exists(path_vegvault),
    msg = "Source rules, records, and VegVault path are invalid."
  )
  rule_columns <-
    base::c(
      "source_scale_rule_id",
      "vegvault_version",
      "data_source_id",
      "expected_data_source_desc",
      "trait_domain_name",
      "trait_name",
      "scale_factor",
      "expected_match_count",
      "rationale",
      "evidence_reference",
      "review_status",
      "reviewer",
      "reviewed_at"
    )
  record_columns <-
    base::c(
      "data_source_id",
      "trait_domain_name",
      "trait_value"
    )
  assertthat::assert_that(
    base::all(rule_columns %in% base::names(data_trait_source_scale_rules)),
    base::all(record_columns %in% base::names(data_trait_records)),
    msg = "Source-scale inputs are missing required columns."
  )

  character_columns <-
    base::c(
      "source_scale_rule_id",
      "vegvault_version",
      "expected_data_source_desc",
      "trait_domain_name",
      "trait_name",
      "rationale",
      "evidence_reference",
      "review_status",
      "reviewer",
      "reviewed_at"
    )
  has_edge_whitespace <-
    base::vapply(
      data_trait_source_scale_rules[character_columns],
      function(column_value) {
        base::any(
          !base::is.na(column_value) &
            column_value != stringr::str_trim(column_value),
          na.rm = TRUE
        )
      },
      logical(1L)
    )
  if (
    base::any(has_edge_whitespace)
  ) {
    cli::cli_abort("Trait source scale rules contain edge whitespace.")
  }

  required_text_columns <-
    base::c(
      "source_scale_rule_id",
      "vegvault_version",
      "expected_data_source_desc",
      "trait_domain_name",
      "rationale",
      "evidence_reference",
      "review_status"
    )
  has_missing_text <-
    base::vapply(
      data_trait_source_scale_rules[required_text_columns],
      function(column_value) {
        base::any(base::is.na(column_value) | column_value == "")
      },
      logical(1L)
    )
  if (
    base::any(has_missing_text)
  ) {
    cli::cli_abort("Required source-scale rule text cannot be blank.")
  }

  allowed_statuses <- base::c("proposed", "approved", "rejected")
  if (
    base::any(
      !data_trait_source_scale_rules[["review_status"]] %in%
        allowed_statuses
    )
  ) {
    cli::cli_abort("Source-scale review status is invalid.")
  }
  needs_human_metadata <-
    data_trait_source_scale_rules[["review_status"]] %in%
      base::c("approved", "rejected")
  reviewer <- data_trait_source_scale_rules[["reviewer"]]
  reviewed_at <- data_trait_source_scale_rules[["reviewed_at"]]
  invalid_human_metadata <-
    needs_human_metadata &
    (
      base::is.na(reviewer) |
        reviewer == "" |
        base::is.na(reviewed_at) |
        !stringr::str_detect(reviewed_at, "^\\d{4}-\\d{2}-\\d{2}$") |
        base::is.na(
          base::suppressWarnings(base::as.Date(reviewed_at))
        )
    )
  if (
    base::any(invalid_human_metadata)
  ) {
    cli::cli_abort(
      "Human-reviewed source rules require reviewer and review date."
    )
  }
  if (
    base::any(
      base::is.na(data_trait_source_scale_rules[["scale_factor"]]) |
        !base::is.finite(
          data_trait_source_scale_rules[["scale_factor"]]
        ) |
        data_trait_source_scale_rules[["scale_factor"]] <= 0
    )
  ) {
    cli::cli_abort("Source rules require a positive finite scale factor.")
  }
  if (
    base::any(
      base::is.na(
        data_trait_source_scale_rules[["expected_match_count"]]
      ) |
        data_trait_source_scale_rules[["expected_match_count"]] <= 0L
    )
  ) {
    cli::cli_abort("Source rules require a positive expected count.")
  }

  connection_vegvault <-
    DBI::dbConnect(RSQLite::SQLite(), path_vegvault)
  base::on.exit(
    DBI::dbDisconnect(connection_vegvault),
    add = TRUE
  )
  data_current_version <-
    DBI::dbGetQuery(
      connection_vegvault,
      paste0(
        "SELECT version FROM version_control ",
        "ORDER BY date(update_date) DESC, id DESC LIMIT 1"
      )
    )
  assertthat::assert_that(
    base::nrow(data_current_version) == 1L,
    msg = "VegVault must contain exactly one latest version entry."
  )
  current_version <- data_current_version[["version"]][[1L]]
  if (
    base::any(
      data_trait_source_scale_rules[["vegvault_version"]] !=
        current_version
    )
  ) {
    cli::cli_abort(
      "Source-scale rule version does not match the current VegVault version."
    )
  }
  data_source_lookup <-
    DBI::dbGetQuery(
      connection_vegvault,
      "SELECT data_source_id, data_source_desc FROM DatasetSourcesID"
    )
  source_index <-
    base::match(
      data_trait_source_scale_rules[["data_source_id"]],
      data_source_lookup[["data_source_id"]]
    )
  invalid_source <-
    base::is.na(source_index) |
    data_trait_source_scale_rules[["expected_data_source_desc"]] !=
      data_source_lookup[["data_source_desc"]][source_index]
  if (
    base::any(invalid_source)
  ) {
    cli::cli_abort(
      "A source-scale rule does not match the exact source description."
    )
  }

  valid_hash <- "^[0-9a-f]{64}$"
  if (
    base::any(
      !stringr::str_detect(
        data_trait_source_scale_rules[["source_scale_rule_id"]],
        valid_hash
      )
    ) ||
      base::anyDuplicated(
        data_trait_source_scale_rules[["source_scale_rule_id"]]
      ) > 0L
  ) {
    cli::cli_abort("Source-scale rule identifiers must be unique hashes.")
  }
  vec_rule_keys <-
    stringr::str_c(
      data_trait_source_scale_rules[["vegvault_version"]],
      data_trait_source_scale_rules[["data_source_id"]],
      data_trait_source_scale_rules[["trait_domain_name"]],
      tidyr::replace_na(
        data_trait_source_scale_rules[["trait_name"]],
        ""
      ),
      data_trait_source_scale_rules[["scale_factor"]],
      sep = "|"
    )
  vec_expected_hashes <-
    purrr::map_chr(
      vec_rule_keys,
      ~ digest::digest(
        .x,
        algo = "sha256",
        serialize = FALSE
      )
    )
  if (
    !base::identical(
      data_trait_source_scale_rules[["source_scale_rule_id"]],
      vec_expected_hashes
    )
  ) {
    cli::cli_abort("Source-scale rule hashes do not match their contract.")
  }

  matched_record_ids <-
    base::vector(
      "list",
      base::nrow(data_trait_source_scale_rules)
    )
  for (
    rule_index in
      base::seq_len(base::nrow(data_trait_source_scale_rules))
  ) {
    rule <-
      data_trait_source_scale_rules[rule_index, , drop = FALSE]
    is_match <-
      data_trait_records[["data_source_id"]] ==
        rule[["data_source_id"]][[1L]] &
      data_trait_records[["trait_domain_name"]] ==
        rule[["trait_domain_name"]][[1L]]
    trait_name <- rule[["trait_name"]][[1L]]
    if (
      !base::is.na(trait_name) && trait_name != ""
    ) {
      assertthat::assert_that(
        "trait_name" %in% base::names(data_trait_records),
        msg = "A source trait-name selector cannot match records."
      )
      is_match <-
        is_match & data_trait_records[["trait_name"]] == trait_name
    }
    is_match[base::is.na(is_match)] <- FALSE
    matched_record_ids[[rule_index]] <- base::which(is_match)
  }
  vec_match_counts <- base::lengths(matched_record_ids)
  if (
    base::any(vec_match_counts == 0L)
  ) {
    cli::cli_abort("Every source-scale rule must match current records.")
  }
  if (
    base::any(
      vec_match_counts !=
        data_trait_source_scale_rules[["expected_match_count"]]
    )
  ) {
    cli::cli_abort("A source-scale rule has an unexpected count.")
  }
  approved_rules <-
    data_trait_source_scale_rules[["review_status"]] == "approved"
  approved_record_ids <-
    base::unlist(matched_record_ids[approved_rules])
  if (
    base::anyDuplicated(approved_record_ids) > 0L
  ) {
    cli::cli_abort("Approved source-scale rules overlap.")
  }

  return(data_trait_source_scale_rules)
}
