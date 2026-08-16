testthat::test_that(
  "evidence packets summarise current and historical records",
  {
    data_records <-
      tibble::tibble(
        taxon_name = base::c(
          base::rep("Taxon A", 4L),
          base::rep("Taxon B", 3L)
        ),
        trait_domain_name = base::c(
          base::rep("Diaspore mass", 4L),
          base::rep("Stem specific density", 3L)
        ),
        trait_value = base::c(1, 1, 100, 100, 0, -0.5, 0.5),
        dataset_id = base::c(1L, 1L, 2L, 2L, 3L, 3L, 3L),
        dataset_name = base::c(
          "Dataset A",
          "Dataset A",
          "Dataset B",
          "Dataset B",
          "Dataset C",
          "Dataset C",
          "Dataset C"
        ),
        trait_name = base::c(
          base::rep("Seed mass", 4L),
          base::rep("Stem density", 3L)
        ),
        sample_id = base::seq_len(7L),
        trait_id = base::seq_len(7L),
        taxon_id = base::c(
          base::rep(10L, 4L),
          base::rep(20L, 3L)
        )
      )
    data_reconciliation <-
      tibble::tibble(
        candidate_id = base::c("candidate-a", "candidate-b"),
        taxon_name = base::c("Taxon A", "Taxon B"),
        trait_domain_name = base::c(
          "Diaspore mass",
          "Stem specific density"
        ),
        n_taxon_outliers = base::c(2L, 1L),
        implicit_none_proposal_eligible = base::c(TRUE, FALSE),
        historical_scope_status = base::c(
          "confirmed_previous_review",
          "confirmed_previous_review"
        )
      )
    data_historical <-
      tibble::tibble(
        candidate_id = base::c("candidate-a", "candidate-b"),
        historical_n_records = base::c(4L, 3L),
        historical_median = base::c(50.5, 0.4),
        historical_iqr = base::c(99, 0.4),
        historical_heuristic = base::c("PROBABLY OK", "REVIEW"),
        historical_suggestion = base::c(
          "No correction needed",
          "Manual review required"
        )
      )

    res <-
      build_trait_review_evidence_packets(
        data_trait_records = data_records,
        data_trait_review_reconciliation = data_reconciliation,
        data_historical_review_scope = data_historical
      )
    data_candidates <-
      res[["data_candidate_evidence"]]

    testthat::expect_named(
      res,
      base::c(
        "data_candidate_evidence",
        "data_dataset_evidence",
        "data_record_evidence"
      )
    )
    testthat::expect_equal(base::nrow(data_candidates), 2L)
    testthat::expect_equal(
      data_candidates[["n_nonpositive"]],
      base::c(0L, 2L)
    )
    testthat::expect_equal(
      data_candidates[["n_zero"]],
      base::c(0L, 1L)
    )
    testthat::expect_equal(
      data_candidates[["n_negative"]],
      base::c(0L, 1L)
    )
    testthat::expect_true(
      data_candidates[["historical_summary_stable"]][[1L]]
    )
    testthat::expect_equal(
      data_candidates[["unit_ratio_nearest_factor"]][[1L]],
      100
    )
    testthat::expect_true(
      data_candidates[["possible_unit_pattern"]][[1L]]
    )
    testthat::expect_equal(
      base::sort(
        base::unique(res[["data_record_evidence"]][["candidate_id"]])
      ),
      base::c("candidate-a", "candidate-b")
    )
  }
)

testthat::test_that(
  "evidence packets reject incomplete record contracts",
  {
    testthat::expect_error(
      build_trait_review_evidence_packets(
        data_trait_records = tibble::tibble(
          taxon_name = "Taxon A"
        ),
        data_trait_review_reconciliation = tibble::tibble(),
        data_historical_review_scope = tibble::tibble()
      ),
      "required columns"
    )
  }
)
