testthat::test_that(
  paste(
    "convert_v1_sjsdm_regularization_selection_artifact() upgrades",
    "the frozen v1 fixture"
  ),
  {
    payload <-
      base::list(
        data_unit_selection =
          build_sjsdm_empty_unit_regularization_selection(),
        data_tier_selection =
          make_sjsdm_tier_payload_fixture(
            schema_version = "1.0.0"
          )[["data_regularization_selection"]],
        data_selection_for_fit = tibble::tibble(
          tier_id = "paleo",
          taxonomic_resolution = "genus",
          response_family = "binomial",
          predictor_structure = "full",
          candidate_table_hash = "candidate_hash",
          candidate_id = NA_character_,
          alpha_cov = NA_real_,
          alpha_coef = NA_real_,
          alpha_spatial = NA_real_,
          lambda_cov = NA_real_,
          lambda_coef = NA_real_,
          lambda_spatial = NA_real_,
          cv_feasibility_status = "full_model_infeasible",
          regularization_source = "none",
          source_tier = NA_character_,
          selection_status = "full_model_infeasible"
        )
      )

    res <-
      convert_v1_sjsdm_regularization_selection_artifact(
        payload = payload,
        pipeline_id = "pipeline_test",
        configuration_profile = "project_test",
        created_at = base::as.POSIXct("2026-08-11", tz = "UTC")
      )

    testthat::expect_identical(
      res[["artifact_type"]],
      "sjsdm_regularization_selection"
    )
    testthat::expect_true(
      res[["provenance"]][["migration_applied"]]
    )
    testthat::expect_identical(
      res[["payload"]][["data_tier_selection"]][[
        "artifact_schema_version"
      ]],
      "2.0.0"
    )
  }
)
