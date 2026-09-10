testthat::test_that(
  "aggregate_sjsdm_tuning_fit_attempts combines cached attempts",
  {
    data_attempt <-
      tibble::tibble(
        candidate_id = "candidate_1",
        repeat_id = 1L,
        fold_id = 1L,
        attempt = 1L
      )
    list_cache <-
      base::list(
        base::list(
          list_candidate_predictions = base::list(
            base::list(data_fit_attempts = data_attempt),
            base::list(
              data_fit_attempts = dplyr::mutate(
                data_attempt,
                candidate_id = "candidate_2"
              )
            )
          )
        )
      )

    res <-
      aggregate_sjsdm_tuning_fit_attempts(list_cache)

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_equal(
      res[["candidate_id"]],
      c("candidate_1", "candidate_2")
    )
  }
)

testthat::test_that(
  "aggregate_sjsdm_tuning_fit_attempts returns typed empty output",
  {
    res <-
      aggregate_sjsdm_tuning_fit_attempts(base::list())

    testthat::expect_s3_class(res, "data.frame")
    testthat::expect_equal(base::nrow(res), 0L)
    testthat::expect_true(
      base::all(
        c("candidate_id", "repeat_id", "fold_id", "attempt") %in%
          base::names(res)
      )
    )
  }
)
