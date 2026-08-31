testthat::test_that(
  "decision validation accepts complete approved coverage",
  {
    candidate_id <-
      digest::digest("raw|A|Height", algo = "sha256", serialize = FALSE)

    data_candidates <-
      tibble::tibble(
        candidate_id = candidate_id,
        review_stage = "raw",
        taxon_name = "A",
        trait_domain_name = "Height"
      )

    data_records <-
      tibble::tibble(
        taxon_name = "A",
        trait_domain_name = "Height",
        trait_name = "whole plant height",
        dataset_id = 1L,
        trait_value = 10
      )

    data_decisions <-
      tibble::tibble(
        decision_id = digest::digest(
          "decision-1",
          algo = "sha256",
          serialize = FALSE
        ),
        candidate_id = candidate_id,
        taxon_name = "A",
        trait_domain_name = "Height",
        trait_name = "",
        dataset_id = NA_integer_,
        value_lower = NA_real_,
        value_lower_inclusive = NA,
        value_upper = NA_real_,
        value_upper_inclusive = NA,
        action = "none",
        scale_factor = NA_real_,
        rationale = "Values are plausible.",
        evidence_reference = "report:raw:A:Height",
        source_reference = "candidate:raw:A:Height",
        review_status = "approved",
        reviewer = "Reviewer",
        reviewed_at = "2026-08-13"
      )

    data_validated <-
      validate_trait_review_decisions(
        data_trait_review_decisions = data_decisions,
        data_trait_records = data_records,
        data_trait_review_candidates = data_candidates
      )

    testthat::expect_identical(data_validated, data_decisions)
  }
)

testthat::test_that(
  "decision validation rejects incomplete candidate coverage",
  {
    data_candidates <-
      tibble::tibble(
        candidate_id = base::rep("a", 64L) |>
          stringr::str_c(collapse = ""),
        review_stage = "raw",
        taxon_name = "A",
        trait_domain_name = "Height"
      )

    data_records <-
      tibble::tibble(
        taxon_name = "A",
        trait_domain_name = "Height",
        trait_value = 10
      )

    data_empty <-
      tibble::tibble()

    testthat::expect_error(
      validate_trait_review_decisions(
        data_trait_review_decisions = data_empty,
        data_trait_records = data_records,
        data_trait_review_candidates = data_candidates
      ),
      regexp = "coverage"
    )
  }
)

testthat::test_that(
  "decision validation rejects overlapping approved rules",
  {
    candidate_id <-
      digest::digest("raw|A|Height", algo = "sha256", serialize = FALSE)

    data_candidates <-
      tibble::tibble(
        candidate_id = candidate_id,
        review_stage = "raw",
        taxon_name = "A",
        trait_domain_name = "Height"
      )

    data_records <-
      tibble::tibble(
        taxon_name = "A",
        trait_domain_name = "Height",
        trait_name = "whole plant height",
        dataset_id = 1L,
        trait_value = 10
      )

    data_decisions <-
      tibble::tibble(
        decision_id = base::c(
          digest::digest("one", algo = "sha256", serialize = FALSE),
          digest::digest("two", algo = "sha256", serialize = FALSE)
        ),
        candidate_id = base::rep(candidate_id, 2L),
        taxon_name = base::rep("A", 2L),
        trait_domain_name = base::rep("Height", 2L),
        trait_name = base::rep("", 2L),
        dataset_id = base::rep(NA_integer_, 2L),
        value_lower = base::c(5, 9),
        value_lower_inclusive = base::c(TRUE, TRUE),
        value_upper = base::rep(NA_real_, 2L),
        value_upper_inclusive = base::rep(NA, 2L),
        action = base::c("exclude", "scale"),
        scale_factor = base::c(NA_real_, 0.1),
        rationale = base::c("Outlier.", "Unit mismatch."),
        evidence_reference = base::rep("report", 2L),
        source_reference = base::rep("review_submission", 2L),
        review_status = base::rep("approved", 2L),
        reviewer = base::rep("Reviewer", 2L),
        reviewed_at = base::rep("2026-08-13", 2L)
      )

    testthat::expect_error(
      validate_trait_review_decisions(
        data_trait_review_decisions = data_decisions,
        data_trait_records = data_records,
        data_trait_review_candidates = data_candidates
      ),
      regexp = "overlap"
    )
  }
)

testthat::test_that(
  "decision validation fails closed on malformed decisions",
  {
    candidate_id <-
      digest::digest("raw|A|Height", algo = "sha256", serialize = FALSE)
    decision_id <-
      digest::digest("decision", algo = "sha256", serialize = FALSE)
    data_candidates <-
      tibble::tibble(
        candidate_id = candidate_id,
        taxon_name = "A",
        trait_domain_name = "Height"
      )
    data_records <-
      tibble::tibble(
        taxon_name = "A",
        trait_domain_name = "Height",
        trait_name = "whole",
        dataset_id = 1L,
        trait_value = base::c(1, 10)
      )
    data_valid <-
      tibble::tibble(
        decision_id = decision_id,
        candidate_id = candidate_id,
        taxon_name = "A",
        trait_domain_name = "Height",
        trait_name = "",
        dataset_id = NA_integer_,
        value_lower = NA_real_,
        value_lower_inclusive = NA,
        value_upper = NA_real_,
        value_upper_inclusive = NA,
        action = "none",
        scale_factor = NA_real_,
        rationale = "Plausible.",
        evidence_reference = "report",
        source_reference = "candidate",
        review_status = "approved",
        reviewer = "Reviewer",
        reviewed_at = "2026-08-13"
      )

    data_bad_action <-
      data_valid |>
      dplyr::mutate(action = "delete")
    testthat::expect_error(
      validate_trait_review_decisions(
        data_bad_action,
        data_records,
        data_candidates
      ),
      regexp = "Actions"
    )

    data_bad_factor <-
      data_valid |>
      dplyr::mutate(action = "scale", scale_factor = 0)
    testthat::expect_error(
      validate_trait_review_decisions(
        data_bad_factor,
        data_records,
        data_candidates
      ),
      regexp = "positive factor"
    )

    data_bad_bound <-
      data_valid |>
      dplyr::mutate(
        action = "exclude",
        value_lower = 1,
        value_lower_inclusive = NA
      )
    testthat::expect_error(
      validate_trait_review_decisions(
        data_bad_bound,
        data_records,
        data_candidates
      ),
      regexp = "paired"
    )

    data_bad_metadata <-
      data_valid |>
      dplyr::mutate(reviewer = "")
    testthat::expect_error(
      validate_trait_review_decisions(
        data_bad_metadata,
        data_records,
        data_candidates
      ),
      regexp = "reviewer"
    )

    data_unmatched <-
      data_valid |>
      dplyr::mutate(
        action = "exclude",
        trait_name = "missing"
      )
    testthat::expect_error(
      validate_trait_review_decisions(
        data_unmatched,
        data_records,
        data_candidates
      ),
      regexp = "match current records"
    )

    data_unmatched_proposal <-
      data_unmatched |>
      dplyr::mutate(
        decision_id = digest::digest(
          "proposal",
          algo = "sha256",
          serialize = FALSE
        ),
        review_status = "proposed",
        reviewer = NA_character_,
        reviewed_at = NA_character_
      )
    testthat::expect_error(
      validate_trait_review_decisions(
        dplyr::bind_rows(data_valid, data_unmatched_proposal),
        data_records,
        data_candidates
      ),
      regexp = "match current records"
    )

    data_agent_proposal <-
      data_valid |>
      dplyr::mutate(
        review_status = "proposed",
        reviewer = NA_character_,
        reviewed_at = NA_character_
      )
    testthat::expect_error(
      validate_trait_review_decisions(
        data_agent_proposal,
        data_records,
        data_candidates
      ),
      regexp = "coverage"
    )
  }
)

testthat::test_that(
  "validation accepts fully source-satisfied identical scales",
  {
    candidate_id <-
      digest::digest("raw|A|Leaf Area", algo = "sha256", serialize = FALSE)
    data_candidates <-
      tibble::tibble(
        candidate_id = candidate_id,
        taxon_name = "A",
        trait_domain_name = "Leaf Area"
      )
    data_records <-
      tibble::tibble(
        dataset_id = 1L,
        sample_id = 11L,
        trait_id = 21L,
        taxon_id = 31L,
        taxon_name = "A",
        trait_domain_name = "Leaf Area",
        trait_name = "leaf area",
        trait_value = 10
      )
    data_decisions <-
      tibble::tibble(
        decision_id = digest::digest(
          "decision",
          algo = "sha256",
          serialize = FALSE
        ),
        candidate_id = candidate_id,
        taxon_name = "A",
        trait_domain_name = "Leaf Area",
        trait_name = "",
        dataset_id = NA_integer_,
        value_lower = NA_real_,
        value_lower_inclusive = NA,
        value_upper = 20,
        value_upper_inclusive = TRUE,
        action = "scale",
        scale_factor = 100,
        rationale = "Known source-unit mismatch.",
        evidence_reference = "report",
        source_reference = "review",
        review_status = "approved",
        reviewer = "Reviewer",
        reviewed_at = "2026-08-28"
      )
    data_source_audit <-
      tibble::tibble(
        source_scale_rule_id = "source-rule",
        dataset_id = 1L,
        sample_id = 11L,
        trait_id = 21L,
        taxon_id = 31L,
        taxon_name = "A",
        data_source_id = 294L,
        trait_domain_name = "Leaf Area",
        trait_name = "leaf area",
        trait_value_before = 0.1,
        trait_value_after = 10,
        scale_factor = 100
      )

    testthat::expect_no_error(
      validate_trait_review_decisions(
        data_trait_review_decisions = data_decisions,
        data_trait_records = data_records,
        data_trait_review_candidates = data_candidates,
        data_trait_source_scale_record_audit = data_source_audit
      )
    )
    testthat::expect_error(
      validate_trait_review_decisions(
        data_trait_review_decisions = data_decisions |>
          dplyr::mutate(scale_factor = 10),
        data_trait_records = data_records,
        data_trait_review_candidates = data_candidates,
        data_trait_source_scale_record_audit = data_source_audit
      ),
      regexp = "conflict"
    )
  }
)
