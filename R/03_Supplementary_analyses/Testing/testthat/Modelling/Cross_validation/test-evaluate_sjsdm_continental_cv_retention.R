testthat::test_that(
  "evaluate_sjsdm_continental_cv_retention() requires both audit gates",
  {
    data_completed <-
      tibble::tibble(
        analysis_id = "paleo_spatial",
        continent_id = base::c("europe", "america", "asia"),
        resolution_id = "genus",
        final_model_converged = base::c(TRUE, TRUE, FALSE),
        legacy_candidate_id = base::c(
          "candidate_1",
          "candidate_1",
          "candidate_2"
        ),
        legacy_cv_n_iter = 6400L,
        legacy_cv_n_sampling = 1000L,
        final_n_iter = 8000L,
        final_n_sampling = 1000L
      )
    data_calibration <-
      tibble::tibble(
        analysis_id = "paleo_spatial",
        continent_id = base::c("europe", "america", "asia"),
        resolution_id = "genus",
        calibration_status = "accepted",
        candidate_id = base::c("candidate_1", "candidate_2", "candidate_2"),
        n_iter_initial = 1000L,
        n_iter_max = 4000L,
        n_sampling = 200L
      )

    res <-
      evaluate_sjsdm_continental_cv_retention(
        data_completed = data_completed,
        data_calibration = data_calibration
      )

    testthat::expect_equal(
      res[["retention_status"]],
      base::c(
        "retain",
        "invalidate_cv_and_model_descendants",
        "invalidate_cv_and_model_descendants"
      )
    )
    testthat::expect_equal(
      res[["retention_reason"]],
      base::c(
        "converged_and_winner_reproduced",
        "regularization_winner_changed",
        "final_model_not_converged"
      )
    )
    testthat::expect_equal(
      res[["legacy_cv_n_iter"]],
      base::rep(6400L, 3L)
    )
  }
)
