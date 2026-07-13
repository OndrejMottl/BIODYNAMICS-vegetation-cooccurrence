make_tier_tuning_test_data <- function() {
  data_tuning_summary <-
    tidyr::crossing(
      source_id = base::c("large_id", "small_id"),
      repeat_id = 1:2,
      candidate_id = base::c("candidate_001", "candidate_002")
    ) |>
    dplyr::mutate(
      tier_id = "regional",
      taxonomic_resolution = "genus",
      response_family = "binomial",
      predictor_structure = "abiotic_spatial",
      candidate_table_hash = "candidate_hash_001",
      alpha_cov = 0.5,
      alpha_coef = 0.5,
      alpha_spatial = 0.5,
      lambda_cov = dplyr::if_else(
        .data[["candidate_id"]] == "candidate_001",
        0.1,
        0.2
      ),
      lambda_coef = 0.1,
      lambda_spatial = 0.1,
      n_response_values = dplyr::if_else(
        .data[["source_id"]] == "large_id",
        500L,
        5L
      ),
      negative_log_likelihood_per_response = dplyr::case_when(
        .data[["source_id"]] == "small_id" &
          .data[["candidate_id"]] == "candidate_001" ~ 0.1,
        .data[["source_id"]] == "small_id" ~ 0.9,
        .data[["candidate_id"]] == "candidate_001" ~ 0.6,
        .default = 0.4
      ),
      summary_status = "ok"
    )

  return(data_tuning_summary)
}

testthat::test_that(
  "aggregate_sjsdm_tuning_by_tier() weights source IDs equally",
  {
    data_tuning_summary <-
      make_tier_tuning_test_data()

    res <-
      aggregate_sjsdm_tuning_by_tier(
        data_tuning_summary = data_tuning_summary
      )

    data_source_loss <-
      res[["source_candidate_loss"]]

    data_aggregation <-
      res[["candidate_aggregation"]]

    data_selection <-
      res[["selection_sensitivity"]]

    testthat::expect_equal(base::nrow(data_source_loss), 4L)
    testthat::expect_equal(base::nrow(data_aggregation), 2L)
    testthat::expect_equal(base::nrow(data_selection), 2L)

    data_candidate_one <-
      data_aggregation |>
      dplyr::filter(.data[["candidate_id"]] == "candidate_001")

    data_candidate_two <-
      data_aggregation |>
      dplyr::filter(.data[["candidate_id"]] == "candidate_002")

    testthat::expect_equal(
      data_candidate_one[["normalized_loss_equal_id"]],
      0.35
    )
    testthat::expect_equal(
      data_candidate_two[["normalized_loss_equal_id"]],
      0.65
    )
    testthat::expect_equal(
      data_candidate_one[["normalized_loss_sample_weighted"]],
      (0.6 * 1000 + 0.1 * 10) / 1010
    )
    testthat::expect_true(
      base::all(data_aggregation[["aggregation_status"]] == "ok")
    )

    data_primary <-
      data_selection |>
      dplyr::filter(.data[["weighting_rule"]] == "equal_id")

    data_sensitivity <-
      data_selection |>
      dplyr::filter(.data[["weighting_rule"]] == "sample_weighted")

    testthat::expect_equal(
      data_primary[["candidate_id"]],
      "candidate_001"
    )
    testthat::expect_equal(
      data_sensitivity[["candidate_id"]],
      "candidate_002"
    )
    testthat::expect_true(data_sensitivity[["differs_from_primary"]])
  }
)

testthat::test_that(
  "aggregate_sjsdm_tuning_by_tier() excludes incomplete candidates",
  {
    data_tuning_summary <-
      make_tier_tuning_test_data() |>
      dplyr::mutate(
        summary_status = dplyr::if_else(
          .data[["source_id"]] == "small_id" &
            .data[["candidate_id"]] == "candidate_001" &
            .data[["repeat_id"]] == 2L,
          "incomplete",
          .data[["summary_status"]]
        ),
        negative_log_likelihood_per_response = dplyr::if_else(
          .data[["summary_status"]] == "incomplete",
          NA_real_,
          .data[["negative_log_likelihood_per_response"]]
        )
      )

    res <-
      aggregate_sjsdm_tuning_by_tier(
        data_tuning_summary = data_tuning_summary
      )

    data_candidate_one <-
      res[["candidate_aggregation"]] |>
      dplyr::filter(.data[["candidate_id"]] == "candidate_001")

    data_primary <-
      res[["selection_sensitivity"]] |>
      dplyr::filter(.data[["weighting_rule"]] == "equal_id")

    testthat::expect_equal(
      data_candidate_one[["aggregation_status"]],
      "incomplete_source_evidence"
    )
    testthat::expect_true(
      base::is.na(data_candidate_one[["normalized_loss_equal_id"]])
    )
    testthat::expect_equal(
      data_primary[["candidate_id"]],
      "candidate_002"
    )
  }
)

testthat::test_that(
  "aggregate_sjsdm_tuning_by_tier() rejects mixed model contexts",
  {
    data_tuning_summary <-
      make_tier_tuning_test_data()

    vec_context_columns <-
      base::c(
        "tier_id",
        "taxonomic_resolution",
        "response_family",
        "predictor_structure",
        "candidate_table_hash"
      )

    purrr::walk(
      vec_context_columns,
      .f = ~ {
        data_mixed <-
          data_tuning_summary

        data_mixed[[.x]][data_mixed[["source_id"]] == "small_id"] <-
          stringr::str_c(data_mixed[[.x]][[1L]], "_mixed")

        testthat::expect_error(
          aggregate_sjsdm_tuning_by_tier(
            data_tuning_summary = data_mixed
          ),
          "one compatible model context"
        )
      }
    )
  }
)

testthat::test_that(
  "aggregate_sjsdm_tuning_by_tier() rejects candidate-table drift",
  {
    data_tuning_summary <-
      make_tier_tuning_test_data() |>
      dplyr::filter(
        !(
          .data[["source_id"]] == "small_id" &
            .data[["candidate_id"]] == "candidate_002"
        )
      )

    testthat::expect_error(
      aggregate_sjsdm_tuning_by_tier(
        data_tuning_summary = data_tuning_summary
      ),
      "same candidate table"
    )

    data_parameter_drift <-
      make_tier_tuning_test_data() |>
      dplyr::mutate(
        lambda_cov = dplyr::if_else(
          .data[["source_id"]] == "small_id" &
            .data[["candidate_id"]] == "candidate_001",
          0.3,
          .data[["lambda_cov"]]
        )
      )

    testthat::expect_error(
      aggregate_sjsdm_tuning_by_tier(
        data_tuning_summary = data_parameter_drift
      ),
      "same candidate table"
    )
  }
)
