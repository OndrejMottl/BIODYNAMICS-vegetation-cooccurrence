make_sjsdm_staged_benchmark_fixture <- function(
    staged_candidate_id = "candidate_1") {
  data_benchmark_runs <-
    tidyr::crossing(
      repetition_id = 1:3,
      tuning_strategy = base::c("exhaustive", "staged")
    ) |>
    dplyr::mutate(
      wall_seconds = dplyr::if_else(
        .data[["tuning_strategy"]] == "exhaustive",
        100,
        75
      ),
      store_bytes = dplyr::if_else(
        .data[["tuning_strategy"]] == "exhaustive",
        1000,
        1100
      ),
      peak_ram_bytes = dplyr::if_else(
        .data[["tuning_strategy"]] == "exhaustive",
        1000,
        1050
      ),
      peak_vram_bytes = dplyr::if_else(
        .data[["tuning_strategy"]] == "exhaustive",
        1000,
        1050
      ),
      gpu_memory_failure = FALSE,
      n_fits_executed = dplyr::if_else(
        .data[["tuning_strategy"]] == "exhaustive",
        120L,
        70L
      ),
      mean_log_loss = dplyr::if_else(
        .data[["tuning_strategy"]] == "exhaustive",
        0.50,
        0.503
      ),
      mean_auc = dplyr::if_else(
        .data[["tuning_strategy"]] == "exhaustive",
        0.80,
        0.795
      ),
      mean_tjur_r2 = dplyr::if_else(
        .data[["tuning_strategy"]] == "exhaustive",
        0.20,
        0.195
      ),
      evaluable_taxon_coverage = dplyr::if_else(
        .data[["tuning_strategy"]] == "exhaustive",
        0.90,
        0.89
      ),
      technical_cv_status = "pass",
      assignment_hash = "assignments_1",
      artifact_schema_hash = "schema_1",
      selected_candidate_id = dplyr::if_else(
        .data[["tuning_strategy"]] == "exhaustive",
        "candidate_1",
        staged_candidate_id
      )
    )

  list_policy <-
    base::list(
      policy_version = "issue138_staged_benchmark_v1",
      minimum_median_wall_reduction = 0.20,
      minimum_each_wall_reduction = 0.15,
      minimum_fit_reduction = 0.40,
      maximum_store_growth = 0.25,
      maximum_memory_growth = 0.10,
      maximum_log_loss_regression = 0.005,
      maximum_auc_regression = 0.01,
      maximum_tjur_r2_regression = 0.01,
      maximum_coverage_regression = 0.02
    )

  return(
    base::list(
      data_benchmark_runs = data_benchmark_runs,
      list_policy = list_policy
    )
  )
}

testthat::test_that(
  "assess_sjsdm_staged_benchmark() passes the frozen gates",
  {
    list_fixture <-
      make_sjsdm_staged_benchmark_fixture()

    res <-
      assess_sjsdm_staged_benchmark(
        data_benchmark_runs = list_fixture |>
          purrr::chuck("data_benchmark_runs"),
        list_policy = list_fixture |>
          purrr::chuck("list_policy")
      )

    data_pairs <-
      res |>
      purrr::chuck("data_pair_comparisons")
    data_gates <-
      res |>
      purrr::chuck("data_gate_results")
    data_decision <-
      res |>
      purrr::chuck("data_benchmark_decision")

    testthat::expect_equal(base::nrow(data_pairs), 3L)
    testthat::expect_equal(
      data_pairs[["wall_reduction"]],
      base::rep(0.25, 3L)
    )
    testthat::expect_equal(
      data_pairs[["fit_reduction"]],
      base::rep(50 / 120, 3L)
    )
    testthat::expect_true(base::all(data_gates[["passed"]]))
    testthat::expect_identical(
      data_decision[["benchmark_status"]],
      "pass"
    )
    testthat::expect_false(
      data_decision[["scientific_review_required"]]
    )
  }
)

testthat::test_that(
  "assess_sjsdm_staged_benchmark() reports failed resource gates",
  {
    list_fixture <-
      make_sjsdm_staged_benchmark_fixture()
    data_failed <-
      list_fixture |>
      purrr::chuck("data_benchmark_runs") |>
      dplyr::mutate(
        wall_seconds = dplyr::if_else(
          .data[["tuning_strategy"]] == "staged",
          90,
          .data[["wall_seconds"]]
        ),
        gpu_memory_failure = .data[["tuning_strategy"]] == "staged"
      )

    res <-
      assess_sjsdm_staged_benchmark(
        data_benchmark_runs = data_failed,
        list_policy = list_fixture |>
          purrr::chuck("list_policy")
      )
    data_gates <-
      res |>
      purrr::chuck("data_gate_results")
    data_decision <-
      res |>
      purrr::chuck("data_benchmark_decision")

    testthat::expect_setequal(
      data_gates |>
        dplyr::filter(!.data[["passed"]]) |>
        dplyr::pull(.data[["criterion_id"]]),
      base::c(
        "median_wall_reduction",
        "each_wall_reduction",
        "no_gpu_memory_failure"
      )
    )
    testthat::expect_identical(
      data_decision[["benchmark_status"]],
      "fail"
    )
  }
)

testthat::test_that(
  "assess_sjsdm_staged_benchmark() flags changed selection for review",
  {
    list_fixture <-
      make_sjsdm_staged_benchmark_fixture(
        staged_candidate_id = "candidate_2"
      )

    res <-
      assess_sjsdm_staged_benchmark(
        data_benchmark_runs = list_fixture |>
          purrr::chuck("data_benchmark_runs"),
        list_policy = list_fixture |>
          purrr::chuck("list_policy")
      )
    data_decision <-
      res |>
      purrr::chuck("data_benchmark_decision")

    testthat::expect_identical(
      data_decision[["benchmark_status"]],
      "scientific_review"
    )
    testthat::expect_true(
      data_decision[["scientific_review_required"]]
    )
  }
)

testthat::test_that(
  "assess_sjsdm_staged_benchmark() rejects incomplete pairs",
  {
    list_fixture <-
      make_sjsdm_staged_benchmark_fixture()
    data_incomplete <-
      list_fixture |>
      purrr::chuck("data_benchmark_runs") |>
      dplyr::filter(
        !(
          .data[["repetition_id"]] == 3L &
            .data[["tuning_strategy"]] == "staged"
        )
      )

    testthat::expect_error(
      assess_sjsdm_staged_benchmark(
        data_benchmark_runs = data_incomplete,
        list_policy = list_fixture |>
          purrr::chuck("list_policy")
      ),
      "one exhaustive and one staged run"
    )
  }
)
