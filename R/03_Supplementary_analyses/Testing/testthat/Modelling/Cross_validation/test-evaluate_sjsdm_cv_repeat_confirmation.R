testthat::test_that(
  "evaluate_sjsdm_cv_repeat_confirmation() accepts a near tie",
  {
    data_candidate_summary <-
      tibble::tibble(
        repeat_id = base::rep(1:2, each = 2L),
        candidate_id = base::rep(
          base::c("candidate_001", "candidate_002"),
          times = 2L
        ),
        candidate_loss = base::c(0.101, 0.100, 0.100, 0.1015),
        candidate_complete = TRUE
      )

    res <-
      evaluate_sjsdm_cv_repeat_confirmation(
        data_candidate_summary = data_candidate_summary,
        provisional_candidate_id = "candidate_002",
        relative_loss_tolerance = 0.02
      )

    testthat::expect_equal(
      res[["repeat_two_candidate_id"]],
      "candidate_001"
    )
    testthat::expect_false(res[["repeat_two_exact_winner"]])
    testthat::expect_equal(
      res[["repeat_two_relative_loss_gap"]],
      0.015
    )
    testthat::expect_true(
      res[["repeat_two_practically_equivalent"]]
    )
    testthat::expect_true(res[["repeat_two_confirmed"]])
  }
)

testthat::test_that(
  "evaluate_sjsdm_cv_repeat_confirmation() rejects a material gap",
  {
    data_candidate_summary <-
      tibble::tibble(
        repeat_id = 2L,
        candidate_id = base::c("candidate_001", "candidate_002"),
        candidate_loss = base::c(0.1, 0.1021),
        candidate_complete = TRUE
      )

    res <-
      evaluate_sjsdm_cv_repeat_confirmation(
        data_candidate_summary = data_candidate_summary,
        provisional_candidate_id = "candidate_002",
        relative_loss_tolerance = 0.02
      )

    testthat::expect_false(res[["repeat_two_exact_winner"]])
    testthat::expect_equal(
      res[["repeat_two_relative_loss_gap"]],
      0.021
    )
    testthat::expect_false(
      res[["repeat_two_practically_equivalent"]]
    )
    testthat::expect_false(res[["repeat_two_confirmed"]])
  }
)

testthat::test_that(
  "evaluate_sjsdm_cv_repeat_confirmation() requires complete evidence",
  {
    data_candidate_summary <-
      tibble::tibble(
        repeat_id = 2L,
        candidate_id = base::c("candidate_001", "candidate_002"),
        candidate_loss = base::c(0.1, 0.1005),
        candidate_complete = base::c(TRUE, FALSE)
      )

    res <-
      evaluate_sjsdm_cv_repeat_confirmation(
        data_candidate_summary = data_candidate_summary,
        provisional_candidate_id = "candidate_002"
      )

    testthat::expect_false(res[["repeat_two_confirmed"]])
    testthat::expect_true(
      base::is.na(res[["repeat_two_relative_loss_gap"]])
    )
  }
)
