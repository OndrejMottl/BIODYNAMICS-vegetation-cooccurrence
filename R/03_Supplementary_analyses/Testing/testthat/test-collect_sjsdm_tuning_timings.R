testthat::test_that(
  "collect_sjsdm_tuning_timings() reports every cached stage",
  {
    list_cache <-
      base::list(
        base::list(
          list_fold_context = base::list(
            repeat_id = 1L,
            fold_id = 2L
          ),
          list_prepared_fold = base::list(value = TRUE),
          preparation_seconds = 1.5,
          list_candidate_predictions = base::list(
            base::list(
              candidate_id = "candidate_001",
              fit_status = "ok",
              fit_seconds = 2,
              prediction_seconds = 0.2,
              scoring_seconds = 0.3
            )
          )
        )
      )

    data_timings <-
      collect_sjsdm_tuning_timings(list_cache)

    testthat::expect_equal(base::nrow(data_timings), 4L)
    testthat::expect_setequal(
      data_timings[["stage"]],
      base::c("preparation", "fit", "prediction", "scoring")
    )
    testthat::expect_equal(
      base::sum(data_timings[["elapsed_seconds"]]),
      4
    )
  }
)

testthat::test_that(
  "collect_sjsdm_tuning_timings() returns a typed empty table",
  {
    data_timings <-
      collect_sjsdm_tuning_timings(base::list())

    testthat::expect_equal(base::nrow(data_timings), 0L)
    testthat::expect_named(
      data_timings,
      base::c(
        "repeat_id",
        "fold_id",
        "candidate_id",
        "stage",
        "elapsed_seconds",
        "execution_status"
      )
    )
  }
)
