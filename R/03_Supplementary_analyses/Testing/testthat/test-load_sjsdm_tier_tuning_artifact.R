testthat::test_that(
  "load_sjsdm_tier_tuning_artifact() selects a compatible artifact",
  {
    data_artifacts <-
      tibble::tibble(
        tier_id = "paleo_spatial_regional",
        taxonomic_resolution = base::c("genus", "family"),
        response_family = "binomial",
        predictor_structure = "spatial=TRUE;mode=spatial",
        candidate_table_hash = "candidate_hash",
        candidate_id = base::c("candidate_001", "candidate_002")
      )

    data_context <-
      data_artifacts |>
      dplyr::filter(.data[["taxonomic_resolution"]] == "family") |>
      dplyr::select(-"candidate_id")

    res <-
      load_sjsdm_tier_tuning_artifact(
        store_path = "tier_store",
        data_model_context = data_context,
        read_target_function = function(name, store) {
          testthat::expect_equal(
            name,
            "data_sjsdm_tier_regularization_artifacts"
          )
          testthat::expect_equal(store, "tier_store")
          return(data_artifacts)
        }
      )

    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_equal(res[["candidate_id"]], "candidate_002")
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

    testthat::expect_null(res)
  }
)
