testthat::test_that(
  "convert_v1_sjsdm_tier_regularization_selection() is strict",
  {
    data_v1 <-
      build_sjsdm_empty_tier_regularization_selection()

    res <-
      convert_v1_sjsdm_tier_regularization_selection(data_v1)

    testthat::expect_identical(
      res[["artifact_schema_version"]],
      base::character()
    )

    data_unknown <-
      tibble::add_row(
        data_v1,
        artifact_schema_version = "0.9.0",
        created_at = base::as.POSIXct("2026-08-11", tz = "UTC"),
        tier_id = "regional",
        source_tier = "regional",
        taxonomic_resolution = "genus",
        response_family = "binomial",
        predictor_structure = "abiotic_spatial",
        candidate_table_hash = "candidate_hash",
        candidate_id = "candidate_001",
        alpha_cov = 0.5,
        alpha_coef = 0.5,
        alpha_spatial = 0.5,
        lambda_cov = 0.1,
        lambda_coef = 0.1,
        lambda_spatial = 0.1,
        regularization_source = "tier_pooled",
        weighting_rule = "equal_id",
        selection_metric =
          "negative_log_likelihood_per_response",
        selection_metric_value = 0.2,
        n_source_ids = 2L,
        source_ids = base::list(base::c("id_a", "id_b"))
      )

    testthat::expect_error(
      convert_v1_sjsdm_tier_regularization_selection(data_unknown),
      "invalid status"
    )
  }
)
