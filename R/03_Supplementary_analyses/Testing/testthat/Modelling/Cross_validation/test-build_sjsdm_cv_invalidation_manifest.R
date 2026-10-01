testthat::test_that(
  "build_sjsdm_cv_invalidation_manifest() preserves retained units",
  {
    data_audit <-
      tibble::tibble(
        analysis_id = base::c("paleo_spatial", "modern_spatial"),
        continent_id = base::c("europe", "america"),
        resolution_id = base::c("genus", "family"),
        store_path = base::c("paleo/europe", "modern/america"),
        retention_status = base::c(
          "retain_legacy_selection_and_model",
          "invalidate_cv_and_model_descendants"
        ),
        retention_reason = base::c(
          "stable_candidate_and_converged_model",
          "candidate_changed"
        )
      )

    result <-
      build_sjsdm_cv_invalidation_manifest(
        data_continental_audit = data_audit,
        regional_store_root = "paleo/regional",
        regional_units = "eu_r001",
        regional_tier_store = "paleo/regional/tier"
      )

    testthat::expect_false(
      base::any(
        result[["scope"]] == "continental_audit" &
          result[["unit_id"]] == "europe"
      )
    )
    testthat::expect_true(
      base::any(
        result[["scope"]] == "continental_audit" &
          result[["unit_id"]] == "america" &
          result[["target_name"]] == "mod_jsdm_family"
      )
    )
    testthat::expect_true(
      base::any(
        result[["scope"]] == "partial_regional_reset" &
          result[["unit_id"]] == "eu_r001" &
          result[["target_name"]] ==
            "list_sjsdm_tuning_work_item_result_genus"
      )
    )
    testthat::expect_true(
      base::any(
        result[["scope"]] == "partial_regional_tier_reset" &
          result[["target_name"]] ==
            "data_sjsdm_tier_survivor_decisions_round_1"
      )
    )
  }
)

testthat::test_that(
  "build_sjsdm_cv_invalidation_manifest() rejects pending audits",
  {
    data_audit <-
      tibble::tibble(
        analysis_id = "paleo_spatial",
        continent_id = "europe",
        resolution_id = "genus",
        store_path = "paleo/europe",
        retention_status = "pending_calibration",
        retention_reason = "missing"
      )

    testthat::expect_error(
      build_sjsdm_cv_invalidation_manifest(data_audit),
      "unresolved retention status"
    )
  }
)
