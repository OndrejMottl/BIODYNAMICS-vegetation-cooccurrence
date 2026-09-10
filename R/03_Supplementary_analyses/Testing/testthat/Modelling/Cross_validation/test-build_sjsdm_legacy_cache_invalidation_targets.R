testthat::test_that(
  "legacy cache collection follows target dependencies",
  {
    data_endpoints <-
      tibble::tibble(
        target_name = "folds_genus",
        endpoint_status = "cache_format_incompatible",
        error_message = paste(
          "could not load dependency data_checked of target folds_genus.",
          "there is no package called 'qs'"
        )
      )
    data_errors <-
      tibble::tibble(
        name = base::c("data_checked", "model_jsdm"),
        error = base::c(
          paste(
            "could not load dependency data_raw of target data_checked.",
            "there is no package called 'qs'"
          ),
          "Final model did not converge."
        )
      )

    testthat::expect_setequal(
      build_sjsdm_legacy_cache_invalidation_targets(
        data_endpoints = data_endpoints,
        data_target_errors = data_errors
      ),
      base::c(
        "folds_genus",
        "data_checked",
        "data_raw"
      )
    )
  }
)
