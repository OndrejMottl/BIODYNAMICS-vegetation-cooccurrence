# -- Helpers ---------------------------------------------------------------

make_proposal_candidates <- function() {
  tibble::tibble(
    candidate_id = base::c("c1", "c2", "c3", "c4"),
    taxon_name = base::c("Abies alba", "Betula", "Carex", "Dryas"),
    trait_domain_name = "Plant heigh"
  )
}

make_proposal_rows <- function(
    vec_candidate_ids,
    action,
    review_status = "proposed") {
  tibble::tibble(
    decision_id = stringr::str_c("d_", vec_candidate_ids, "_", action),
    candidate_id = vec_candidate_ids,
    taxon_name = "taxon",
    trait_domain_name = "Plant heigh",
    trait_name = NA_character_,
    dataset_id = NA_integer_,
    value_lower = NA_real_,
    value_lower_inclusive = NA,
    value_upper = dplyr::if_else(action == "exclude", 0, NA_real_),
    value_upper_inclusive = dplyr::if_else(action == "exclude", TRUE, NA),
    action = action,
    scale_factor = dplyr::if_else(action == "scale", 100, NA_real_),
    rationale = "Rationale.",
    evidence_reference = "report.md",
    source_reference = "source",
    review_status = review_status,
    reviewer = dplyr::if_else(review_status == "approved", "R", NA),
    reviewed_at = dplyr::if_else(
      review_status == "approved",
      "2026-11-26",
      NA
    )
  )
}

# -- Precedence ------------------------------------------------------------

testthat::test_that(
  "select_trait_review_proposals() applies policy, closure, then queue",
  {
    res <-
      select_trait_review_proposals(
        data_trait_review_candidates = make_proposal_candidates(),
        data_policy_proposals = make_proposal_rows("c1", "none"),
        data_closure_decisions = make_proposal_rows(
          base::c("c1", "c2"),
          "exclude",
          review_status = "approved"
        ),
        data_queue_suggestions = make_proposal_rows(
          base::c("c1", "c3", "c3"),
          "scale"
        )
      )

    testthat::expect_equal(
      dplyr::pull(res, candidate_id),
      base::c("c1", "c2", "c3", "c3", "c4")
    )
    testthat::expect_equal(
      dplyr::pull(res, proposal_source),
      base::c("policy", "closure", "queue", "queue", "queue")
    )
    testthat::expect_equal(
      dplyr::pull(res, action),
      base::c("none", "exclude", "scale", "scale", NA)
    )
    testthat::expect_equal(
      dplyr::pull(res, has_overridden_suggestion),
      base::c(TRUE, FALSE, FALSE, FALSE, FALSE)
    )
  }
)

testthat::test_that(
  "select_trait_review_proposals() approves nothing",
  {
    res <-
      select_trait_review_proposals(
        data_trait_review_candidates = make_proposal_candidates(),
        data_policy_proposals = make_proposal_rows("c1", "none"),
        data_closure_decisions = make_proposal_rows(
          base::c("c2", "c3"),
          "none",
          review_status = "approved"
        ),
        data_queue_suggestions = make_proposal_rows(
          base::character(),
          "scale"
        )
      )

    testthat::expect_true(
      base::all(dplyr::pull(res, review_status) == "proposed")
    )
    testthat::expect_true(base::all(base::is.na(dplyr::pull(res, reviewer))))
    testthat::expect_true(
      base::all(base::is.na(dplyr::pull(res, reviewed_at)))
    )
  }
)

testthat::test_that(
  "select_trait_review_proposals() leaves an empty queue row to complete",
  {
    res <-
      select_trait_review_proposals(
        data_trait_review_candidates = make_proposal_candidates(),
        data_policy_proposals = make_proposal_rows(
          base::character(),
          "none"
        ),
        data_closure_decisions = make_proposal_rows(
          base::c("c1", "c2", "c3"),
          "none"
        ),
        data_queue_suggestions = make_proposal_rows(
          base::character(),
          "scale"
        )
      )

    data_queue <-
      res |>
      dplyr::filter(.data[["proposal_source"]] == "queue")

    testthat::expect_equal(base::nrow(data_queue), 1L)
    testthat::expect_equal(dplyr::pull(data_queue, candidate_id), "c4")
    testthat::expect_equal(dplyr::pull(data_queue, taxon_name), "Dryas")
    testthat::expect_true(base::is.na(dplyr::pull(data_queue, action)))
    testthat::expect_true(base::is.na(dplyr::pull(data_queue, decision_id)))
  }
)

testthat::test_that(
  "select_trait_review_proposals() keeps the canonical decision columns",
  {
    res <-
      select_trait_review_proposals(
        data_trait_review_candidates = make_proposal_candidates(),
        data_policy_proposals = make_proposal_rows("c1", "none"),
        data_closure_decisions = make_proposal_rows("c2", "none"),
        data_queue_suggestions = make_proposal_rows("c3", "scale")
      )

    testthat::expect_named(
      res,
      base::c(
        base::names(make_proposal_rows("c1", "none")),
        "proposal_source",
        "has_overridden_suggestion"
      )
    )
  }
)

# -- Arguments -------------------------------------------------------------

testthat::test_that(
  "select_trait_review_proposals() rejects inconsistent inputs",
  {
    testthat::expect_error(
      select_trait_review_proposals(
        data_trait_review_candidates = make_proposal_candidates(),
        data_policy_proposals = make_proposal_rows(
          base::c("c1", "c1"),
          "none"
        ),
        data_closure_decisions = make_proposal_rows("c2", "none"),
        data_queue_suggestions = make_proposal_rows("c3", "scale")
      ),
      regexp = "one row per candidate"
    )
    testthat::expect_error(
      select_trait_review_proposals(
        data_trait_review_candidates = make_proposal_candidates(),
        data_policy_proposals = make_proposal_rows("c9", "none"),
        data_closure_decisions = make_proposal_rows("c2", "none"),
        data_queue_suggestions = make_proposal_rows("c3", "scale")
      ),
      regexp = "unknown candidates"
    )
    testthat::expect_error(
      select_trait_review_proposals(
        data_trait_review_candidates = make_proposal_candidates(),
        data_policy_proposals = make_proposal_rows("c1", "none") |>
          dplyr::select(-"action"),
        data_closure_decisions = make_proposal_rows("c2", "none"),
        data_queue_suggestions = make_proposal_rows("c3", "scale")
      ),
      regexp = "canonical decision columns"
    )
    testthat::expect_error(
      select_trait_review_proposals(
        data_trait_review_candidates = dplyr::bind_rows(
          make_proposal_candidates(),
          make_proposal_candidates()[1L, ]
        ),
        data_policy_proposals = make_proposal_rows("c1", "none"),
        data_closure_decisions = make_proposal_rows("c2", "none"),
        data_queue_suggestions = make_proposal_rows("c3", "scale")
      ),
      regexp = "unique"
    )
  }
)
