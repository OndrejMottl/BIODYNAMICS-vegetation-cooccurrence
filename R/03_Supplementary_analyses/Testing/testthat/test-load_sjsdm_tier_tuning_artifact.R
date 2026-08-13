testthat::test_that(
  "load_sjsdm_tier_tuning_artifact() reads native v2 evidence",
  {
    payload <-
      make_sjsdm_tier_payload_fixture(
        schema_version = "2.0.0"
      )

    list_artifact <-
      build_sjsdm_artifact_envelope(
        artifact_type = "sjsdm_tier_tuning",
        payload = payload,
        provenance = build_sjsdm_artifact_provenance(
          pipeline_id = "pipeline_sjsdm_tier_tuning",
          configuration_profile = "project_test"
        )
      )

    data_artifacts <-
      payload[["data_regularization_selection"]]

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
          testthat::expect_equal(
            name,
            "list_sjsdm_tier_tuning_artifact"
          )
          testthat::expect_equal(store, "tier_store")
          return(list_artifact)
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
    environment_reads <-
      base::new.env(parent = base::emptyenv())
    environment_reads[["names"]] <- base::character()

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
          environment_reads[["names"]] <-
            base::c(environment_reads[["names"]], name)
          base::stop("missing")
        }
      )

    testthat::expect_identical(
      res,
      build_sjsdm_empty_tier_regularization_selection()
    )
    testthat::expect_identical(
      environment_reads[["names"]],
      "list_sjsdm_tier_tuning_artifact"
    )
  }
)

testthat::test_that(
  "load_sjsdm_tier_tuning_artifact() rejects a raw legacy table",
  {
    payload <-
      make_sjsdm_tier_payload_fixture(schema_version = "2.0.0")

    data_context <-
      payload[["data_regularization_selection"]] |>
      dplyr::select(
        "tier_id",
        "taxonomic_resolution",
        "response_family",
        "predictor_structure",
        "candidate_table_hash"
      )

    testthat::expect_error(
      load_sjsdm_tier_tuning_artifact(
        store_path = "legacy_store",
        data_model_context = data_context,
        read_target_function = function(name, store) {
          payload[["data_regularization_selection"]]
        }
      ),
      "exact v2 envelope"
    )
  }
)
