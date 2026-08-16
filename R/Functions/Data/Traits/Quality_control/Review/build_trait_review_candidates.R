#' @title Build Trait Review Candidates
#' @description
#' Builds an auditable taxon-by-domain review queue from within-taxon trait
#' outlier flags, objective invalid values, and optional source review keys.
#' Domain-level flags remain diagnostic and do not create candidates alone.
#' @param data_trait_records
#' Trait records containing `taxon_name`, `trait_domain_name`, and
#' `trait_value`.
#' @param data_source_candidates
#' Optional data frame containing `taxon_name`, `trait_domain_name`, and
#' `source_reference` from an external review source.
#' @param review_stage
#' Character scalar: either `"raw"` or `"classified"`.
#' @param domain_iqr_multiplier
#' Positive numeric domain-level IQR multiplier. Default: `3`.
#' @param taxon_iqr_multiplier
#' Positive numeric within-taxon IQR multiplier. Default: `1.5`.
#' @param minimum_taxon_records
#' Positive integer minimum group size. Default: `10L`.
#' @return
#' A tibble with one row per review candidate and a stable SHA-256
#' `candidate_id`.
#' @export
build_trait_review_candidates <- function(
    data_trait_records,
    data_source_candidates = NULL,
    review_stage = "raw",
    domain_iqr_multiplier = 3,
    taxon_iqr_multiplier = 1.5,
    minimum_taxon_records = 10L) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_records),
    msg = "'data_trait_records' must be a data frame."
  )
  required_record_columns <-
    base::c("taxon_name", "trait_domain_name", "trait_value")
  assertthat::assert_that(
    base::all(required_record_columns %in% base::names(data_trait_records)),
    msg = "Trait records are missing required review columns."
  )
  assertthat::assert_that(
    base::is.numeric(data_trait_records[["trait_value"]]),
    msg = "'trait_value' must be numeric."
  )
  assertthat::assert_that(
    base::is.character(review_stage) &&
      base::length(review_stage) == 1L &&
      review_stage %in% base::c("raw", "classified"),
    msg = "'review_stage' must be either 'raw' or 'classified'."
  )
  assertthat::assert_that(
    base::is.numeric(domain_iqr_multiplier) &&
      base::length(domain_iqr_multiplier) == 1L &&
      domain_iqr_multiplier > 0,
    msg = "'domain_iqr_multiplier' must be positive."
  )
  assertthat::assert_that(
    base::is.numeric(taxon_iqr_multiplier) &&
      base::length(taxon_iqr_multiplier) == 1L &&
      taxon_iqr_multiplier > 0,
    msg = "'taxon_iqr_multiplier' must be positive."
  )
  assertthat::assert_that(
    base::is.numeric(minimum_taxon_records) &&
      base::length(minimum_taxon_records) == 1L &&
      minimum_taxon_records >= 1,
    msg = "'minimum_taxon_records' must be positive."
  )

  data_records_for_review <-
    tibble::as_tibble(data_trait_records)
  if (!"trait_name" %in% base::names(data_records_for_review)) {
    data_records_for_review <-
      data_records_for_review |>
      dplyr::mutate(trait_name = NA_character_)
  }
  if (!"dataset_id" %in% base::names(data_records_for_review)) {
    data_records_for_review <-
      data_records_for_review |>
      dplyr::mutate(dataset_id = NA_integer_)
  }

  data_domain_flags <-
    data_records_for_review |>
    dplyr::group_by(.data[["trait_domain_name"]]) |>
    flag_trait_outliers(iqr_multiplier = domain_iqr_multiplier) |>
    dplyr::select("is_trait_outlier") |>
    dplyr::rename(is_domain_outlier = "is_trait_outlier")

  data_taxon_flags <-
    data_records_for_review |>
    dplyr::group_by(
      .data[["trait_domain_name"]],
      .data[["taxon_name"]]
    ) |>
    flag_trait_outliers(
      iqr_multiplier = taxon_iqr_multiplier,
      minimum_group_size = minimum_taxon_records
    ) |>
    dplyr::select("is_trait_outlier") |>
    dplyr::rename(is_taxon_outlier = "is_trait_outlier")

  data_record_summary <-
    data_records_for_review |>
    dplyr::bind_cols(data_domain_flags, data_taxon_flags) |>
    dplyr::group_by(
      .data[["taxon_name"]],
      .data[["trait_domain_name"]]
    ) |>
    dplyr::summarise(
      n_records = dplyr::n(),
      n_trait_names = dplyr::n_distinct(
        .data[["trait_name"]],
        na.rm = TRUE
      ),
      n_datasets = dplyr::n_distinct(
        .data[["dataset_id"]],
        na.rm = TRUE
      ),
      n_domain_outliers = base::sum(.data[["is_domain_outlier"]]),
      n_taxon_outliers = base::sum(.data[["is_taxon_outlier"]]),
      n_invalid_values = base::sum(
        !base::is.finite(.data[["trait_value"]]) |
          .data[["trait_value"]] <= 0,
        na.rm = TRUE
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::starts_with("n_"),
        base::as.integer
      )
    )

  data_automated_candidates <-
    data_record_summary |>
    dplyr::filter(
      .data[["n_taxon_outliers"]] > 0L |
        .data[["n_invalid_values"]] > 0L
    ) |>
    dplyr::select("taxon_name", "trait_domain_name")

  if (base::is.null(data_source_candidates)) {
    data_source_summary <-
      tibble::tibble(
        taxon_name = character(),
        trait_domain_name = character(),
        source_references = character()
      )
  } else {
    required_source_columns <-
      base::c("taxon_name", "trait_domain_name", "source_reference")
    assertthat::assert_that(
      base::is.data.frame(data_source_candidates) &&
        base::all(
          required_source_columns %in% base::names(data_source_candidates)
        ),
      msg = "Source candidates are missing required review columns."
    )
    data_source_summary <-
      data_source_candidates |>
      dplyr::group_by(
        .data[["taxon_name"]],
        .data[["trait_domain_name"]]
      ) |>
      dplyr::summarise(
        source_references = stringr::str_c(
          base::sort(base::unique(.data[["source_reference"]])),
          collapse = ";"
        ),
        .groups = "drop"
      )
  }

  data_candidate_keys <-
    dplyr::bind_rows(
      data_automated_candidates,
      data_source_summary |>
        dplyr::select("taxon_name", "trait_domain_name")
    ) |>
    dplyr::distinct()

  data_candidates <-
    data_candidate_keys |>
    dplyr::left_join(
      data_record_summary,
      by = base::c("taxon_name", "trait_domain_name")
    ) |>
    dplyr::left_join(
      data_source_summary,
      by = base::c("taxon_name", "trait_domain_name")
    ) |>
    dplyr::mutate(
      dplyr::across(
        dplyr::starts_with("n_"),
        ~ tidyr::replace_na(.x, 0L)
      ),
      source_references = tidyr::replace_na(
        .data[["source_references"]],
        ""
      ),
      candidate_reasons = stringr::str_c(
        dplyr::if_else(
          .data[["n_domain_outliers"]] > 0L,
          "domain_outlier;",
          ""
        ),
        dplyr::if_else(
          .data[["n_taxon_outliers"]] > 0L,
          "taxon_outlier;",
          ""
        ),
        dplyr::if_else(
          .data[["n_invalid_values"]] > 0L,
          "invalid_value;",
          ""
        ),
        dplyr::if_else(
          .data[["source_references"]] != "",
          "source_review;",
          ""
        )
      ) |>
        stringr::str_remove(";$"),
      review_stage = review_stage,
      candidate_key = stringr::str_c(
        .data[["review_stage"]],
        .data[["taxon_name"]],
        .data[["trait_domain_name"]],
        sep = "|"
      ),
      candidate_id = base::vapply(
        .data[["candidate_key"]],
        digest::digest,
        character(1L),
        algo = "sha256",
        serialize = FALSE
      )
    ) |>
    dplyr::arrange(
      .data[["trait_domain_name"]],
      .data[["taxon_name"]]
    ) |>
    dplyr::select(
      "candidate_id",
      "review_stage",
      "taxon_name",
      "trait_domain_name",
      "n_records",
      "n_trait_names",
      "n_datasets",
      "n_domain_outliers",
      "n_taxon_outliers",
      "n_invalid_values",
      "source_references",
      "candidate_reasons"
    )

  return(data_candidates)
}
