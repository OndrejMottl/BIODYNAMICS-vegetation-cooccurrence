testthat::test_that("migration preserves fits, budgets and previous history", {
  config_model <-
    base::list(use_age_in_formula = FALSE,
      cross_validation = base::list(regularization = base::list(
        alpha_cov = 0.5, alpha_coef = 0.5, alpha_spatial = 0.5,
        lambda_cov = 0.1, lambda_coef = 0.1, lambda_spatial = 0.1
      )))
  list_folds <-
    base::list(fold_1 = base::list(preparation_status = "ok",
      list_prepared_fold = base::list(data_train_input = base::list(
        data_abiotic_to_fit = tibble::tibble(temperature = 1:3)
      ))
    ))
  list_hashes <-
    validate_sjsdm_cv_calibration_evidence(NULL, list_folds,
      config_model)[["list_hashes"]]
  list_result <-
    base::list(calibration_status = "accepted",
      calibration_contract_version = "sjsdm_cv_adaptive_calibration_v4",
      calibration_input_hash = list_hashes[["legacy_v4_hash"]],
      legacy_calibration_input_hash = "earlier_hash",
      data_accepted_budget = tibble::tibble(n_iter_initial = 500L),
      data_benchmark = tibble::tibble(loss = 0.2),
      data_fit_attempts = tibble::tibble(runtime_seconds = 5),
      run_provenance = tibble::tibble(commit = "original",
        migration_status = NA_character_))
  list_migrated <-
    prepare_sjsdm_cv_calibration_result_migration(
      list_result, list_folds, config_model,
      migrated_at = base::as.POSIXct("2026-10-13", tz = "UTC")
    )
  vec_scientific_fields <-
    base::c("data_accepted_budget", "data_benchmark", "data_fit_attempts")
  testthat::expect_identical(list_result[vec_scientific_fields],
    list_migrated[vec_scientific_fields])
  testthat::expect_identical(list_migrated[["calibration_contract_version"]],
    "sjsdm_cv_adaptive_calibration_v5")
  testthat::expect_identical(list_migrated[["list_migration_history"]][[1L]][[
    "legacy_calibration_input_hash"]], "earlier_hash")
  testthat::expect_identical(list_migrated[["legacy_run_provenance"]],
    list_result[["run_provenance"]])
  testthat::expect_identical(list_migrated[["run_provenance"]][[
    "migration_status"]], "reused_content_matched_v4_result")
  testthat::expect_identical(
    prepare_sjsdm_cv_calibration_result_migration(
      list_migrated, list_folds, config_model
    ), list_migrated
  )
  list_changed <- list_folds
  list_changed[[1L]][["list_prepared_fold"]][["data_train_input"]][[
    "data_abiotic_to_fit"]][["temperature"]] <- 4:6
  testthat::expect_error(prepare_sjsdm_cv_calibration_result_migration(
    list_result, list_changed, config_model
  ), "incompatible|verified")
})
