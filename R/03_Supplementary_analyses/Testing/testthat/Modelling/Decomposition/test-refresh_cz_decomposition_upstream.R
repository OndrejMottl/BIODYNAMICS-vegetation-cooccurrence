testthat::test_that(
  "refresh_cz_decomposition_upstream() validates target status",
  {
    flag_ran_pipeline <- FALSE

    run_pipeline_fn <- function(...) {
      flag_ran_pipeline <<- TRUE
    }

    tar_meta_fn <- function(fields, complete_only, store) {
      tibble::tibble(
        name = c(
          "data_sample_ids_checked_genus",
          "data_community_model_matrix_genus",
          "data_abiotic_wide_genus",
          "data_spatial_mev_core",
          "data_coords_projected",
          "config_data_processing",
          "config_model_fitting",
          "config_spatial_predictors"
        ),
        error = NA_character_
      )
    }

    res <-
      refresh_cz_decomposition_upstream(
        refresh_upstream = TRUE,
        store_path = "store",
        pipeline_script = "script.R",
        run_pipeline_fn = run_pipeline_fn,
        tar_meta_fn = tar_meta_fn,
        verbose = FALSE
      )

    testthat::expect_true(flag_ran_pipeline)
    testthat::expect_equal(res[["upstream_status"]], "ok")
  }
)

testthat::test_that(
  "refresh_cz_decomposition_upstream() errors on missing target",
  {
    run_pipeline_fn <- function(...) {
      TRUE
    }

    tar_meta_fn <- function(fields, complete_only, store) {
      tibble::tibble(
        name = "data_sample_ids_checked_genus",
        error = NA_character_
      )
    }

    testthat::expect_error(
      refresh_cz_decomposition_upstream(
        refresh_upstream = FALSE,
        store_path = "store",
        pipeline_script = "script.R",
        run_pipeline_fn = run_pipeline_fn,
        tar_meta_fn = tar_meta_fn,
        verbose = FALSE
      ),
      "missing or failed"
    )
  }
)
