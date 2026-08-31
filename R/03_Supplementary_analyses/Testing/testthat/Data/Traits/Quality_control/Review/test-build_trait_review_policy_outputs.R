testthat::test_that(
  "policy outputs build proposed none and invalid-value exclusions",
  {
    vec_candidate_ids <-
      base::vapply(
        base::c("none", "exclude", "agent"),
        digest::digest,
        base::character(1L),
        algo = "sha256",
        serialize = FALSE
      )
    data_recommendations <-
      tibble::tibble(
        candidate_id = vec_candidate_ids,
        taxon_name = base::c("Taxon A", "Taxon B", "Taxon C"),
        trait_domain_name = "Diaspore mass",
        n_records_current = base::c(5L, 2L, 8L),
        deterministic_outcome = base::c(
          "retain_flagged_uncertain",
          "exclude_invalid_values",
          "investigate_unit_pattern"
        ),
        suggested_action = base::c("none", "exclude", "defer"),
        acceptance_eligibility = base::c(
          "eligible_policy_acceptance",
          "eligible_policy_acceptance",
          "requires_agent_review"
        ),
        recommendation_rationale = base::c(
          "Retain without objective error evidence.",
          "Exclude non-positive values.",
          "Investigate a possible unit pattern."
        ),
        candidate_impact_score = base::c(0.2, 0.9, 0.8)
      )

    res <-
      build_trait_review_policy_outputs(
        data_candidate_recommendations = data_recommendations,
        evidence_reference = "policy-report.html"
      )
    data_proposals <-
      res[["data_policy_proposals"]]

    testthat::expect_equal(base::nrow(data_proposals), 2L)
    testthat::expect_equal(
      data_proposals[["action"]],
      base::c("none", "exclude")
    )
    testthat::expect_true(
      base::all(data_proposals[["review_status"]] == "proposed")
    )
    testthat::expect_true(
      base::all(base::is.na(data_proposals[["reviewer"]]))
    )
    testthat::expect_true(
      base::is.na(data_proposals[["value_upper"]][[1L]])
    )
    testthat::expect_equal(
      data_proposals[["value_upper"]][[2L]],
      0
    )
    testthat::expect_true(
      data_proposals[["value_upper_inclusive"]][[2L]]
    )
    testthat::expect_match(
      data_proposals[["decision_id"]],
      "^[0-9a-f]{64}$"
    )
  }
)

testthat::test_that(
  "policy outputs bound and prioritize agent candidates by domain",
  {
    data_recommendations <-
      tibble::tibble(
        candidate_id = base::vapply(
          base::letters[1:6],
          digest::digest,
          base::character(1L),
          algo = "sha256",
          serialize = FALSE
        ),
        taxon_name = stringr::str_c("Taxon ", base::LETTERS[1:6]),
        trait_domain_name = base::rep(
          base::c("Leaf Area", "Plant heigh"),
          each = 3L
        ),
        n_records_current = 1L,
        deterministic_outcome = base::c(
          "investigate_historical_drift",
          "investigate_unit_pattern",
          "validate_recovered_proposal",
          "investigate_historical_drift",
          "investigate_submitted_note",
          "investigate_unit_pattern"
        ),
        suggested_action = "defer",
        acceptance_eligibility = "requires_agent_review",
        recommendation_rationale = "Targeted investigation required.",
        candidate_impact_score = base::c(0.9, 0.1, 0.2, 0.9, 0.1, 0.8)
      )

    res <-
      build_trait_review_policy_outputs(
        data_candidate_recommendations = data_recommendations,
        evidence_reference = "policy-report.html",
        max_agent_candidates_per_domain = 2L,
        agent_batch_size = 1L
      )
    data_queue <-
      res[["data_agent_review_queue"]]

    testthat::expect_equal(base::nrow(data_queue), 4L)
    testthat::expect_equal(
      data_queue[["taxon_name"]],
      base::c("Taxon C", "Taxon B", "Taxon E", "Taxon F")
    )
    testthat::expect_equal(
      data_queue[["agent_batch_id"]],
      base::c("leaf_area_01", "leaf_area_02", "plant_heigh_01",
              "plant_heigh_02")
    )
  }
)

testthat::test_that(
  "policy outputs reject malformed recommendation contracts",
  {
    data_recommendations <-
      tibble::tibble(candidate_id = "not-a-hash")

    testthat::expect_error(
      build_trait_review_policy_outputs(
        data_candidate_recommendations = data_recommendations,
        evidence_reference = ""
      ),
      "recommendations|reference"
    )
  }
)
