testthat::test_that(
  "programmatic reconciliation validates only corroborated rules",
  {
    vec_candidate_ids <-
      base::vapply(
        base::letters[1:5],
        digest::digest,
        base::character(1L),
        algo = "sha256",
        serialize = FALSE
      ) |>
      base::unname()
    data_candidates <-
      tibble::tibble(
        candidate_id = vec_candidate_ids,
        taxon_name = stringr::str_c("Taxon ", base::LETTERS[1:5]),
        trait_domain_name = "Leaf Area",
        triage_outcome = base::c(
          "pending_recovered_proposal",
          "pending_isolated_source_pattern",
          "pending_submitted_note",
          "pending_submitted_note",
          "pending_unresolved_evidence"
        ),
        n_records_current = base::c(0L, 4L, 4L, 4L, 2L),
        n_submission_rows = 0L,
        pending_programmatic = TRUE
      )
    data_source_pairs <-
      tibble::tibble(
        candidate_id = vec_candidate_ids[[2L]],
        trait_domain_name = "Leaf Area",
        low_dataset_id = 1L,
        low_dataset_name = "Low source",
        low_trait_name = "Leaf area",
        low_source_median = 1,
        high_dataset_id = 2L,
        high_dataset_name = "High source",
        high_trait_name = "Leaf area",
        high_source_median = 10,
        source_median_ratio = 10,
        unit_factor = 10,
        unit_factor_relative_error = 0
      )
    data_submission_audit <-
      tibble::tibble(
        candidate_id = vec_candidate_ids[2:4],
        action_source = "scale",
        scale_factor_source = base::c("10", "100", "10"),
        notes_lower = base::c(
          "x",
          "rescale values below 10 only",
          "rescale values below 3 only"
        ),
        source_row = 1:3
      )
    data_records <-
      tibble::tibble(
        candidate_id = base::c(
          base::rep(vec_candidate_ids[[2L]], 4L),
          base::rep(vec_candidate_ids[[3L]], 4L),
          base::rep(vec_candidate_ids[[4L]], 4L),
          base::rep(vec_candidate_ids[[5L]], 2L)
        ),
        dataset_id = base::c(
          1L, 1L, 2L, 2L,
          base::rep(3L, 10L)
        ),
        trait_name = "Leaf area",
        trait_value = base::c(
          1, 1, 10, 10,
          1, 1, 100, 100,
          1, 2, 3, 4,
          5, 6
        )
      )

    res <-
      build_trait_review_programmatic_reconciliation(
        data_candidate_triage = data_candidates,
        data_source_pairs = data_source_pairs,
        data_submission_audit = data_submission_audit,
        data_record_evidence = data_records,
        evidence_reference = "report.md"
      )

    data_reconciliation <-
      res[["data_candidate_reconciliation"]]
    testthat::expect_equal(
      data_reconciliation[["reconciliation_outcome"]],
      base::c(
        "propose_none_no_current_records",
        "propose_scale_corroborated_source",
        "propose_scale_validated_threshold",
        "agent_threshold_rule_not_corroborated",
        "pending_unresolved_evidence"
      )
    )
    testthat::expect_equal(
      res[["data_decision_proposals"]][["action"]],
      base::c("none", "scale", "scale")
    )
    testthat::expect_equal(
      res[["data_decision_proposals"]][["dataset_id"]][[2L]],
      1L
    )
    testthat::expect_equal(
      res[["data_decision_proposals"]][["value_upper"]][[3L]],
      10
    )
    testthat::expect_false(
      res[["data_decision_proposals"]][[
        "value_upper_inclusive"
      ]][[3L]]
    )
    testthat::expect_true(
      data_reconciliation[["requires_agent"]][[4L]]
    )
    testthat::expect_equal(
      base::sum(
        res[["data_proposal_audit"]][["proposed_record_count"]]
      ),
      4L
    )
  }
)

testthat::test_that(
  "programmatic reconciliation rejects malformed inputs",
  {
    testthat::expect_error(
      build_trait_review_programmatic_reconciliation(
        data_candidate_triage = tibble::tibble(
          candidate_id = "not-a-hash"
        ),
        data_source_pairs = tibble::tibble(),
        data_submission_audit = tibble::tibble(),
        data_record_evidence = tibble::tibble(),
        evidence_reference = "report.md"
      ),
      "missing required columns"
    )
  }
)
