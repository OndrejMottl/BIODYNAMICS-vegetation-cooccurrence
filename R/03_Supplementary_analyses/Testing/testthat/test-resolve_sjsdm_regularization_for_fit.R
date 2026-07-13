make_regularization_resolution_test_candidate <- function() {
  res <-
    tibble::tibble(
      candidate_id = "candidate_001",
      alpha_cov = 0.5,
      alpha_coef = 0.5,
      alpha_spatial = 0.5,
      lambda_cov = 0.1,
      lambda_coef = 0.1,
      lambda_spatial = 0.1
    )

  return(res)
}

make_regularization_resolution_test_context <- function() {
  res <-
    tibble::tibble(
      tier_id = "regional",
      taxonomic_resolution = "genus",
      response_family = "binomial",
      predictor_structure = "abiotic_spatial",
      candidate_table_hash = "candidate_hash_001"
    )

  return(res)
}

testthat::test_that(
  "resolve_sjsdm_regularization_for_fit() resolves supported states",
  {
    data_context <-
      make_regularization_resolution_test_context()

    data_candidate <-
      make_regularization_resolution_test_candidate()

    data_unit <-
      resolve_sjsdm_regularization_for_fit(
        data_feasibility = tibble::tibble(
          cv_feasibility_status = "grouped_kfold_feasible"
        ),
        data_model_context = data_context,
        data_unit_selection = data_candidate
      )

    data_tier_artifact <-
      dplyr::bind_cols(
        data_context,
        data_candidate
      ) |>
      dplyr::mutate(
        regularization_source = "tier_pooled",
        source_tier = "regional"
      )

    data_tier <-
      resolve_sjsdm_regularization_for_fit(
        data_feasibility = tibble::tibble(
          cv_feasibility_status =
            "tier_pooled_regularization_required"
        ),
        data_model_context = data_context,
        data_tier_artifact = data_tier_artifact
      )

    data_no_model <-
      resolve_sjsdm_regularization_for_fit(
        data_feasibility = tibble::tibble(
          cv_feasibility_status = "full_model_infeasible"
        ),
        data_model_context = data_context
      )

    testthat::expect_equal(
      data_unit[["regularization_source"]],
      "unit_cv"
    )
    testthat::expect_true(base::is.na(data_unit[["source_tier"]]))
    testthat::expect_equal(
      data_tier[["regularization_source"]],
      "tier_pooled"
    )
    testthat::expect_equal(data_tier[["source_tier"]], "regional")
    testthat::expect_equal(
      data_tier[["candidate_id"]],
      "candidate_001"
    )
    testthat::expect_equal(
      data_no_model[["selection_status"]],
      "full_model_infeasible"
    )
    testthat::expect_equal(
      data_no_model[["regularization_source"]],
      "none"
    )
    testthat::expect_true(base::is.na(data_no_model[["candidate_id"]]))
  }
)

testthat::test_that(
  "resolve_sjsdm_regularization_for_fit() rejects artifact mismatch",
  {
    data_context <-
      make_regularization_resolution_test_context()

    data_tier_artifact <-
      dplyr::bind_cols(
        data_context,
        make_regularization_resolution_test_candidate()
      ) |>
      dplyr::mutate(
        taxonomic_resolution = "family",
        regularization_source = "tier_pooled",
        source_tier = "regional"
      )

    testthat::expect_error(
      resolve_sjsdm_regularization_for_fit(
        data_feasibility = tibble::tibble(
          cv_feasibility_status =
            "tier_pooled_regularization_required"
        ),
        data_model_context = data_context,
        data_tier_artifact = data_tier_artifact
      ),
      "does not match"
    )
  }
)
