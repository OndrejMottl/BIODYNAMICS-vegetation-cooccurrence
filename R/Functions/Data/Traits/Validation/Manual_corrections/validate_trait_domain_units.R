#' @title Validate Trait Domain Units
#' @description
#' Fails closed unless the reviewed trait-domain unit table is approved,
#' belongs to the VegVault release and build the pipeline reads, matches the
#' units of `TraitsDomain` exactly, and every trait record has the unit of
#' its domain and a VegVault unit rule.
#' @param data_trait_domain_units
#' The unit table loaded by [load_trait_domain_units()].
#' @param data_trait_records
#' Extracted trait records with `trait_domain_name`, `trait_unit`,
#' `conversion_rule_key`, and `derivation_rule_key`.
#' @param path_vegvault
#' Character scalar path to the VegVault SQLite database.
#' @param data_vegvault_release
#' A one-row data frame with the VegVault release record the pipeline
#' built from the same file (the `config_vegvault_release` target), as
#' returned by [load_vegvault_database_version()].
#' @return
#' The validated unit table, unchanged.
#' @details
#' The function stops with an error unless:
#'
#'   1. every row is `approved` and names a reviewer and an ISO review date;
#'   2. every row names the release version and its build reference, the
#'      `manifest_sha256` of `data_vegvault_release`;
#'   3. each domain appears once, the domains are exactly those of
#'      `TraitsDomain`, and each unit is exactly the `TraitsDomain` unit;
#'   4. `evidence_status` is `source_standardised` or `source_derived`, and
#'      `included_in_primary` is `TRUE` or `FALSE`;
#'   5. every record belongs to a listed domain and has exactly its unit,
#'      with no `NA`;
#'   6. every record carries a conversion or a derivation rule key.
#'
#' [validate_vegvault_release()] first confirms that the file holds the
#' release in `data_vegvault_release`; `TraitsDomain` is then read with a
#' read-only connection.
#' @seealso [load_trait_domain_units()], [validate_vegvault_release()]
#' @export
validate_trait_domain_units <- function(
    data_trait_domain_units,
    data_trait_records,
    path_vegvault,
    data_vegvault_release) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_domain_units),
    base::is.data.frame(data_trait_records),
    msg = "Trait domain units and trait records must be data frames."
  )
  assertthat::assert_that(
    base::is.character(path_vegvault) &&
      base::length(path_vegvault) == 1L &&
      base::file.exists(path_vegvault),
    msg = "'path_vegvault' must identify one existing file."
  )

  vec_text_columns <-
    base::c(
      "vegvault_version",
      "vegvault_build_reference",
      "trait_domain_name",
      "trait_unit",
      "evidence_status",
      "rationale",
      "evidence_reference",
      "review_status",
      "reviewer",
      "reviewed_at"
    )
  vec_record_columns <-
    base::c(
      "trait_domain_name",
      "trait_unit",
      "conversion_rule_key",
      "derivation_rule_key"
    )
  assertthat::assert_that(
    base::all(
      base::c(vec_text_columns, "included_in_primary") %in%
        base::names(data_trait_domain_units)
    ),
    base::all(vec_record_columns %in% base::names(data_trait_records)),
    msg = "Trait domain units or trait records are missing required columns."
  )

  validate_vegvault_release(
    path_to_vegvault = path_vegvault,
    data_vegvault_release = data_vegvault_release
  )

  # 1. Text cells -----
  has_edge_whitespace <-
    data_trait_domain_units[vec_text_columns] |>
    purrr::map_lgl(
      .f = ~ base::any(
        !base::is.na(.x) & .x != stringr::str_trim(.x)
      )
    )

  if (
    base::any(has_edge_whitespace)
  ) {
    cli::cli_abort("Trait domain units contain edge whitespace.")
  }

  vec_required_text_columns <-
    base::setdiff(vec_text_columns, base::c("reviewer", "reviewed_at"))
  has_missing_text <-
    data_trait_domain_units[vec_required_text_columns] |>
    purrr::map_lgl(
      .f = ~ base::any(base::is.na(.x) | .x == "")
    )

  if (
    base::any(has_missing_text)
  ) {
    cli::cli_abort("Required trait domain unit text cannot be blank.")
  }

  # 2. Review state -----
  if (
    base::any(data_trait_domain_units[["review_status"]] != "approved")
  ) {
    cli::cli_abort(
      c(
        "Every trait domain unit row must be approved.",
        "i" = "Set {.field review_status} to {.val approved} after review."
      )
    )
  }

  vec_reviewer <- data_trait_domain_units[["reviewer"]]
  vec_reviewed_at <- data_trait_domain_units[["reviewed_at"]]
  is_invalid_review <-
    base::is.na(vec_reviewer) |
    vec_reviewer == "" |
    base::is.na(vec_reviewed_at) |
    !stringr::str_detect(
      vec_reviewed_at,
      "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"
    ) |
    base::is.na(
      base::as.Date(vec_reviewed_at, format = "%Y-%m-%d")
    )
  is_invalid_review[base::is.na(is_invalid_review)] <- TRUE

  if (
    base::any(is_invalid_review)
  ) {
    cli::cli_abort(
      "Approved trait domain units require a reviewer and a review date."
    )
  }

  # 3. Status vocabulary -----
  vec_allowed_statuses <-
    base::c("source_standardised", "source_derived")

  if (
    base::any(
      !data_trait_domain_units[["evidence_status"]] %in%
        vec_allowed_statuses
    )
  ) {
    cli::cli_abort(
      c(
        "A trait domain evidence status is not recognised.",
        "i" = "Allowed: {.val {vec_allowed_statuses}}."
      )
    )
  }

  assertthat::assert_that(
    base::is.logical(data_trait_domain_units[["included_in_primary"]]),
    !base::anyNA(data_trait_domain_units[["included_in_primary"]]),
    msg = "'included_in_primary' must be TRUE or FALSE in every row."
  )

  # 4. Release and build -----
  release_version <- data_vegvault_release[["vegvault_version"]][[1L]]
  release_build <- data_vegvault_release[["manifest_sha256"]][[1L]]

  if (
    base::any(
      data_trait_domain_units[["vegvault_version"]] != release_version
    )
  ) {
    cli::cli_abort(
      c(
        "Trait domain units must name the VegVault release.",
        "i" = "The release is {.val {release_version}}."
      )
    )
  }

  if (
    base::is.na(release_build) ||
      base::any(
        data_trait_domain_units[["vegvault_build_reference"]] !=
          release_build
      )
  ) {
    cli::cli_abort(
      c(
        "Trait domain units must name the build of the VegVault release.",
        "i" = stringr::str_c(
          "The build reference is the {.field manifest_sha256} of ",
          "the release record."
        )
      )
    )
  }

  # 5. TraitsDomain -----
  if (
    base::anyDuplicated(data_trait_domain_units[["trait_domain_name"]]) >
      0L
  ) {
    cli::cli_abort("Each trait domain must appear once in the unit table.")
  }

  connection_vegvault <-
    DBI::dbConnect(
      drv = RSQLite::SQLite(),
      dbname = path_vegvault,
      flags = RSQLite::SQLITE_RO
    )
  base::on.exit(
    DBI::dbDisconnect(connection_vegvault),
    add = TRUE
  )

  data_traits_domain <-
    DBI::dbGetQuery(
      connection_vegvault,
      "SELECT trait_domain_name, trait_unit FROM TraitsDomain"
    )

  if (
    !base::setequal(
      data_trait_domain_units[["trait_domain_name"]],
      data_traits_domain[["trait_domain_name"]]
    ) ||
      base::anyDuplicated(data_traits_domain[["trait_domain_name"]]) > 0L
  ) {
    cli::cli_abort(
      "The unit table must list exactly the domains of TraitsDomain."
    )
  }

  vec_database_units <-
    data_traits_domain[["trait_unit"]][
      base::match(
        data_trait_domain_units[["trait_domain_name"]],
        data_traits_domain[["trait_domain_name"]]
      )
    ]
  is_unit_mismatch <-
    base::is.na(vec_database_units) |
    vec_database_units != data_trait_domain_units[["trait_unit"]]

  if (
    base::any(is_unit_mismatch)
  ) {
    cli::cli_abort(
      c(
        "The unit table must match the units of TraitsDomain.",
        "x" = stringr::str_c(
          "Differs for: ",
          "{.val {data_trait_domain_units[['trait_domain_name']][",
          "is_unit_mismatch]}}."
        )
      )
    )
  }

  # 6. Records -----
  vec_expected_units <-
    data_trait_domain_units[["trait_unit"]][
      base::match(
        data_trait_records[["trait_domain_name"]],
        data_trait_domain_units[["trait_domain_name"]]
      )
    ]
  is_record_unit_mismatch <-
    base::is.na(vec_expected_units) |
    base::is.na(data_trait_records[["trait_unit"]]) |
    vec_expected_units != data_trait_records[["trait_unit"]]

  if (
    base::any(is_record_unit_mismatch)
  ) {
    cli::cli_abort(
      c(
        "Every trait record must have the unit of its domain.",
        "x" = "{base::sum(is_record_unit_mismatch)} record{?s} differ."
      )
    )
  }

  is_without_rule <-
    base::is.na(data_trait_records[["conversion_rule_key"]]) &
    base::is.na(data_trait_records[["derivation_rule_key"]])

  if (
    base::any(is_without_rule)
  ) {
    cli::cli_abort(
      c(
        "Every trait record must carry a conversion or derivation rule.",
        "x" = "{base::sum(is_without_rule)} record{?s} carry neither."
      )
    )
  }

  return(data_trait_domain_units)
}
