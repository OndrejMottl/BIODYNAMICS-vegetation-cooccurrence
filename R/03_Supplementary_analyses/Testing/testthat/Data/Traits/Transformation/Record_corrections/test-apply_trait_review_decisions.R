testthat::test_that(
  "approved selectors exclude and scale only matching records",
  {
    data_records <-
      tibble::tibble(
        record_id = 1:4,
        taxon_name = base::rep("A", 4L),
        trait_domain_name = base::rep("Height", 4L),
        trait_name = base::c("vegetative", "vegetative", "whole", "whole"),
        dataset_id = base::c(1L, 1L, 2L, 2L),
        trait_value = base::c(1, 10, 100, 1000)
      )

    data_decisions <-
      tibble::tibble(
        decision_id = base::c("exclude-low", "scale-high"),
        candidate_id = base::rep("candidate", 2L),
        taxon_name = base::rep("A", 2L),
        trait_domain_name = base::rep("Height", 2L),
        trait_name = base::c("vegetative", "whole"),
        dataset_id = base::c(1L, 2L),
        value_lower = base::c(NA_real_, 100),
        value_lower_inclusive = base::c(NA, TRUE),
        value_upper = base::c(1, NA_real_),
        value_upper_inclusive = base::c(TRUE, NA),
        action = base::c("exclude", "scale"),
        scale_factor = base::c(NA_real_, 0.01),
        rationale = base::rep("Approved.", 2L),
        evidence_reference = base::rep("report", 2L),
        source_reference = base::rep("review_submission", 2L),
        review_status = base::rep("approved", 2L),
        reviewer = base::rep("Reviewer", 2L),
        reviewed_at = base::rep("2026-08-13", 2L)
      )

    list_result <-
      apply_trait_review_decisions(
        data_trait_records = data_records,
        data_trait_review_decisions = data_decisions
      )

    data_corrected <-
      purrr::chuck(list_result, "data_trait_records_corrected")
    data_audit <-
      purrr::chuck(list_result, "data_correction_audit")

    testthat::expect_equal(
      dplyr::pull(data_corrected, record_id),
      base::c(2L, 3L, 4L)
    )
    testthat::expect_equal(
      dplyr::pull(data_corrected, trait_value),
      base::c(10, 1, 10)
    )
    testthat::expect_equal(
      dplyr::pull(data_audit, n_matched),
      base::c(1L, 2L)
    )
  }
)

testthat::test_that(
  "no-action decisions preserve records and appear in the audit",
  {
    data_records <-
      tibble::tibble(
        taxon_name = "A",
        trait_domain_name = "Height",
        trait_value = 10
      )

    data_decisions <-
      tibble::tibble(
        decision_id = "none",
        candidate_id = "candidate",
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

    list_result <-
      apply_trait_review_decisions(
        data_trait_records = data_records,
        data_trait_review_decisions = data_decisions
      )

    testthat::expect_identical(
      purrr::chuck(list_result, "data_trait_records_corrected"),
      data_records
    )
    testthat::expect_equal(
      dplyr::pull(
        purrr::chuck(list_result, "data_correction_audit"),
        n_matched
      ),
      0L
    )
  }
)

testthat::test_that(
  "selector bounds respect lower and upper inclusivity",
  {
    data_records <-
      tibble::tibble(
        taxon_name = base::rep("A", 3L),
        trait_domain_name = base::rep("Height", 3L),
        trait_value = base::c(1, 2, 3)
      )
    data_decisions <-
      tibble::tibble(
        decision_id = "bounded",
        candidate_id = "candidate",
        taxon_name = "A",
        trait_domain_name = "Height",
        trait_name = "",
        dataset_id = NA_integer_,
        value_lower = 1,
        value_lower_inclusive = FALSE,
        value_upper = 3,
        value_upper_inclusive = TRUE,
        action = "exclude",
        scale_factor = NA_real_,
        review_status = "approved"
      )

    list_result <-
      apply_trait_review_decisions(data_records, data_decisions)

    testthat::expect_equal(
      purrr::chuck(
        list_result,
        "data_trait_records_corrected"
      )[["trait_value"]],
      1
    )
  }
)

testthat::test_that(
  "selectors do not change records with missing selector fields",
  {
    data_records <-
      tibble::tibble(
        taxon_name = base::rep("A", 2L),
        trait_domain_name = base::rep("Height", 2L),
        trait_name = base::c("whole", NA_character_),
        dataset_id = base::c(1L, NA_integer_),
        trait_value = base::c(10, 20)
      )
    data_decisions <-
      tibble::tibble(
        decision_id = "scale-complete-selector",
        candidate_id = "candidate",
        taxon_name = "A",
        trait_domain_name = "Height",
        trait_name = "whole",
        dataset_id = 1L,
        value_lower = NA_real_,
        value_lower_inclusive = NA,
        value_upper = NA_real_,
        value_upper_inclusive = NA,
        action = "scale",
        scale_factor = 0.1,
        review_status = "approved"
      )

    list_result <-
      apply_trait_review_decisions(data_records, data_decisions)

    testthat::expect_equal(
      purrr::chuck(
        list_result,
        "data_trait_records_corrected"
      )[["trait_value"]],
      base::c(1, 20)
    )
  }
)
