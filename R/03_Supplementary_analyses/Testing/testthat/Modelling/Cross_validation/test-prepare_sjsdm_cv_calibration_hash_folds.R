testthat::test_that("calibration hashes exclude only operational runtimes", {
  list_folds <-
    base::list(fold_1 = base::list(
      preparation_status = "ok",
      preparation_seconds = 10,
      list_fold_context = base::list(fold_id = 1L, seed = 42L),
      list_prepared_fold = base::list(
        data_train_input = base::list(
          data_abiotic_to_fit = tibble::tibble(elapsed_seconds = 3)
        ),
        data_train_observed = base::matrix(1, 1L, 1L),
        data_spatial_provenance = tibble::tibble(
          strategy_selected = "dense", elapsed_seconds = 20
        )
      )
    ))
  list_changed <-
    list_folds
  list_changed[[1L]][["preparation_seconds"]] <-
    100
  list_changed[[1L]][["list_prepared_fold"]][[
    "data_spatial_provenance"
  ]][["elapsed_seconds"]] <-
    200
  list_normalized <-
    prepare_sjsdm_cv_calibration_hash_folds(list_folds)
  testthat::expect_identical(
    list_normalized,
    prepare_sjsdm_cv_calibration_hash_folds(list_changed)
  )
  testthat::expect_equal(list_folds[[1L]][["preparation_seconds"]], 10)
  testthat::expect_equal(
    list_normalized[[1L]][["list_prepared_fold"]][[
      "data_train_input"
    ]][["data_abiotic_to_fit"]][["elapsed_seconds"]], 3
  )
  for (
    field_id in base::c("data_train_observed", "data_spatial_provenance")
  ) {
    list_changed <-
      list_folds
    list_changed[[1L]][["list_prepared_fold"]][[field_id]] <-
      "changed scientific content"
    testthat::expect_false(base::identical(
      list_normalized,
      prepare_sjsdm_cv_calibration_hash_folds(list_changed)
    ))
  }
  list_changed <-
    list_folds
  list_changed[[1L]][["list_fold_context"]][["seed"]] <-
    43L
  testthat::expect_false(base::identical(
    list_normalized,
    prepare_sjsdm_cv_calibration_hash_folds(list_changed)
  ))
})

testthat::test_that("empty and failed fold records retain their meaning", {
  testthat::expect_identical(
    prepare_sjsdm_cv_calibration_hash_folds(base::list()), base::list()
  )
  list_failed <-
    base::list(fold_1 = base::list(
      preparation_status = "error", error_message = "insufficient taxa"
    ))
  testthat::expect_identical(
    prepare_sjsdm_cv_calibration_hash_folds(list_failed), list_failed
  )
  testthat::expect_error(
    prepare_sjsdm_cv_calibration_hash_folds("not folds"), "must be a list"
  )
})
