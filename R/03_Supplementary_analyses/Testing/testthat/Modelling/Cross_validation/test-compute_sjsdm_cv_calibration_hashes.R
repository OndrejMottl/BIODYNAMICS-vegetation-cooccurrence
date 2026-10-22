testthat::test_that("scientific signatures retain exact legacy proof", {
  data_candidates <-
    tibble::tibble(candidate_id = "candidate_001")
  list_folds <-
    base::list(fold_1 = base::list(
      preparation_seconds = 1, response = base::matrix(1, 1L, 1L)
    ))
  config_cv <-
    base::list(seed = 42L)
  list_hashes <-
    compute_sjsdm_cv_calibration_hashes(
      data_candidates, list_folds, ~ x, config_cv
    )
  list_raw <-
    base::list(
      calibration_contract_version = "sjsdm_cv_adaptive_calibration_v3",
      data_candidates = data_candidates,
      list_prepared_folds = list_folds,
      formula_jsdm_environment = "~x",
      config_sjsdm_cv_fitting = config_cv,
      repeat_confirmation_loss_tolerance = 0.02
    )
  testthat::expect_identical(
    list_hashes[["legacy_v3_hash"]], digest::digest(list_raw)
  )
  list_changed <-
    list_folds
  list_changed[[1L]][["preparation_seconds"]] <-
    99
  list_changed_hashes <-
    compute_sjsdm_cv_calibration_hashes(
      data_candidates, list_changed, ~ x, config_cv
    )
  testthat::expect_identical(
    list_hashes[["calibration_input_hash"]],
    list_changed_hashes[["calibration_input_hash"]]
  )
  testthat::expect_false(base::identical(
    list_hashes[["legacy_v3_hash"]],
    list_changed_hashes[["legacy_v3_hash"]]
  ))
  list_changed[[1L]][["response"]] <-
    base::matrix(0, 1L, 1L)
  testthat::expect_false(base::identical(
    list_hashes[["calibration_input_hash"]],
    compute_sjsdm_cv_calibration_hashes(
      data_candidates, list_changed, ~ x, config_cv
    )[["calibration_input_hash"]]
  ))
  testthat::expect_false(base::identical(
    list_hashes[["calibration_input_hash"]],
    compute_sjsdm_cv_calibration_hashes(
      data_candidates, list_folds, ~ y, config_cv
    )[["calibration_input_hash"]]
  ))
  testthat::expect_named(list_hashes[["fold_content_hashes"]], "fold_1")
  testthat::expect_error(
    compute_sjsdm_cv_calibration_hashes(
      data_candidates, list_folds, ~ x, config_cv, NA_real_
    )
  )
})

testthat::test_that("v5 excludes bytes but preserves exact v4 fingerprints", {
  list_folds <-
    base::list(fold_1 = base::list(
      preparation_status = "ok",
      list_prepared_fold = base::list(
        response = base::matrix(1, 1L, 1L),
        data_spatial_provenance = tibble::tibble(
          basis_bytes = 100, estimated_dense_matrix_bytes = 800,
          strategy_selected = "exact"
        )
      )
    ))
  list_hashes <-
    compute_sjsdm_cv_calibration_hashes(
      tibble::tibble(candidate_id = "one"), list_folds, ~ x,
      base::list(seed = 42L)
    )
  testthat::expect_identical(list_hashes[["calibration_contract_version"]],
    "sjsdm_cv_adaptive_calibration_v5")
  list_changed <- list_folds
  list_changed[[1L]][["list_prepared_fold"]][[
    "data_spatial_provenance"
  ]][["basis_bytes"]] <- 200
  list_changed_hashes <-
    compute_sjsdm_cv_calibration_hashes(
      tibble::tibble(candidate_id = "one"), list_changed, ~ x,
      base::list(seed = 42L)
    )
  testthat::expect_identical(list_hashes[["calibration_input_hash"]],
    list_changed_hashes[["calibration_input_hash"]])
  testthat::expect_false(base::identical(list_hashes[["legacy_v4_hash"]],
    list_changed_hashes[["legacy_v4_hash"]]))
  testthat::expect_false(base::identical(
    list_hashes[["legacy_v4_fold_content_hashes"]],
    list_changed_hashes[["legacy_v4_fold_content_hashes"]]
  ))
})
