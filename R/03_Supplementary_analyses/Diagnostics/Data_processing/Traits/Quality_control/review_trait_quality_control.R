#----------------------------------------------------------#
#
#                 Vegetation Co-occurrence
#
#      Trait quality-control interactive review tool
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# This tool inspects exact trait-name, dataset, and value selectors and
# can append proposed decisions. It never writes an approved decision.


#----------------------------------------------------------#
# 0. Setup and reviewer inputs -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

Sys.setenv(R_CONFIG_ACTIVE = "project_traits_reference")

review_stage <- "raw"
focal_candidate_id <- NULL
proposed_action <- "none"
proposed_trait_name <- ""
proposed_dataset_id <- NA_integer_
proposed_value_lower <- NA_real_
proposed_value_lower_inclusive <- NA
proposed_value_upper <- NA_real_
proposed_value_upper_inclusive <- NA
proposed_scale_factor <- NA_real_
proposed_rationale <- ""
proposed_evidence_reference <- ""
write_proposal <- FALSE

assertthat::assert_that(
  review_stage %in% base::c("raw", "classified"),
  msg = "'review_stage' must be 'raw' or 'classified'."
)

path_trait_store <-
  resolve_pipeline_store_path(
    pipeline_script = here::here(
      "R/Pipelines/pipeline_traits_reference.R"
    )
  )
path_candidates <-
  here::here(
    "Data/Temp/Trait_corrections",
    review_stage,
    "trait_review_candidates.csv"
  )
path_decisions <-
  here::here(
    "Data/Input/Trait_corrections",
    stringr::str_glue(
      "trait_review_decisions_{review_stage}.csv"
    )
  )


#----------------------------------------------------------#
# 1. Load current queue, decisions, and records -----
#----------------------------------------------------------#

data_candidates <-
  readr::read_csv(path_candidates, show_col_types = FALSE)
data_decisions <-
  load_trait_review_decisions(path_decisions)

if (review_stage == "raw") {
  data_records <-
    targets::tar_read(data_traits_raw, store = path_trait_store)
} else {
  data_records <-
    targets::tar_read(data_traits_classified, store = path_trait_store) |>
    dplyr::select(-"taxon_name") |>
    dplyr::rename(taxon_name = "taxon_resolved")
}

data_review_progress <-
  data_candidates |>
  dplyr::left_join(
    data_decisions |>
      dplyr::filter(.data[["review_status"]] == "approved") |>
      dplyr::count(.data[["candidate_id"]], name = "n_approved"),
    by = "candidate_id"
  ) |>
  dplyr::mutate(
    n_approved = tidyr::replace_na(.data[["n_approved"]], 0L)
  )

data_review_progress |>
  dplyr::count(
    .data[["trait_domain_name"]],
    complete = .data[["n_approved"]] > 0L
  ) |>
  base::print(n = Inf)


#----------------------------------------------------------#
# 2. Inspect one candidate -----
#----------------------------------------------------------#

if (base::is.null(focal_candidate_id)) {
  data_review_progress |>
    dplyr::filter(.data[["n_approved"]] == 0L) |>
    dplyr::arrange(
      dplyr::desc(.data[["n_domain_outliers"]]),
      dplyr::desc(.data[["n_taxon_outliers"]])
    ) |>
    dplyr::slice_head(n = 25L) |>
    base::print(n = Inf)
} else {
  data_focal_candidate <-
    data_candidates |>
    dplyr::filter(.data[["candidate_id"]] == focal_candidate_id)
  assertthat::assert_that(
    base::nrow(data_focal_candidate) == 1L,
    msg = "'focal_candidate_id' must identify one current candidate."
  )

  focal_taxon <-
    data_focal_candidate[["taxon_name"]][[1L]]
  focal_domain <-
    data_focal_candidate[["trait_domain_name"]][[1L]]
  data_focal_records <-
    data_records |>
    dplyr::filter(
      .data[["taxon_name"]] == focal_taxon,
      .data[["trait_domain_name"]] == focal_domain
    ) |>
    dplyr::arrange(
      .data[["trait_name"]],
      .data[["dataset_id"]],
      .data[["trait_value"]]
    )

  data_focal_records |>
    dplyr::group_by(
      .data[["trait_name"]],
      .data[["dataset_id"]],
      .data[["dataset_name"]]
    ) |>
    dplyr::summarise(
      n_records = dplyr::n(),
      minimum = base::min(.data[["trait_value"]]),
      median = stats::median(.data[["trait_value"]]),
      maximum = base::max(.data[["trait_value"]]),
      .groups = "drop"
    ) |>
    base::print(n = Inf)

  ggplot2::ggplot(
    data_focal_records,
    ggplot2::aes(
      x = .data[["trait_value"]],
      colour = base::factor(.data[["dataset_id"]])
    )
  ) +
    ggplot2::geom_freqpoly(bins = 40L) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data[["trait_name"]]),
      scales = "free"
    ) +
    ggplot2::labs(
      title = stringr::str_glue("{focal_taxon}: {focal_domain}"),
      colour = "dataset_id"
    ) |>
    base::print()

  if (base::isTRUE(write_proposal)) {
    assertthat::assert_that(
      proposed_action %in% base::c("none", "exclude", "scale"),
      base::nzchar(proposed_rationale),
      base::nzchar(proposed_evidence_reference),
      msg = "Proposal action, rationale, and evidence are required."
    )
    decision_key <-
      stringr::str_c(
        focal_candidate_id,
        proposed_trait_name,
        proposed_dataset_id,
        proposed_value_lower,
        proposed_value_upper,
        proposed_action,
        proposed_scale_factor,
        proposed_rationale,
        sep = "|"
      )
    data_proposal <-
      tibble::tibble(
        decision_id = digest::digest(
          decision_key,
          algo = "sha256",
          serialize = FALSE
        ),
        candidate_id = focal_candidate_id,
        taxon_name = focal_taxon,
        trait_domain_name = focal_domain,
        trait_name = proposed_trait_name,
        dataset_id = proposed_dataset_id,
        value_lower = proposed_value_lower,
        value_lower_inclusive = proposed_value_lower_inclusive,
        value_upper = proposed_value_upper,
        value_upper_inclusive = proposed_value_upper_inclusive,
        action = proposed_action,
        scale_factor = proposed_scale_factor,
        rationale = proposed_rationale,
        evidence_reference = proposed_evidence_reference,
        source_reference = stringr::str_glue(
          "interactive_reviewer:{review_stage}"
        ),
        review_status = "proposed",
        reviewer = NA_character_,
        reviewed_at = NA_character_
      )
    readr::write_csv(
      dplyr::bind_rows(data_decisions, data_proposal),
      path_decisions
    )
    cli::cli_inform(
      "Wrote one proposed decision. Human approval is still required."
    )
  }
}
