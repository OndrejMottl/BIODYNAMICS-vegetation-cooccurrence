testthat::test_that(
  "build_sjsdm_tier_tuning_artifact() retains provenance",
  {
    data_tuning_summary <-
      tidyr::crossing(
        source_id = base::c("id_b", "id_a"),
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
          .data[["source_id"]] == "id_b",
          100L,
          10L
        ),
        negative_log_likelihood_per_response = dplyr::if_else(
          .data[["candidate_id"]] == "candidate_001",
          0.2,
          0.5
        ),
        summary_status = "ok"
      )

    created_at <-
      base::as.POSIXct(
        "2026-07-05 12:00:00",
        tz = "UTC"
      )

    res <-
      build_sjsdm_tier_tuning_artifact(
        data_tuning_summary = data_tuning_summary,
        created_at = created_at
      )

    data_artifact <-
      res[["artifact"]]

    testthat::expect_equal(base::nrow(data_artifact), 1L)
    testthat::expect_equal(
      data_artifact[["artifact_schema_version"]],
      "2.0.0"
    )
    testthat::expect_equal(
      data_artifact[["candidate_id"]],
      "candidate_001"
    )
    testthat::expect_equal(
      data_artifact[["regularization_source"]],
      "tier_pooled"
    )
    testthat::expect_equal(
      data_artifact[["source_tier"]],
      "regional"
    )
    testthat::expect_equal(
      data_artifact[["candidate_table_hash"]],
      "candidate_hash_001"
    )
    testthat::expect_equal(
      data_artifact[["source_ids"]][[1L]],
      base::c("id_a", "id_b")
    )
    testthat::expect_equal(data_artifact[["created_at"]], created_at)
    testthat::expect_equal(
      data_artifact[["weighting_rule"]],
      "equal_id"
    )
    testthat::expect_equal(
      data_artifact[["selection_metric"]],
      "negative_log_likelihood_per_response"
    )
    testthat::expect_equal(
      base::names(res),
      base::c(
        "artifact",
        "source_candidate_loss",
        "candidate_aggregation",
        "selection_sensitivity"
      )
    )
  }
)

testthat::test_that(
  "build_sjsdm_tier_tuning_artifact() validates creation time",
  {
    testthat::expect_error(
      build_sjsdm_tier_tuning_artifact(
        data_tuning_summary = tibble::tibble(),
        created_at = "2026-07-05"
      ),
      "created_at"
    )
  }
)
