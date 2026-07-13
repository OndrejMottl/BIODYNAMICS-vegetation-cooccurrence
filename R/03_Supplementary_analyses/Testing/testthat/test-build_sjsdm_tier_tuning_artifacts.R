make_multiple_tier_artifact_test_data <- function() {
  res <-
    tidyr::crossing(
      source_id = base::c("id_a", "id_b"),
      repeat_id = 1L,
      taxonomic_resolution = base::c("genus", "family"),
      candidate_id = base::c("candidate_001", "candidate_002")
    ) |>
    dplyr::mutate(
      tier_id = "paleo_spatial_regional",
      response_family = "binomial",
      predictor_structure = "spatial=TRUE;mode=spatial",
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
      negative_log_likelihood_per_response = dplyr::if_else(
        .data[["candidate_id"]] == "candidate_001",
        0.2,
        0.4
      ),
      summary_status = "ok"
    )

  return(res)
}

testthat::test_that(
  "build_sjsdm_tier_tuning_artifacts() builds each compatible context",
  {
    created_at <-
      base::as.POSIXct("2026-07-13 12:00:00", tz = "UTC")

    res <-
      build_sjsdm_tier_tuning_artifacts(
        data_tuning_summary = make_multiple_tier_artifact_test_data(),
        created_at = created_at
      )

    testthat::expect_equal(
      base::nrow(res[["data_artifacts"]]),
      2L
    )
    testthat::expect_setequal(
      res[["data_artifacts"]][["taxonomic_resolution"]],
      base::c("genus", "family")
    )
    testthat::expect_true(
      base::all(
        res[["data_artifacts"]][["candidate_id"]] ==
          "candidate_001"
      )
    )
  }
)
