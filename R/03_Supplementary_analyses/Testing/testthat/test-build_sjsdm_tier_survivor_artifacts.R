make_tier_round_test_data <- function() {
  data_tuning_summary <-
    tidyr::crossing(
      source_id = base::c("unit_a", "unit_b"),
      repeat_id = 1L,
      candidate_id = base::c(
        "candidate_001",
        "candidate_002",
        "candidate_003",
        "candidate_004"
      )
    ) |>
    dplyr::mutate(
      tier_id = "continental",
      taxonomic_resolution = "genus",
      response_family = "binomial",
      predictor_structure = "abiotic_spatial",
      candidate_table_hash = "candidate_hash_001",
      alpha_cov = 0.5,
      alpha_coef = 0.5,
      alpha_spatial = 0.5,
      lambda_cov = 0.1,
      lambda_coef = 0.1,
      lambda_spatial = 0.1,
      n_response_values = 100L,
      negative_log_likelihood_per_response = dplyr::case_when(
        .data[["candidate_id"]] == "candidate_001" ~ 0.1,
        .data[["candidate_id"]] == "candidate_002" ~ 0.2,
        .data[["candidate_id"]] == "candidate_003" ~ 0.3,
        .default = 0.4
      ),
      summary_status = "ok"
    )

  return(data_tuning_summary)
}

testthat::test_that(
  "build_sjsdm_tier_survivor_artifacts() pools before pruning",
  {
    data_schedule <-
      build_sjsdm_tuning_schedule(
        tuning_strategy = "staged",
        n_candidates = 4L,
        repeat_ids = 1:3,
        survivor_counts = base::c(2L, 1L)
      )

    res <-
      build_sjsdm_tier_survivor_artifacts(
        data_tuning_summary = make_tier_round_test_data(),
        data_schedule = data_schedule,
        round_id = 1L
      )

    testthat::expect_named(
      res,
      base::c(
        "data_survivor_decisions",
        "data_source_candidate_loss",
        "data_candidate_aggregation"
      )
    )

    data_decisions <-
      res[["data_survivor_decisions"]]

    testthat::expect_equal(base::nrow(data_decisions), 4L)
    testthat::expect_setequal(
      data_decisions |>
        dplyr::filter(.data[["staged_decision"]] == "survive") |>
        dplyr::pull(.data[["candidate_id"]]),
      base::c("candidate_001", "candidate_002")
    )
    testthat::expect_identical(
      base::unique(data_decisions[["strategy_version"]]),
      "sjsdm_staged_tuning_v1"
    )
    testthat::expect_identical(
      base::unique(data_decisions[["repeat_id"]]),
      1L
    )
  }
)

testthat::test_that(
  "build_sjsdm_tier_survivor_artifacts() fails on partial evidence",
  {
    data_schedule <-
      build_sjsdm_tuning_schedule(
        tuning_strategy = "staged",
        n_candidates = 4L,
        repeat_ids = 1:3,
        survivor_counts = base::c(2L, 1L)
      )

    data_partial <-
      make_tier_round_test_data() |>
      dplyr::filter(
        !(
          .data[["source_id"]] == "unit_b" &
            .data[["candidate_id"]] == "candidate_004"
        )
      )

    testthat::expect_error(
      build_sjsdm_tier_survivor_artifacts(
        data_tuning_summary = data_partial,
        data_schedule = data_schedule,
        round_id = 1L
      ),
      "same candidate table"
    )
  }
)

testthat::test_that(
  "build_sjsdm_tier_survivor_artifacts() checks the round",
  {
    data_schedule <-
      build_sjsdm_tuning_schedule(
        tuning_strategy = "staged",
        n_candidates = 4L,
        repeat_ids = 1:3,
        survivor_counts = base::c(2L, 1L)
      )

    testthat::expect_error(
      build_sjsdm_tier_survivor_artifacts(
        data_tuning_summary = make_tier_round_test_data(),
        data_schedule = data_schedule,
        round_id = 2L
      ),
      "configured repeat"
    )
  }
)
