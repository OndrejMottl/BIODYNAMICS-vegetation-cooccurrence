testthat::test_that(
  "resolve_cross_validation_fold_count() keeps viable default folds",
  {
    data_resolution <-
      resolve_cross_validation_fold_count(
        n_locations = 7L,
        min_train_locations = 5L,
        default_folds = 5L
      )

    testthat::expect_s3_class(data_resolution, "tbl_df")
    testthat::expect_named(
      data_resolution,
      base::c(
        "n_locations",
        "default_folds",
        "effective_folds",
        "min_train_locations",
        "min_training_locations_actual",
        "cv_strategy",
        "cv_feasibility_status"
      )
    )
    testthat::expect_equal(
      dplyr::pull(data_resolution, effective_folds),
      5L
    )
    testthat::expect_equal(
      dplyr::pull(data_resolution, min_training_locations_actual),
      5L
    )
    testthat::expect_equal(
      dplyr::pull(data_resolution, cv_strategy),
      "spatially_stratified_group_kfold"
    )
    testthat::expect_equal(
      dplyr::pull(data_resolution, cv_feasibility_status),
      "grouped_kfold_feasible"
    )
  }
)

testthat::test_that(
  "resolve_cross_validation_fold_count() increases toward leave-one-out",
  {
    data_resolution <-
      resolve_cross_validation_fold_count(
        n_locations = 6L,
        min_train_locations = 5L,
        default_folds = 5L
      )

    testthat::expect_equal(
      dplyr::pull(data_resolution, effective_folds),
      6L
    )
    testthat::expect_equal(
      dplyr::pull(data_resolution, min_training_locations_actual),
      5L
    )
    testthat::expect_equal(
      dplyr::pull(data_resolution, cv_strategy),
      "leave_one_location_out"
    )
    testthat::expect_equal(
      dplyr::pull(data_resolution, cv_feasibility_status),
      "leave_one_location_out_required"
    )
  }
)

testthat::test_that(
  "resolve_cross_validation_fold_count() classifies infeasible holdouts",
  {
    data_tier_pooled <-
      resolve_cross_validation_fold_count(
        n_locations = 5L,
        min_train_locations = 5L
      )

    data_no_model <-
      resolve_cross_validation_fold_count(
        n_locations = 4L,
        min_train_locations = 5L
      )

    testthat::expect_true(
      base::is.na(dplyr::pull(data_tier_pooled, effective_folds))
    )
    testthat::expect_equal(
      dplyr::pull(data_tier_pooled, cv_strategy),
      "none"
    )
    testthat::expect_equal(
      dplyr::pull(data_tier_pooled, cv_feasibility_status),
      "tier_pooled_regularization_required"
    )
    testthat::expect_equal(
      dplyr::pull(data_no_model, cv_feasibility_status),
      "full_model_infeasible"
    )
  }
)

testthat::test_that(
  "resolve_cross_validation_fold_count() validates counts",
  {
    testthat::expect_error(
      resolve_cross_validation_fold_count(
        n_locations = 6.5,
        min_train_locations = 5L
      ),
      "n_locations"
    )

    testthat::expect_error(
      resolve_cross_validation_fold_count(
        n_locations = 6L,
        min_train_locations = 0L
      ),
      "min_train_locations"
    )

    testthat::expect_error(
      resolve_cross_validation_fold_count(
        n_locations = 6L,
        min_train_locations = 5L,
        default_folds = 1L
      ),
      "default_folds"
    )
  }
)
