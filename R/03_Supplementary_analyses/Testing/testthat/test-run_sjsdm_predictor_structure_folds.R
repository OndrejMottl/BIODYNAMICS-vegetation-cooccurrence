testthat::test_that(
  "run_sjsdm_predictor_structure_folds() controls one component",
  {
    environment_capture <-
      base::new.env(parent = base::emptyenv())

    prepare_fold_function <- function(...) {
      environment_capture[["prepare"]] <-
        base::list(...)

      return(base::list(data_train_input = "prepared"))
    }

    fit_candidate_function <- function(...) {
      environment_capture[["fit"]] <-
        base::list(...)

      return("fit")
    }

    runner_function <- function(
        data_assignments,
        data_selected_candidate,
        data_sample_ids,
        taxon_names,
        prepare_fold_function,
        fit_function,
        predict_function,
        seed) {
      list_prepared <-
        prepare_fold_function(
          train_indices = 1L,
          test_indices = 2L,
          repeat_id = 1L,
          fold_id = 1L
        )

      fit_function(
        data_train_input = list_prepared[["data_train_input"]],
        candidate = data_selected_candidate,
        seed = seed
      )

      environment_capture[["runner"]] <-
        base::list(
          data_assignments = data_assignments,
          data_sample_ids = data_sample_ids,
          taxon_names = taxon_names,
          predict_function = predict_function
        )

      return(
        base::list(
          data_predictions = tibble::tibble(row_index = 2L),
          data_diagnostics = tibble::tibble(fold_id = 1L)
        )
      )
    }

    data_candidate <-
      tibble::tibble(candidate_id = "candidate_008")

    res <-
      run_sjsdm_predictor_structure_folds(
        predictor_structure = "abiotic_spatial_no_associations",
        data_assignments = tibble::tibble(repeat_id = 1L),
        data_selected_candidate = data_candidate,
        data_community_matrix = base::matrix(
          data = base::c(0, 1),
          ncol = 1L,
          dimnames = base::list(NULL, "taxon_a")
        ),
        data_abiotic_wide = tibble::tibble(age = base::c(1, 2)),
        data_coords_projected = tibble::tibble(x = base::c(1, 2)),
        data_sample_ids = tibble::tibble(sample_id = base::c("a", "b")),
        config_model_fitting = base::list(use_spatial = FALSE),
        config_data_processing = base::list(min_n_taxa = 1L),
        model_formula = stats::as.formula("~ age"),
        device = "gpu",
        seed = 123L,
        prepare_fold_function = prepare_fold_function,
        fit_candidate_function = fit_candidate_function,
        runner_function = runner_function,
        predict_function = base::identity
      )

    list_prepare <-
      environment_capture[["prepare"]]

    list_fit <-
      environment_capture[["fit"]]

    list_runner <-
      environment_capture[["runner"]]

    testthat::expect_equal(
      list_prepare[["config_model_fitting"]][["use_spatial"]],
      TRUE
    )
    testthat::expect_equal(
      base::deparse(list_fit[["sel_abiotic_formula"]]),
      "~age"
    )
    testthat::expect_true(
      list_fit[["config_model_fitting"]][["use_spatial"]]
    )
    testthat::expect_equal(list_fit[["device"]], "gpu")
    testthat::expect_equal(list_fit[["seed"]], 123L)
    testthat::expect_s3_class(list_fit[["biotic"]], "bioticStruct")
    testthat::expect_true(list_fit[["biotic"]][["diag"]])
    testthat::expect_equal(list_runner[["taxon_names"]], "taxon_a")
    testthat::expect_equal(
      res[["data_predictions"]][["predictor_structure"]],
      "abiotic_spatial_no_associations"
    )
    testthat::expect_equal(
      res[["data_diagnostics"]][["predictor_structure"]],
      "abiotic_spatial_no_associations"
    )
  }
)

testthat::test_that(
  "run_sjsdm_predictor_structure_folds() validates runner output",
  {
    testthat::expect_error(
      run_sjsdm_predictor_structure_folds(
        predictor_structure = "intercept_only",
        data_community_matrix = base::matrix(
          data = base::c(0, 1),
          ncol = 1L,
          dimnames = base::list(NULL, "taxon_a")
        ),
        config_model_fitting = base::list(use_spatial = TRUE),
        model_formula = stats::as.formula("~ age"),
        runner_function = function(...) base::list()
      ),
      "prediction and diagnostic"
    )
  }
)
