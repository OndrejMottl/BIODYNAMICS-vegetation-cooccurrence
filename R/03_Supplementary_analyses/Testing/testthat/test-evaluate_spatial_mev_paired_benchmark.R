make_spatial_mev_benchmark_fixture <- function() {
  tidyr::crossing(
    repetition_id = 1:3,
    spatial_mev_strategy = base::c("exact", "fast")
  ) |>
    dplyr::mutate(
      mean_log_loss = dplyr::if_else(
        .data[["spatial_mev_strategy"]] == "exact",
        0.50,
        0.503
      ),
      mean_auc = dplyr::if_else(
        .data[["spatial_mev_strategy"]] == "exact",
        0.80,
        0.795
      ),
      mean_tjur_r2 = dplyr::if_else(
        .data[["spatial_mev_strategy"]] == "exact",
        0.20,
        0.195
      ),
      evaluable_taxon_coverage = dplyr::if_else(
        .data[["spatial_mev_strategy"]] == "exact",
        0.90,
        0.89
      ),
      technical_cv_status = "pass",
      assignment_hash = stringr::str_glue(
        "assignment_{.data[['repetition_id']]}"
      ),
      artifact_schema_hash = "schema_1"
    )
}

testthat::test_that(
  "evaluate_spatial_mev_paired_benchmark() passes predictive gates",
  {
    res <-
      evaluate_spatial_mev_paired_benchmark(
        data_benchmark_runs = make_spatial_mev_benchmark_fixture()
      )

    testthat::expect_true(
      base::all(res[["data_gate_results"]][["passed"]])
    )
    testthat::expect_identical(
      res[["data_benchmark_decision"]][["benchmark_status"]],
      "pass"
    )
    testthat::expect_equal(
      res[["data_pair_comparisons"]][["log_loss_regression"]],
      base::rep(0.003, 3L)
    )
  }
)

testthat::test_that(
  "evaluate_spatial_mev_paired_benchmark() reports predictive failures",
  {
    data_failed <-
      make_spatial_mev_benchmark_fixture() |>
      dplyr::mutate(
        mean_log_loss = dplyr::if_else(
          .data[["spatial_mev_strategy"]] == "fast",
          0.51,
          .data[["mean_log_loss"]]
        ),
        mean_auc = dplyr::if_else(
          .data[["spatial_mev_strategy"]] == "fast",
          0.78,
          .data[["mean_auc"]]
        )
      )

    res <-
      evaluate_spatial_mev_paired_benchmark(
        data_benchmark_runs = data_failed
      )

    testthat::expect_setequal(
      res[["data_gate_results"]] |>
        dplyr::filter(!.data[["passed"]]) |>
        dplyr::pull("criterion_id"),
      c("log_loss_regression", "auc_regression")
    )
    testthat::expect_identical(
      res[["data_benchmark_decision"]][["benchmark_status"]],
      "fail"
    )
  }
)

testthat::test_that(
  "evaluate_spatial_mev_paired_benchmark() rejects incomplete pairs",
  {
    data_incomplete <-
      make_spatial_mev_benchmark_fixture() |>
      dplyr::filter(
        !(
          .data[["repetition_id"]] == 3L &
            .data[["spatial_mev_strategy"]] == "fast"
        )
      )

    testthat::expect_error(
      evaluate_spatial_mev_paired_benchmark(
        data_benchmark_runs = data_incomplete
      ),
      regexp = "one exact and one fast"
    )
  }
)
