testthat::test_that(
  "candidate diagnosis applies conservative policy precedence",
  {
    data_candidate_evidence <-
      tibble::tibble(
        candidate_id = base::letters[1:4],
        n_nonpositive = base::c(0L, 1L, 0L, 0L),
        n_nonfinite = 0L,
        historical_summary_stable = base::c(
          TRUE,
          FALSE,
          FALSE,
          FALSE
        ),
        implicit_none_proposal_eligible = base::c(
          TRUE,
          FALSE,
          FALSE,
          FALSE
        ),
        possible_unit_pattern = base::c(
          FALSE,
          FALSE,
          TRUE,
          FALSE
        ),
        candidate_impact_score = base::c(0.2, 0.9, 0.8, 0.5),
        candidate_impact_tier = base::c(
          "low",
          "high",
          "high",
          "medium"
        )
      )
    data_records <-
      tibble::tibble(
        candidate_id = base::letters[1:4],
        taxon_name = stringr::str_c("Taxon ", base::LETTERS[1:4]),
        trait_domain_name = "Diaspore mass",
        trait_value = base::c(1, 0, 100, 20),
        trait_name = "Seed mass",
        dataset_id = 1L
      )
    data_proposals <-
      tibble::tibble(
        decision_id = "decision-d",
        candidate_id = "d",
        taxon_name = "Taxon D",
        trait_domain_name = "Diaspore mass",
        trait_name = "Seed mass",
        dataset_id = 1L,
        value_lower = 10,
        value_lower_inclusive = FALSE,
        value_upper = NA_real_,
        value_upper_inclusive = NA,
        action = "exclude",
        scale_factor = NA_real_
      )

    res <-
      diagnose_trait_review_candidates(
        data_candidate_evidence = data_candidate_evidence,
        data_record_evidence = data_records,
        data_review_decision_proposals = data_proposals
      )
    data_recommendations <-
      res[["data_candidate_recommendations"]]

    testthat::expect_equal(
      data_recommendations[["deterministic_outcome"]],
      base::c(
        "retain_historical_no_action",
        "exclude_invalid_values",
        "investigate_unit_pattern",
        "validate_recovered_proposal"
      )
    )
    testthat::expect_equal(
      data_recommendations[["acceptance_eligibility"]],
      base::c(
        "eligible_policy_acceptance",
        "eligible_policy_acceptance",
        "requires_agent_review",
        "requires_agent_review"
      )
    )
    testthat::expect_equal(
      res[["data_proposal_diagnostics"]][["n_matched_records"]],
      1L
    )
  }
)

testthat::test_that(
  "candidate diagnosis reports unmatched recovered selectors",
  {
    data_candidate_evidence <-
      tibble::tibble(
        candidate_id = "a",
        n_nonpositive = 0L,
        n_nonfinite = 0L,
        historical_summary_stable = FALSE,
        implicit_none_proposal_eligible = FALSE,
        possible_unit_pattern = FALSE,
        candidate_impact_score = 0.5,
        candidate_impact_tier = "medium"
      )
    data_records <-
      tibble::tibble(
        candidate_id = "a",
        taxon_name = "Taxon A",
        trait_domain_name = "Diaspore mass",
        trait_value = 1,
        trait_name = "Seed mass",
        dataset_id = 1L
      )
    data_proposals <-
      tibble::tibble(
        decision_id = "decision-a",
        candidate_id = "a",
        taxon_name = "Taxon A",
        trait_domain_name = "Diaspore mass",
        trait_name = "Seed mass",
        dataset_id = 1L,
        value_lower = 10,
        value_lower_inclusive = FALSE,
        value_upper = NA_real_,
        value_upper_inclusive = NA,
        action = "exclude",
        scale_factor = NA_real_
      )

    res <-
      diagnose_trait_review_candidates(
        data_candidate_evidence,
        data_records,
        data_proposals
      )
    data_recommendations <-
      res[["data_candidate_recommendations"]]

    testthat::expect_equal(
      res[["data_proposal_diagnostics"]][["proposal_match_status"]],
      "unmatched_selector"
    )
    testthat::expect_equal(
      data_recommendations[["deterministic_outcome"]],
      "investigate_recovered_proposal"
    )
  }
)
testthat::test_that(
  "candidate diagnosis retains unexplained flags but routes submitted notes",
  {
    data_candidate_evidence <-
      tibble::tibble(
        candidate_id = base::c("a", "b"),
        n_nonpositive = 0L,
        n_nonfinite = 0L,
        n_pending_submission_rows = base::c(0L, 1L),
        historical_summary_stable = FALSE,
        implicit_none_proposal_eligible = FALSE,
        possible_unit_pattern = FALSE,
        candidate_impact_score = base::c(0.5, 0.6),
        candidate_impact_tier = "medium"
      )
    data_records <-
      tibble::tibble(
        candidate_id = base::c("a", "b"),
        taxon_name = base::c("Taxon A", "Taxon B"),
        trait_domain_name = "Leaf Area",
        trait_value = base::c(1, 2),
        trait_name = "Leaf area",
        dataset_id = 1L
      )
    data_proposals <-
      tibble::tibble(
        decision_id = character(),
        candidate_id = character(),
        taxon_name = character(),
        trait_domain_name = character(),
        trait_name = character(),
        dataset_id = integer(),
        value_lower = double(),
        value_lower_inclusive = logical(),
        value_upper = double(),
        value_upper_inclusive = logical(),
        action = character(),
        scale_factor = double()
      )

    res <-
      diagnose_trait_review_candidates(
        data_candidate_evidence = data_candidate_evidence,
        data_record_evidence = data_records,
        data_review_decision_proposals = data_proposals
      )
    data_recommendations <-
      res[["data_candidate_recommendations"]]

    testthat::expect_equal(
      data_recommendations[["deterministic_outcome"]],
      base::c(
        "retain_flagged_uncertain",
        "investigate_submitted_note"
      )
    )
    testthat::expect_equal(
      data_recommendations[["suggested_action"]],
      base::c("none", "defer")
    )
    testthat::expect_equal(
      data_recommendations[["acceptance_eligibility"]],
      base::c(
        "eligible_policy_acceptance",
        "requires_agent_review"
      )
    )
  }
)
testthat::test_that(
  "candidate diagnosis separates zero exclusions from negative investigation",
  {
    data_candidate_evidence <-
      tibble::tibble(
        candidate_id = base::c("a", "b"),
        n_nonpositive = 1L,
        n_nonfinite = 0L,
        n_zero = base::c(1L, 0L),
        n_negative = base::c(0L, 1L),
        n_pending_submission_rows = 0L,
        historical_summary_stable = FALSE,
        implicit_none_proposal_eligible = FALSE,
        possible_unit_pattern = FALSE,
        candidate_impact_score = base::c(0.4, 0.9),
        candidate_impact_tier = base::c("medium", "high")
      )
    data_records <-
      tibble::tibble(
        candidate_id = base::c("a", "b"),
        taxon_name = base::c("Taxon A", "Taxon B"),
        trait_domain_name = "Plant heigh",
        trait_value = base::c(0, -1),
        trait_name = "Plant height",
        dataset_id = 1L
      )
    data_proposals <-
      tibble::tibble(
        decision_id = character(),
        candidate_id = character(),
        taxon_name = character(),
        trait_domain_name = character(),
        trait_name = character(),
        dataset_id = integer(),
        value_lower = double(),
        value_lower_inclusive = logical(),
        value_upper = double(),
        value_upper_inclusive = logical(),
        action = character(),
        scale_factor = double()
      )

    res <-
      diagnose_trait_review_candidates(
        data_candidate_evidence = data_candidate_evidence,
        data_record_evidence = data_records,
        data_review_decision_proposals = data_proposals
      )
    data_recommendations <-
      res[["data_candidate_recommendations"]]

    testthat::expect_equal(
      data_recommendations[["deterministic_outcome"]],
      base::c("exclude_invalid_values", "investigate_invalid_values")
    )
    testthat::expect_equal(
      data_recommendations[["acceptance_eligibility"]],
      base::c(
        "eligible_policy_acceptance",
        "requires_agent_review"
      )
    )
  }
)
