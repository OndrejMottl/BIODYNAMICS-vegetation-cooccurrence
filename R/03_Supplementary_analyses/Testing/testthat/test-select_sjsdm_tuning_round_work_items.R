testthat::test_that(
  "select_sjsdm_tuning_round_work_items() selects round one",
  {
    data_work_items <-
      tidyr::crossing(
        repeat_id = 1:2,
        fold_id = 1:2,
        candidate_id = base::c("candidate_001", "candidate_002")
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

    data_schedule <-
      build_sjsdm_tuning_schedule(
        tuning_strategy = "staged",
        n_candidates = 2L,
        repeat_ids = 1:2,
        survivor_counts = 1L
      )

    res <-
      select_sjsdm_tuning_round_work_items(
        data_work_items = data_work_items,
        data_schedule = data_schedule,
        round_id = 1L
      )

    testthat::expect_equal(base::nrow(res), 4L)
    testthat::expect_identical(base::unique(res[["round_id"]]), 1L)
    testthat::expect_identical(base::unique(res[["repeat_id"]]), 1L)
    testthat::expect_setequal(
      res[["candidate_id"]],
      base::c("candidate_001", "candidate_002")
    )
  }
)

testthat::test_that(
  "select_sjsdm_tuning_round_work_items() applies tier survivors",
  {
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

    data_schedule <-
      build_sjsdm_tuning_schedule(
        tuning_strategy = "staged",
        n_candidates = 4L,
        repeat_ids = 1:3,
        survivor_counts = base::c(2L, 1L)
      )

    data_prior_decisions <-
      tibble::tibble(
        round_id = base::rep(1L, 4L),
        candidate_id = base::c(
          "candidate_001",
          "candidate_002",
          "candidate_003",
          "candidate_004"
        ),
        candidate_rank = 1:4,
        normalized_loss_equal_id = base::c(0.1, 0.2, 0.3, 0.4),
        staged_decision = base::c(
          "survive",
          "survive",
          "prune",
          "prune"
        )
      )

    res <-
      select_sjsdm_tuning_round_work_items(
        data_work_items = data_work_items,
        data_schedule = data_schedule,
        round_id = 2L,
        data_prior_decisions = data_prior_decisions
      )

    testthat::expect_equal(base::nrow(res), 4L)
    testthat::expect_identical(base::unique(res[["repeat_id"]]), 2L)
    testthat::expect_setequal(
      res[["candidate_id"]],
      base::c("candidate_001", "candidate_002")
    )
    testthat::expect_setequal(
      res[["work_item_id"]],
      base::c(
        "2_1_candidate_001",
        "2_1_candidate_002",
        "2_2_candidate_001",
        "2_2_candidate_002"
      )
    )
  }
)

testthat::test_that(
  "select_sjsdm_tuning_round_work_items() fails closed",
  {
    data_work_items <-
      tidyr::crossing(
        repeat_id = 1:2,
        fold_id = 1:2,
        candidate_id = base::c("candidate_001", "candidate_002")
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

    data_schedule <-
      build_sjsdm_tuning_schedule(
        tuning_strategy = "staged",
        n_candidates = 2L,
        repeat_ids = 1:2,
        survivor_counts = 1L
      )

    testthat::expect_error(
      select_sjsdm_tuning_round_work_items(
        data_work_items = data_work_items,
        data_schedule = data_schedule,
        round_id = 2L
      ),
      "previous tier-wide survivor decision"
    )

    data_wrong_decisions <-
      tibble::tibble(
        round_id = base::rep(1L, 2L),
        candidate_id = base::c("candidate_001", "candidate_003"),
        candidate_rank = 1:2,
        normalized_loss_equal_id = base::c(0.1, 0.2),
        staged_decision = base::c("survive", "prune")
      )

    testthat::expect_error(
      select_sjsdm_tuning_round_work_items(
        data_work_items = data_work_items,
        data_schedule = data_schedule,
        round_id = 2L,
        data_prior_decisions = data_wrong_decisions
      ),
      "candidate set"
    )
  }
)

testthat::test_that(
  "select_sjsdm_tuning_round_work_items() rejects local pruning",
  {
    data_work_items <-
      tidyr::crossing(
        repeat_id = 1:2,
        fold_id = 1:2,
        candidate_id = base::c("candidate_001", "candidate_002")
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

    data_schedule <-
      build_sjsdm_tuning_schedule(
        tuning_strategy = "staged",
        n_candidates = 2L,
        repeat_ids = 1:2,
        survivor_counts = 1L
      )

    data_partial_decisions <-
      tibble::tibble(
        round_id = 1L,
        candidate_id = "candidate_001",
        candidate_rank = 1L,
        normalized_loss_equal_id = 0.1,
        staged_decision = "survive"
      )

    testthat::expect_error(
      select_sjsdm_tuning_round_work_items(
        data_work_items = data_work_items,
        data_schedule = data_schedule,
        round_id = 2L,
        data_prior_decisions = data_partial_decisions
      ),
      "every entering candidate"
    )
  }
)
