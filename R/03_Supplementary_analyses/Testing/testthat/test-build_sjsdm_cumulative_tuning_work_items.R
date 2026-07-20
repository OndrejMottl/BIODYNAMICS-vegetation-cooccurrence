make_cumulative_work_item_test_data <- function() {
  data_work_items <-
    tidyr::crossing(
      repeat_id = 1:3,
      fold_id = 1:2,
      candidate_id = base::c(
        "candidate_001",
        "candidate_002",
        "candidate_003",
        "candidate_004"
      )
    ) |>
    dplyr::mutate(
      work_item_id = stringr::str_c(
        .data[["repeat_id"]],
        .data[["fold_id"]],
        .data[["candidate_id"]],
        sep = "_"
      ),
      .before = 1L
    )

  return(data_work_items)
}

make_cumulative_schedule_test_data <- function() {
  res <-
    build_sjsdm_tuning_schedule(
      tuning_strategy = "staged",
      n_candidates = 4L,
      repeat_ids = 1:3,
      survivor_counts = base::c(2L, 1L)
    )

  return(res)
}

make_cumulative_decision_test_data <- function(
    round_id,
    candidate_ids,
    survivor_ids) {
  res <-
    tibble::tibble(
      round_id = base::rep(round_id, base::length(candidate_ids)),
      candidate_id = candidate_ids,
      staged_decision = dplyr::if_else(
        candidate_ids %in% survivor_ids,
        "survive",
        "prune"
      )
    )

  return(res)
}

testthat::test_that(
  "build_sjsdm_cumulative_tuning_work_items() starts at round one",
  {
    res <-
      build_sjsdm_cumulative_tuning_work_items(
        data_work_items = make_cumulative_work_item_test_data(),
        data_schedule = make_cumulative_schedule_test_data()
      )

    testthat::expect_equal(base::nrow(res), 8L)
    testthat::expect_identical(base::unique(res[["round_id"]]), 1L)
    testthat::expect_identical(base::unique(res[["repeat_id"]]), 1L)
  }
)

testthat::test_that(
  "build_sjsdm_cumulative_tuning_work_items() appends authorized work",
  {
    data_round_one <-
      make_cumulative_decision_test_data(
        round_id = 1L,
        candidate_ids = base::c(
          "candidate_001",
          "candidate_002",
          "candidate_003",
          "candidate_004"
        ),
        survivor_ids = base::c("candidate_001", "candidate_002")
      )

    data_round_two <-
      make_cumulative_decision_test_data(
        round_id = 2L,
        candidate_ids = base::c("candidate_001", "candidate_002"),
        survivor_ids = "candidate_002"
      )

    res_round_two <-
      build_sjsdm_cumulative_tuning_work_items(
        data_work_items = make_cumulative_work_item_test_data(),
        data_schedule = make_cumulative_schedule_test_data(),
        list_prior_decisions = base::list(data_round_one)
      )

    res_round_three <-
      build_sjsdm_cumulative_tuning_work_items(
        data_work_items = make_cumulative_work_item_test_data(),
        data_schedule = make_cumulative_schedule_test_data(),
        list_prior_decisions = base::list(
          data_round_one,
          data_round_two
        )
      )

    testthat::expect_equal(base::nrow(res_round_two), 12L)
    testthat::expect_equal(base::nrow(res_round_three), 14L)
    testthat::expect_setequal(
      res_round_three |>
        dplyr::filter(.data[["round_id"]] == 3L) |>
        dplyr::pull(.data[["candidate_id"]]),
      "candidate_002"
    )
    testthat::expect_setequal(
      res_round_two |>
        dplyr::filter(.data[["round_id"]] == 1L) |>
        dplyr::pull(.data[["work_item_id"]]),
      res_round_three |>
        dplyr::filter(.data[["round_id"]] == 1L) |>
        dplyr::pull(.data[["work_item_id"]])
    )
  }
)

testthat::test_that(
  "build_sjsdm_cumulative_tuning_work_items() rejects decision gaps",
  {
    data_round_two <-
      make_cumulative_decision_test_data(
        round_id = 2L,
        candidate_ids = base::c("candidate_001", "candidate_002"),
        survivor_ids = "candidate_002"
      )

    testthat::expect_error(
      build_sjsdm_cumulative_tuning_work_items(
        data_work_items = make_cumulative_work_item_test_data(),
        data_schedule = make_cumulative_schedule_test_data(),
        list_prior_decisions = base::list(data_round_two)
      ),
      "consecutive"
    )
  }
)

testthat::test_that(
  "build_sjsdm_cumulative_tuning_work_items() stops after final round",
  {
    data_round_one <-
      make_cumulative_decision_test_data(
        round_id = 1L,
        candidate_ids = base::c(
          "candidate_001",
          "candidate_002",
          "candidate_003",
          "candidate_004"
        ),
        survivor_ids = base::c("candidate_001", "candidate_002")
      )

    data_round_two <-
      make_cumulative_decision_test_data(
        round_id = 2L,
        candidate_ids = base::c("candidate_001", "candidate_002"),
        survivor_ids = "candidate_002"
      )

    data_round_three <-
      make_cumulative_decision_test_data(
        round_id = 3L,
        candidate_ids = "candidate_002",
        survivor_ids = "candidate_002"
      )

    testthat::expect_error(
      build_sjsdm_cumulative_tuning_work_items(
        data_work_items = make_cumulative_work_item_test_data(),
        data_schedule = make_cumulative_schedule_test_data(),
        list_prior_decisions = base::list(
          data_round_one,
          data_round_two,
          data_round_three
        )
      ),
      "non-final rounds"
    )
  }
)
