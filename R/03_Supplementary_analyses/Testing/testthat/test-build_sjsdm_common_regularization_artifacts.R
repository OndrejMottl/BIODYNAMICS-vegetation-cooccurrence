testthat::test_that(
  "build_sjsdm_common_regularization_artifacts() separates resolutions",
  {
    data_tuning <-
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
        negative_log_likelihood_per_response = dplyr::if_else(
          .data[["candidate_id"]] == "candidate_001",
          0.4,
          0.2
        ),
        summary_status = "ok"
      ) |>
      tidyr::crossing(
        taxonomic_resolution_new = base::c("genus", "family")
      ) |>
      dplyr::mutate(
        taxonomic_resolution = .data[["taxonomic_resolution_new"]]
      ) |>
      dplyr::select(-"taxonomic_resolution_new")

    res <-
      build_sjsdm_common_regularization_artifacts(
        data_tuning_summary = data_tuning,
        created_at = base::as.POSIXct(
          "2026-07-13 12:00:00",
          tz = "UTC"
        )
      )

    testthat::expect_equal(base::nrow(res[["data_artifacts"]]), 2L)
    testthat::expect_setequal(
      res[["data_artifacts"]][["taxonomic_resolution"]],
      base::c("genus", "family")
    )
  }
)
