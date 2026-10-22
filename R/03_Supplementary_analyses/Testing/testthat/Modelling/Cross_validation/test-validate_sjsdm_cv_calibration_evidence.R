testthat::test_that("accepted status cannot hide changed calibration inputs", {
  config_model <-
    base::list(use_age_in_formula = FALSE,
      cross_validation = base::list(regularization = base::list(
        alpha_cov = 0.5, alpha_coef = 0.5, alpha_spatial = 0.5,
        lambda_cov = 0.1, lambda_coef = 0.1, lambda_spatial = 0.1
      )))
  list_folds <-
    base::list(fold_1 = base::list(
      preparation_status = "ok", preparation_seconds = 1,
      list_prepared_fold = base::list(data_train_input = base::list(
        data_abiotic_to_fit = tibble::tibble(temperature = 1:3)
      ))
    ))
  list_check <-
    validate_sjsdm_cv_calibration_evidence(NULL, list_folds, config_model)
  testthat::expect_identical(list_check[["status"]], "missing")
  list_result <-
    base::list(
      calibration_status = "accepted",
      calibration_contract_version = "sjsdm_cv_adaptive_calibration_v5",
      calibration_input_hash =
        list_check[["list_hashes"]][["calibration_input_hash"]]
    )
  testthat::expect_identical(
    validate_sjsdm_cv_calibration_evidence(
      list_result, list_folds, config_model
    )[["status"]], "accepted"
  )
  config_final_changed <-
    config_model
  config_final_changed[["n_iter"]] <-
    64000L
  testthat::expect_identical(
    validate_sjsdm_cv_calibration_evidence(
      list_result, list_folds, config_final_changed
    )[["status"]], "accepted"
  )
  list_incomplete <-
    base::c(list_folds, base::list(fold_2 = base::list(
      preparation_status = "preparation_error", error_message = "data error"
    )))
  testthat::expect_identical(
    validate_sjsdm_cv_calibration_evidence(
      list_result, list_incomplete, config_model
    )[["status"]], "incomplete_preparation"
  )
  list_result[["calibration_status"]] <-
    "no_accepted_budget"
  testthat::expect_identical(
    validate_sjsdm_cv_calibration_evidence(
      list_result, list_folds, config_model
    )[["status"]], "not_accepted"
  )
  list_result[["calibration_status"]] <-
    "accepted"
  list_result[["calibration_contract_version"]] <-
    "sjsdm_cv_adaptive_calibration_v3"
  list_result[["calibration_input_hash"]] <-
    list_check[["list_hashes"]][["legacy_v3_hash"]]
  testthat::expect_identical(
    validate_sjsdm_cv_calibration_evidence(
      list_result, list_folds, config_model
    )[["migration_status"]], "reused_content_matched_v3_result"
  )
  list_result[["calibration_input_hash"]] <-
    list_check[["list_hashes"]][["previous_policy_v3_hash"]]
  testthat::expect_identical(
    validate_sjsdm_cv_calibration_evidence(
      list_result, list_folds, config_model
    )[["migration_status"]], "reused_stricter_v3_policy_result"
  )
  list_result[["calibration_contract_version"]] <-
    "sjsdm_cv_adaptive_calibration_v2"
  list_result[["calibration_input_hash"]] <-
    list_check[["list_hashes"]][["legacy_v2_hash"]]
  testthat::expect_identical(
    validate_sjsdm_cv_calibration_evidence(
      list_result, list_folds, config_model
    )[["migration_status"]], "reused_stricter_v2_result"
  )
  list_folds[[1L]][["preparation_seconds"]] <-
    2
  testthat::expect_identical(
    validate_sjsdm_cv_calibration_evidence(
      list_result, list_folds, config_model
    )[["status"]], "incompatible_inputs"
  )
  list_result[["calibration_contract_version"]] <-
    "sjsdm_cv_adaptive_calibration_v5"
  list_result[["calibration_input_hash"]] <-
    list_check[["list_hashes"]][["calibration_input_hash"]]
  testthat::expect_identical(
    validate_sjsdm_cv_calibration_evidence(
      list_result, list_folds, config_model
    )[["status"]], "accepted"
  )
  list_folds[[1L]][["list_prepared_fold"]][[
    "data_train_input"
  ]][["data_abiotic_to_fit"]][["temperature"]] <-
    4:6
  testthat::expect_identical(
    validate_sjsdm_cv_calibration_evidence(
      list_result, list_folds, config_model
    )[["status"]], "incompatible_inputs"
  )
})

testthat::test_that("v4 memory migration requires complete original proof", {
  config_model <-
    base::list(use_age_in_formula = FALSE,
      cross_validation = base::list(regularization = base::list(
        alpha_cov = 0.5, alpha_coef = 0.5, alpha_spatial = 0.5,
        lambda_cov = 0.1, lambda_coef = 0.1, lambda_spatial = 0.1
      )))
  list_historical <-
    base::list(fold_1 = base::list(preparation_status = "ok",
      list_prepared_fold = base::list(
        data_train_input = base::list(
          data_abiotic_to_fit = tibble::tibble(temperature = 1:3)
        ),
        data_spatial_provenance = tibble::tibble(basis_bytes = 100),
        response = base::matrix(1, 1L, 1L)
      )
    ))
  list_hashes <-
    validate_sjsdm_cv_calibration_evidence(NULL, list_historical,
      config_model)[["list_hashes"]]
  list_result <-
    base::list(calibration_status = "accepted",
      calibration_contract_version = "sjsdm_cv_adaptive_calibration_v4",
      calibration_input_hash = list_hashes[["legacy_v4_hash"]])
  list_current <- list_historical
  list_current[[1L]][["list_prepared_fold"]][[
    "data_spatial_provenance"
  ]][["basis_bytes"]] <- 200
  testthat::expect_identical(
    validate_sjsdm_cv_calibration_evidence(list_result, list_current,
      config_model)[["status"]], "incompatible_inputs"
  )
  testthat::expect_identical(
    validate_sjsdm_cv_calibration_evidence(list_result, list_current,
      config_model, list_legacy_prepared_folds = list_historical)[[
      "migration_status"]], "reused_verified_v4_operational_evidence"
  )
  list_current[[1L]][["list_prepared_fold"]][["response"]] <-
    base::matrix(0, 1L, 1L)
  testthat::expect_identical(
    validate_sjsdm_cv_calibration_evidence(list_result, list_current,
      config_model, list_legacy_prepared_folds = list_historical)[[
      "status"]], "incompatible_inputs"
  )
})
