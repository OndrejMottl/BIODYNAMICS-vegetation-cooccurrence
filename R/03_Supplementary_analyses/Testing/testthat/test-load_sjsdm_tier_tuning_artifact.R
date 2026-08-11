testthat::test_that(
  "load_sjsdm_tier_tuning_artifact() selects a compatible artifact",
  {
    data_artifacts <-
      make_sjsdm_tier_payload_fixture(
        schema_version = "1.0.0"
      )[["data_regularization_selection"]]

    data_context <-
      data_artifacts |>
      dplyr::select(
        "tier_id",
        "taxonomic_resolution",
        "response_family",
        "predictor_structure",
        "candidate_table_hash"
      )

    res <-
      load_sjsdm_tier_tuning_artifact(
        store_path = "tier_store",
        data_model_context = data_context,
        read_target_function = function(name, store) {
          if (name == "list_sjsdm_tier_tuning_artifact") {
            base::stop("v2 target unavailable")
          }

          testthat::expect_equal(
            name,
            "data_sjsdm_tier_regularization_artifacts"
          )
          testthat::expect_equal(store, "tier_store")
          return(data_artifacts)
        }
      )

    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_equal(res[["candidate_id"]], "candidate_001")
    testthat::expect_equal(
      res[["artifact_schema_version"]],
      "2.0.0"
    )
  }
)

testthat::test_that(
  "load_sjsdm_tier_tuning_artifact() allows an unavailable store",
  {
    data_context <-
      tibble::tibble(
        tier_id = "paleo_spatial_regional",
        taxonomic_resolution = "genus",
        response_family = "binomial",
        predictor_structure = "spatial=TRUE;mode=spatial",
        candidate_table_hash = "candidate_hash"
      )

    res <-
      load_sjsdm_tier_tuning_artifact(
        store_path = "missing_store",
        data_model_context = data_context,
        read_target_function = function(name, store) {
          base::stop("missing")
        }
      )

    testthat::expect_identical(
      res,
      build_sjsdm_empty_tier_regularization_selection()
    )
  }
)
