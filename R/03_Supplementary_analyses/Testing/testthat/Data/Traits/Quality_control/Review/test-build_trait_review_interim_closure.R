testthat::test_that(
  "interim closure resolves insufficient evidence and invalid values",
  {
    data_candidates <-
      tibble::tibble(
        candidate_id = base::c("none", "invalid", "scale", "covered"),
        taxon_name = base::c("Taxon a", "Taxon b", "Taxon c", "Taxon d"),
        trait_domain_name = base::c(
          "Leaf Area",
          "Plant heigh",
          "Leaf Area",
          "Leaf Area"
        ),
        n_invalid_values = base::c(0L, 1L, 0L, 0L)
      )
    data_decisions <-
      tibble::tibble(
        candidate_id = "covered",
        review_status = "approved"
      )
    data_triage <-
      tibble::tibble(
        candidate_id = base::c("none", "invalid", "scale"),
        triage_outcome = base::c(
          "pending_submitted_note",
          "agent_invalid_values",
          "pending_submitted_note"
        )
      )
    data_reconciliation <-
      tibble::tibble(
        candidate_id = base::c("none", "invalid", "scale"),
        reconciliation_outcome = base::c(
          "agent_threshold_rule_not_corroborated",
          NA_character_,
          "propose_scale_validated_threshold"
        )
      )

    result <-
      build_trait_review_interim_closure(
        data_trait_review_candidates = data_candidates,
        data_trait_review_decisions = data_decisions,
        data_candidate_triage = data_triage,
        data_candidate_reconciliation = data_reconciliation,
        reviewer = "Reviewer",
        reviewed_at = "2026-08-28",
        evidence_reference = "report.md"
      )

    testthat::expect_equal(
      result[["data_closure_audit"]][["closure_outcome"]],
      base::c(
        "approve_none_insufficient_evidence",
        "approve_exclude_invalid_nonpositive",
        "pending_objective_scale_evidence"
      )
    )
    testthat::expect_equal(
      result[["data_approved_decisions"]][["action"]],
      base::c("none", "exclude")
    )
    testthat::expect_equal(
      result[["data_approved_decisions"]][["value_upper"]],
      base::c(NA_real_, 0)
    )
    testthat::expect_equal(
      result[["data_approved_decisions"]][["review_status"]],
      base::rep("approved", 2L)
    )
    testthat::expect_equal(
      result[["data_exceptions"]][["candidate_id"]],
      "scale"
    )
    testthat::expect_false(
      "covered" %in% result[["data_closure_audit"]][["candidate_id"]]
    )
  }
)

testthat::test_that(
  "interim closure retains repeated source evidence as an exception",
  {
    data_candidates <-
      tibble::tibble(
        candidate_id = "source",
        taxon_name = "Taxon a",
        trait_domain_name = "Leaf Area",
        n_invalid_values = 0L
      )
    result <-
      build_trait_review_interim_closure(
        data_trait_review_candidates = data_candidates,
        data_trait_review_decisions = tibble::tibble(
          candidate_id = character(),
          review_status = character()
        ),
        data_candidate_triage = tibble::tibble(
          candidate_id = "source",
          triage_outcome = "agent_repeated_source_pattern"
        ),
        data_candidate_reconciliation = tibble::tibble(
          candidate_id = character(),
          reconciliation_outcome = character()
        ),
        reviewer = "Reviewer",
        reviewed_at = "2026-08-28",
        evidence_reference = "report.md"
      )

    testthat::expect_equal(
      result[["data_exceptions"]][["closure_outcome"]],
      "pending_objective_scale_evidence"
    )
    testthat::expect_equal(
      base::nrow(result[["data_approved_decisions"]]),
      0L
    )
  }
)

testthat::test_that(
  "interim closure validates complete investigation coverage",
  {
    testthat::expect_error(
      build_trait_review_interim_closure(
        data_trait_review_candidates = tibble::tibble(
          candidate_id = "candidate",
          taxon_name = "Taxon a",
          trait_domain_name = "Leaf Area",
          n_invalid_values = 0L
        ),
        data_trait_review_decisions = tibble::tibble(
          candidate_id = character(),
          review_status = character()
        ),
        data_candidate_triage = tibble::tibble(
          candidate_id = character(),
          triage_outcome = character()
        ),
        data_candidate_reconciliation = tibble::tibble(
          candidate_id = character(),
          reconciliation_outcome = character()
        ),
        reviewer = "Reviewer",
        reviewed_at = "2026-08-28",
        evidence_reference = "report.md"
      ),
      "cover every uncovered candidate"
    )
  }
)
