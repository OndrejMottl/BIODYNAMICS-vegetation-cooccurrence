testthat::test_that(
  "select_sjsdm_staged_survivors() ranks ties deterministically",
  {
    data_aggregation <-
      tibble::tibble(
        candidate_id = base::c("candidate_003", "candidate_001",
          "candidate_002"),
        normalized_loss_equal_id = base::c(0.2, 0.1, 0.1),
        aggregation_status = base::rep("ok", 3L)
      )

    data_survivors <-
      select_sjsdm_staged_survivors(
        data_candidate_aggregation = data_aggregation,
        survivor_count = 2L,
        round_id = 1L
      )

    testthat::expect_identical(
      data_survivors[["candidate_id"]],
      base::c("candidate_001", "candidate_002", "candidate_003")
    )
    testthat::expect_identical(
      data_survivors[["staged_decision"]],
      base::c("survive", "survive", "prune")
    )
    testthat::expect_identical(
      data_survivors[["candidate_rank"]],
      1:3
    )
  }
)

testthat::test_that(
  "select_sjsdm_staged_survivors() prunes ineligible candidates",
  {
    data_aggregation <-
      tibble::tibble(
        candidate_id = base::c(
          "candidate_001",
          "candidate_002",
          "candidate_003"
        ),
        normalized_loss_equal_id = base::c(0.2, NA_real_, 0.1),
        aggregation_status = base::c(
          "ok",
          "incomplete_source_evidence",
          "ok"
        )
      )

    data_survivors <-
      select_sjsdm_staged_survivors(
        data_candidate_aggregation = data_aggregation,
        survivor_count = 1L,
        round_id = 1L
      )

    testthat::expect_identical(
      data_survivors[["candidate_id"]],
      base::c("candidate_003", "candidate_001", "candidate_002")
    )
    testthat::expect_identical(
      data_survivors[["staged_decision"]],
      base::c("survive", "prune", "prune")
    )
  }
)

testthat::test_that(
  "select_sjsdm_staged_survivors() requires enough eligible candidates",
  {
    data_aggregation <-
      tibble::tibble(
        candidate_id = base::c(
          "candidate_001",
          "candidate_002",
          "candidate_003"
        ),
        normalized_loss_equal_id = base::c(0.1, NA_real_, NA_real_),
        aggregation_status = base::c(
          "ok",
          "incomplete_source_evidence",
          "incomplete_source_evidence"
        )
      )

    testthat::expect_error(
      select_sjsdm_staged_survivors(
        data_candidate_aggregation = data_aggregation,
        survivor_count = 2L,
        round_id = 1L
      ),
      "Only 1 candidate has complete tier evidence"
    )
  }
)

testthat::test_that(
  "select_sjsdm_staged_survivors() validates the survivor count",
  {
    data_aggregation <-
      tibble::tibble(
        candidate_id = base::c("candidate_001", "candidate_002"),
        normalized_loss_equal_id = base::c(0.1, 0.2),
        aggregation_status = base::rep("ok", 2L)
      )

    testthat::expect_error(
      select_sjsdm_staged_survivors(
        data_candidate_aggregation = data_aggregation,
        survivor_count = 2L,
        round_id = 1L
      ),
      "fewer candidates"
    )
  }
)
