testthat::test_that(
  "expected insufficient-core failures allow dependency cascades",
  {
    data_errors <-
      tibble::tibble(
        name = base::c(
          "flag_available_core_count_validated",
          "data_community",
          "data_community_long",
          "data_community_taxa_classification_"
        ),
        error = base::c(
          "Not enough cores in this spatial window. Found 1; need 5.",
          "could not load dependency flag_available_core_count_validated",
          "could not load dependency data_community",
          "object 'vec_community_taxa_checked' not found"
        )
      )

    res <-
      classify_sjsdm_unit_pipeline_error(data_errors)

    testthat::expect_identical(res[["status"]], "expected_infeasible")
    testthat::expect_identical(
      res[["root_target"]],
      "flag_available_core_count_validated"
    )
    testthat::expect_identical(
      res[["reason_code"]],
      "insufficient_cores"
    )
    testthat::expect_identical(res[["observed_count"]], 1L)
    testthat::expect_identical(res[["required_count"]], 5L)
  }
)

testthat::test_that(
  "all registered data limitations receive stable reason codes",
  {
    data_cases <-
      tibble::tribble(
        ~name, ~error, ~reason_code,
        "data_sample_ids_checked",
        paste(
          "Too few samples in this time slice to proceed with data",
          "preparation and model fitting. Found 4 sample(s) but at least",
          "10 are required."
        ),
        "insufficient_samples",
        "data_community_rare_filtered",
        paste(
          "No taxa found in data. Please check the input data.",
          "The minimum_proportion is too high."
        ),
        "no_taxa_after_minimum_proportion",
        "data_community_filtered_cores",
        paste(
          "No taxa remain after filtering.",
          "The minimum_core_count is too high."
        ),
        "no_taxa_after_minimum_core_count",
        "data_community_filtered_samples",
        paste(
          "No taxa remain after filtering.",
          "The minimum_sample_count is too high."
        ),
        "no_taxa_after_minimum_sample_count",
        "list_sjsdm_prepared_tuning_folds_family",
        paste(
          "Too few taxa remain after filtering to run the model.",
          "Found 3 taxa but at least 5 are required."
        ),
        "insufficient_taxa",
        "list_sjsdm_prepared_tuning_folds_timeslice_1000",
        paste(
          "Too few taxa remain after filtering to run the model.",
          "Found 2 taxa but at least 5 are required."
        ),
        "insufficient_taxa",
        "vec_community_taxa",
        "No community taxa found in this spatial window.",
        "empty_community",
        "list_abiotic_collinearity",
        paste(
          "Error in tar_make(): cannot branch over empty target",
          "(vec_community_taxa_checked)"
        ),
        "empty_community",
        "list_abiotic_collinearity",
        paste(
          "No columns with non-zero variance remain after removing",
          "constant columns. All 7 predictor columns have zero variance."
        ),
        "no_abiotic_variation",
        "data_vegvault_extracted",
        "VegVault extraction returned zero rows.",
        "no_spatial_records",
        "data_vegvault_extracted",
        paste(
          "Failed to extract VegVault data for this spatial unit.",
          "The upstream backend returned an empty/opaque error message."
        ),
        "no_spatial_records",
        "n_functional_type_groups_selected_continental",
        paste(
          "No viable k in 2..6 produces >= 5 non-constant FT groups",
          "after the pipeline filter chain."
        ),
        "no_viable_functional_type_groups"
      )

    purrr::pwalk(
      data_cases,
      function(name, error, reason_code) {
        res <-
          classify_sjsdm_unit_pipeline_error(
            tibble::tibble(
              name = name,
              error = error
            )
          )

        testthat::expect_identical(
          res[["status"]],
          "expected_infeasible"
        )
        testthat::expect_identical(
          res[["reason_code"]],
          reason_code
        )
        if (
          reason_code == "no_spatial_records"
        ) {
          testthat::expect_identical(res[["observed_count"]], 0L)
        }
      }
    )
  }
)

testthat::test_that(
  "generic VegVault extraction failures remain unexpected",
  {
    res <-
      classify_sjsdm_unit_pipeline_error(
        tibble::tibble(
          name = "data_vegvault_extracted",
          error = paste(
            "Failed to extract VegVault data for this spatial unit.",
            "Database connection failed."
          )
        )
      )

    testthat::expect_identical(res[["status"]], "unexpected_error")
    testthat::expect_true(base::is.na(res[["reason_code"]]))
  }
)

testthat::test_that(
  "sample and taxon counts are extracted when messages provide them",
  {
    data_errors <-
      tibble::tibble(
        name = "data_sample_ids_checked_timeslice_1000",
        error = paste(
          "Too few samples in this time slice to proceed with data",
          "preparation and model fitting.",
          "Found 4 sample(s) but at least 10 are required."
        )
      )

    res <-
      classify_sjsdm_unit_pipeline_error(data_errors)

    testthat::expect_identical(res[["observed_count"]], 4L)
    testthat::expect_identical(res[["required_count"]], 10L)
  }
)

testthat::test_that(
  "temporal validation cascades follow an insufficient-sample root",
  {
    data_errors <-
      tibble::tibble(
        name = base::c(
          "data_sample_ids_checked_timeslice_20000",
          "data_abiotic_wide_timeslice_20000",
          "data_community_model_matrix_timeslice_20000",
          "data_cross_validation_locations_timeslice_20000",
          "data_community_prepared_timeslice_20000",
          "data_cross_validation_fold_resolution_timeslice_20000",
          "data_cross_validation_grid_candidates_timeslice_20000",
          "data_cross_validation_grid_calibration_timeslice_20000",
          "data_cross_validation_assignments_initial_timeslice_20000",
          paste0(
            "data_cross_validation_partition_diagnostics_initial_",
            "timeslice_20000"
          ),
          "data_cross_validation_assignments_timeslice_20000",
          paste0(
            "data_cross_validation_partition_diagnostics_",
            "timeslice_20000"
          ),
          "data_cross_validation_feasibility_timeslice_20000",
          "list_sjsdm_prepared_tuning_folds_timeslice_20000"
        ),
        error = base::c(
          paste(
            "Too few samples in this time slice to proceed with data",
            "preparation and model fitting. Found 4 sample(s) but at",
            "least 10 are required."
          ),
          "data_sample_ids must be a data frame",
          "data_sample_ids must be a data frame",
          "`data_sample_ids` must be a data frame.",
          "mat_community must be a matrix",
          "`n_locations` must be a single positive integer.",
          paste(
            "`data_fold_resolution` must contain one row and a",
            "`cv_strategy` column."
          ),
          "`data_fold_resolution` must contain exactly one row.",
          "`data_locations` must be a non-empty data frame.",
          "`data_locations` must be a non-empty data frame.",
          "`data_locations` must be a non-empty data frame.",
          "`data_locations` must be a non-empty data frame.",
          "`data_partition_diagnostics` must be a data frame.",
          "argument is of length zero"
        )
      )

    res <-
      classify_sjsdm_unit_pipeline_error(data_errors)

    testthat::expect_identical(res[["status"]], "expected_infeasible")
    testthat::expect_identical(
      res[["reason_code"]],
      "insufficient_samples"
    )
    testthat::expect_identical(
      res[["root_target"]],
      "data_sample_ids_checked_timeslice_20000"
    )
  }
)

testthat::test_that(
  "temporal validation messages without a scientific root remain errors",
  {
    data_errors <-
      tibble::tibble(
        name = "list_sjsdm_prepared_tuning_folds_timeslice_20000",
        error = "argument is of length zero"
      )

    res <-
      classify_sjsdm_unit_pipeline_error(data_errors)

    testthat::expect_identical(res[["status"]], "unexpected_error")
    testthat::expect_true(base::is.na(res[["reason_code"]]))
  }
)

testthat::test_that(
  "temporal cascades require a root in the same time slice",
  {
    data_errors <-
      tibble::tibble(
        name = base::c(
          "data_sample_ids_checked_timeslice_20000",
          "list_sjsdm_prepared_tuning_folds_timeslice_19500"
        ),
        error = base::c(
          paste(
            "Too few samples in this time slice to proceed with data",
            "preparation and model fitting. Found 4 sample(s) but at",
            "least 10 are required."
          ),
          "argument is of length zero"
        )
      )

    res <-
      classify_sjsdm_unit_pipeline_error(data_errors)

    testthat::expect_identical(res[["status"]], "unexpected_error")
    testthat::expect_true(base::is.na(res[["reason_code"]]))
  }
)

testthat::test_that(
  "unrelated target errors remain unexpected",
  {
    data_errors <-
      tibble::tibble(
        name = base::c(
          "flag_available_core_count_validated",
          "data_traits"
        ),
        error = base::c(
          "Not enough cores in this spatial window. Found 1; need 5.",
          "Trait file is corrupt."
        )
      )

    res <-
      classify_sjsdm_unit_pipeline_error(data_errors)

    testthat::expect_identical(res[["status"]], "unexpected_error")
    testthat::expect_true(base::is.na(res[["reason_code"]]))
  }
)

testthat::test_that(
  "empty target metadata remains unexpected",
  {
    res <-
      classify_sjsdm_unit_pipeline_error(
        tibble::tibble(
          name = base::character(),
          error = base::character()
        )
      )

    testthat::expect_identical(res[["status"]], "unexpected_error")
    testthat::expect_true(base::is.na(res[["root_target"]]))
    testthat::expect_true(base::is.na(res[["reason_code"]]))
  }
)

testthat::test_that(
  "insufficient abiotic observations are expected infeasibility",
  {
    data_errors <-
      tibble::tibble(
        name = "list_abiotic_collinearity_genus",
        error = stringr::str_c(
          "✖ Too few abiotic observations to evaluate predictor collinearity.",
          " ",
          "ℹ Found 2 row(s) but at least 3 are required."
        )
      )

    res <-
      classify_sjsdm_unit_pipeline_error(data_errors)

    testthat::expect_identical(res[["status"]], "expected_infeasible")
    testthat::expect_identical(
      res[["reason_code"]],
      "insufficient_abiotic_observations"
    )
    testthat::expect_identical(res[["observed_count"]], 2L)
    testthat::expect_identical(res[["required_count"]], 3L)
  }
)
