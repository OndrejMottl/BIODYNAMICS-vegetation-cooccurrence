make_common_regularization_test_data <- function() {
  tidyr::crossing(
    tier_id = base::c("continental", "regional", "local"),
    source_id = base::c("id_a", "id_b"),
    repeat_id = 1L,
    candidate_id = base::c("candidate_001", "candidate_002")
  ) |>
    dplyr::mutate(
      taxonomic_resolution = "genus",
      response_family = "binomial",
      predictor_structure = stringr::str_c(
        "n_mev=",
        dplyr::case_when(
          .data[["tier_id"]] == "continental" ~ 5L,
          .data[["tier_id"]] == "regional" ~ 4L,
          .data[["tier_id"]] == "local" ~ 3L
        )
      ),
      candidate_table_hash = "candidate_hash",
      alpha_cov = 0.5,
      alpha_coef = 0.5,
      alpha_spatial = 0.5,
      lambda_cov = dplyr::if_else(
        .data[["candidate_id"]] == "candidate_001",
        0,
        0.1
      ),
      lambda_coef = 0,
      lambda_spatial = 0,
      n_response_values = 100L,
      negative_log_likelihood_per_response =
        dplyr::case_when(
          .data[["tier_id"]] == "continental" &
            .data[["candidate_id"]] == "candidate_001" ~ 0.1,
          .data[["tier_id"]] == "continental" ~ 0.4,
          .data[["candidate_id"]] == "candidate_001" ~ 0.9,
          TRUE ~ 0.2
        ),
      summary_status = "ok"
    )
}

testthat::test_that(
  "build_sjsdm_common_regularization_artifact() weights tiers equally",
  {
    created_at <-
      base::as.POSIXct("2026-07-13 12:00:00", tz = "UTC")

    res <-
      build_sjsdm_common_regularization_artifact(
        data_tuning_summary = make_common_regularization_test_data(),
        created_at = created_at
      )

    data_artifact <-
      res[["artifact"]]

    testthat::expect_equal(
      data_artifact[["candidate_id"]],
      "candidate_002"
    )
    testthat::expect_equal(
      data_artifact[["weighting_rule"]],
      "equal_tier_equal_id"
    )
    testthat::expect_equal(
      data_artifact[["regularization_source"]],
      "common_spatial_sensitivity"
    )
    testthat::expect_equal(data_artifact[["n_source_tiers"]], 3L)
    testthat::expect_setequal(
      data_artifact[["source_tiers"]][[1L]],
      base::c("continental", "regional", "local")
    )
    testthat::expect_setequal(
      data_artifact[["predictor_structures"]][[1L]],
      base::c("n_mev=5", "n_mev=4", "n_mev=3")
    )
    testthat::expect_equal(
      base::names(res),
      base::c("artifact", "tier_candidate_loss", "candidate_aggregation")
    )
  }
)

testthat::test_that(
  "build_sjsdm_common_regularization_artifact() rejects mixed contexts",
  {
    data_mixed <-
      make_common_regularization_test_data() |>
      dplyr::mutate(
        response_family = dplyr::if_else(
          .data[["tier_id"]] == "local",
          "poisson",
          .data[["response_family"]]
        )
      )

    testthat::expect_error(
      build_sjsdm_common_regularization_artifact(
        data_tuning_summary = data_mixed,
        created_at = base::Sys.time()
      ),
      "compatible"
    )
  }
)
