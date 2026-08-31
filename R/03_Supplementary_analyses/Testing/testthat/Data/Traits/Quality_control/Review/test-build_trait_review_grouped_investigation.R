testthat::test_that(
  "grouped investigation retains proposed source corrections",
  {
    data_exceptions <-
      tibble::tibble(
        candidate_id = base::c("pending", "none"),
        taxon_name = base::c("Taxon a", "Taxon b"),
        trait_domain_name = base::c("Leaf Area", "Plant heigh")
      )
    data_memberships <-
      tibble::tibble(
        candidate_id = "pending",
        trait_domain_name = "Leaf Area",
        data_source_id = 243L
      )
    data_proposals <-
      tibble::tibble(
        source_scale_rule_id = "rule",
        data_source_id = 243L,
        trait_domain_name = "Leaf Area",
        review_status = "proposed"
      )

    result <-
      build_trait_review_grouped_investigation(
        data_trait_review_exceptions = data_exceptions,
        data_candidate_source_memberships = data_memberships,
        data_source_scale_proposals = data_proposals,
        reviewer = "Reviewer",
        reviewed_at = "2026-08-28",
        evidence_reference = "report.md"
      )

    testthat::expect_equal(
      result[["data_investigation_audit"]][["investigation_outcome"]],
      base::c("pending_source_rule_approval", "approve_none_grouped")
    )
    testthat::expect_equal(
      result[["data_approved_decisions"]][["candidate_id"]],
      "none"
    )
    testthat::expect_equal(
      result[["data_approved_decisions"]][["action"]],
      "none"
    )
    testthat::expect_equal(
      result[["data_pending_candidates"]][["candidate_id"]],
      "pending"
    )
  }
)

testthat::test_that(
  "grouped investigation closes approved source rules",
  {
    data_exceptions <-
      tibble::tibble(
        candidate_id = "candidate",
        taxon_name = "Taxon a",
        trait_domain_name = "Leaf Area"
      )
    data_memberships <-
      tibble::tibble(
        candidate_id = "candidate",
        trait_domain_name = "Leaf Area",
        data_source_id = 243L
      )
    data_proposals <-
      tibble::tibble(
        source_scale_rule_id = "rule",
        data_source_id = 243L,
        trait_domain_name = "Leaf Area",
        review_status = "approved"
      )

    result <-
      build_trait_review_grouped_investigation(
        data_trait_review_exceptions = data_exceptions,
        data_candidate_source_memberships = data_memberships,
        data_source_scale_proposals = data_proposals,
        reviewer = "Reviewer",
        reviewed_at = "2026-08-30",
        evidence_reference = "report.md"
      )

    testthat::expect_equal(
      result[["data_investigation_audit"]][["investigation_outcome"]],
      "approve_none_after_source_rule"
    )
    testthat::expect_equal(
      result[["data_approved_decisions"]][["candidate_id"]],
      "candidate"
    )
    testthat::expect_equal(
      base::nrow(result[["data_pending_candidates"]]),
      0L
    )
  }
)

testthat::test_that(
  "grouped investigation permits approved rules that retire candidates",
  {
    result <-
      build_trait_review_grouped_investigation(
        data_trait_review_exceptions = tibble::tibble(
          candidate_id = "candidate",
          taxon_name = "Taxon a",
          trait_domain_name = "Plant heigh"
        ),
        data_candidate_source_memberships = tibble::tibble(
          candidate_id = character(),
          trait_domain_name = character(),
          data_source_id = integer()
        ),
        data_source_scale_proposals = tibble::tibble(
          source_scale_rule_id = "retired_rule",
          data_source_id = 187L,
          trait_domain_name = "Plant heigh",
          review_status = "approved"
        ),
        reviewer = "Reviewer",
        reviewed_at = "2026-08-30",
        evidence_reference = "report.md"
      )

    testthat::expect_equal(
      result[["data_approved_decisions"]][["candidate_id"]],
      "candidate"
    )
    testthat::expect_equal(
      base::nrow(result[["data_pending_candidates"]]),
      0L
    )
  }
)

testthat::test_that(
  "grouped investigation rejects unmatched candidate memberships",
  {
    testthat::expect_error(
      build_trait_review_grouped_investigation(
        data_trait_review_exceptions = tibble::tibble(
          candidate_id = "candidate",
          taxon_name = "Taxon a",
          trait_domain_name = "Leaf Area"
        ),
        data_candidate_source_memberships = tibble::tibble(
          candidate_id = "missing",
          trait_domain_name = "Leaf Area",
          data_source_id = 243L
        ),
        data_source_scale_proposals = tibble::tibble(
          source_scale_rule_id = "rule",
          data_source_id = 243L,
          trait_domain_name = "Leaf Area",
          review_status = "proposed"
        ),
        reviewer = "Reviewer",
        reviewed_at = "2026-08-28",
        evidence_reference = "report.md"
      ),
      "must identify current exceptions"
    )
  }
)
