testthat::test_that(
  "review reconciliation assigns every workflow category",
  {
    data_candidates <-
      tibble::tibble(
        candidate_id = base::letters[1:5],
        review_stage = "raw",
        taxon_name = stringr::str_c("Taxon ", base::LETTERS[1:5]),
        trait_domain_name = "Height",
        n_records = 10L,
        n_trait_names = 1L,
        n_datasets = 1L,
        n_domain_outliers = 0L,
        n_taxon_outliers = 1L,
        source_references = "",
        candidate_reasons = "taxon_outlier"
      )
    data_historical_scope <-
      tibble::tibble(
        candidate_id = base::c("a", "b", "c", "e"),
        taxon_name = stringr::str_c(
          "Historical taxon ",
          base::LETTERS[1:4]
        ),
        trait_domain_name = "Historical domain",
        historical_report_path = "report.pdf",
        historical_report_page = base::c(2L, 3L, 701L, 4L),
        historical_reviewed = base::c(TRUE, TRUE, FALSE, TRUE),
        historical_review_basis = "test fixture"
      )
    data_submission_audit <-
      tibble::tibble(
        candidate_id = base::c("a", "b", "b"),
        source_row = base::c(1L, 2L, 3L),
        proposal_type = base::c(
          "scale_whole_group",
          "pending_visual_review",
          "pending_visual_review"
        )
      )
    data_proposals <-
      tibble::tibble(
        candidate_id = "a",
        decision_id = "decision-a"
      )

    data_reconciliation <-
      build_trait_review_reconciliation(
        data_trait_review_candidates = data_candidates,
        data_historical_review_scope = data_historical_scope,
        data_review_submission_audit = data_submission_audit,
        data_review_decision_proposals = data_proposals
      )

    testthat::expect_equal(base::nrow(data_reconciliation), 5L)
    testthat::expect_equal(
      dplyr::pull(data_reconciliation, remaining_review_category),
      base::c(
        "recovered_correction_needs_validation",
        "submitted_correction_needs_interpretation",
        "unfinished_historical_review",
        "new_or_changed_candidate",
        "prior_no_action_needs_revalidation"
      )
    )
    testthat::expect_equal(
      dplyr::pull(data_reconciliation, n_submission_rows),
      base::c(1L, 2L, 0L, 0L, 0L)
    )
    testthat::expect_true(
      dplyr::pull(
        dplyr::filter(
          data_reconciliation,
          .data[["candidate_id"]] == "e"
        ),
        implicit_none_proposal_eligible
      )
    )
  }
)

testthat::test_that(
  "review reconciliation fails on duplicate candidate identifiers",
  {
    data_candidates <-
      tibble::tibble(
        candidate_id = base::c("a", "a"),
        review_stage = "raw",
        taxon_name = base::c("Taxon A", "Taxon B"),
        trait_domain_name = "Height",
        n_records = 10L,
        n_trait_names = 1L,
        n_datasets = 1L,
        n_domain_outliers = 0L,
        n_taxon_outliers = 1L,
        source_references = "",
        candidate_reasons = "taxon_outlier"
      )

    testthat::expect_error(
      build_trait_review_reconciliation(
        data_trait_review_candidates = data_candidates,
        data_historical_review_scope = tibble::tibble(
          candidate_id = character(),
          historical_report_path = character(),
          historical_report_page = integer(),
          historical_reviewed = logical(),
          historical_review_basis = character()
        ),
        data_review_submission_audit = tibble::tibble(
          candidate_id = character(),
          source_row = integer(),
          proposal_type = character()
        ),
        data_review_decision_proposals = tibble::tibble(
          candidate_id = character(),
          decision_id = character()
        )
      ),
      "candidate_id"
    )
  }
)
