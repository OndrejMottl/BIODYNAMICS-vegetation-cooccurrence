testthat::test_that(
  "build_sjsdm_artifact_registry() defines v2 payloads",
  {
    list_registry <-
      build_sjsdm_artifact_registry()

    testthat::expect_named(
      list_registry,
      base::c(
        "cross_validation_shared_design",
        "cross_validation_design",
        "sjsdm_cv_tuning",
        "sjsdm_regularization_selection",
        "sjsdm_cv_predictions",
        "sjsdm_cv_evaluation",
        "sjsdm_tier_tuning",
        "sjsdm_common_regularization"
      )
    )

    testthat::expect_identical(
      list_registry[["sjsdm_cv_predictions"]],
      base::c("data_predictions", "data_fold_diagnostics")
    )

    testthat::expect_true(
      base::all(
        purrr::map_lgl(
          list_registry,
          ~ base::is.character(.x) &&
            base::length(.x) > 0L &&
            !base::any(base::duplicated(.x))
        )
      )
    )
  }
)
