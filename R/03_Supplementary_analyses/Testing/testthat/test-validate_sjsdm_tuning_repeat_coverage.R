testthat::test_that(
  "validate_sjsdm_tuning_repeat_coverage() accepts scheduled repeats",
  {
    data_work_items <-
      tidyr::expand_grid(
        repeat_id = 1:3,
        fold_id = 1:5,
        candidate_id = base::c("candidate_001", "candidate_002")
      )

    data_schedule <-
      tibble::tibble(
        tuning_strategy = base::rep("staged", 3L),
        repeat_id = 1:3
      )

    testthat::expect_true(
      validate_sjsdm_tuning_repeat_coverage(
        data_work_items = data_work_items,
        data_schedule = data_schedule
      )
    )
  }
)

testthat::test_that(
  "validate_sjsdm_tuning_repeat_coverage() rejects fallback assignments",
  {
    data_work_items <-
      tidyr::expand_grid(
        repeat_id = 1L,
        fold_id = 1:25,
        candidate_id = base::c("candidate_001", "candidate_002")
      )

    data_schedule <-
      tibble::tibble(
        tuning_strategy = base::rep("staged", 3L),
        repeat_id = 1:3
      )

    testthat::expect_error(
      validate_sjsdm_tuning_repeat_coverage(
        data_work_items = data_work_items,
        data_schedule = data_schedule
      ),
      "Missing repeat IDs: 2 and 3"
    )
  }
)

testthat::test_that(
  "validate_sjsdm_tuning_repeat_coverage() permits exhaustive tuning",
  {
    testthat::expect_true(
      validate_sjsdm_tuning_repeat_coverage(
        data_work_items = tibble::tibble(
          repeat_id = 1L,
          fold_id = 1L,
          candidate_id = "candidate_001"
        ),
        data_schedule = tibble::tibble(
          tuning_strategy = "exhaustive",
          repeat_id = 1L
        )
      )
    )
  }
)
