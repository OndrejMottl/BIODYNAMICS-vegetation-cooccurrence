testthat::test_that(
  "run_spatial_mev_paired_cv_fixture() pairs strategies and assignments",
  {
    data_community <-
      base::matrix(
        base::rep(base::c(0, 1, 1, 0), 2L),
        nrow = 4L,
        dimnames = base::list(
          stringr::str_c("sample_", 1:4),
          base::c("taxon_a", "taxon_b")
        )
      )

    prepare_function <- function(
        data_community_matrix,
        train_indices,
        test_indices,
        config_model_fitting,
        ...) {
      data_train <-
        data_community_matrix[train_indices, , drop = FALSE]
      data_test <-
        data_community_matrix[test_indices, , drop = FALSE]

      return(
        base::list(
          data_train_input = base::list(
            data_community_to_fit = data_train,
            data_abiotic_to_fit = base::data.frame(
              abiotic = train_indices
            )
          ),
          data_test_input = base::list(
            data_abiotic_to_fit = base::data.frame(
              abiotic = test_indices
            )
          ),
          data_test_observed = data_test,
          strategy =
            config_model_fitting[["spatial_mev"]][["strategy"]]
        )
      )
    }

    fit_function <- function(data_train_input, ...) {
      return(data_train_input)
    }

    predict_function <- function(object, data_test_input) {
      n_test <-
        base::nrow(data_test_input[["data_abiotic_to_fit"]])
      n_taxa <-
        base::ncol(object[["data_community_to_fit"]])

      res <-
        base::matrix(
          base::rep(base::c(0.25, 0.75), length.out = n_test * n_taxa),
          nrow = n_test,
          ncol = n_taxa,
          dimnames = base::list(
            NULL,
            base::colnames(object[["data_community_to_fit"]])
          )
        )

      return(res)
    }

    data_assignments <-
      tidyr::crossing(
        repeat_id = 1:2,
        row_index = 1:4
      ) |>
      dplyr::mutate(
        fold_id = (.data[["row_index"]] + .data[["repeat_id"]]) %% 2L + 1L
      )

    res <-
      run_spatial_mev_paired_cv_fixture(
        data_community_matrix = data_community,
        data_abiotic_wide = tibble::tibble(),
        data_coords_projected = base::data.frame(),
        data_sample_ids = tibble::tibble(),
        data_assignments = data_assignments,
        candidate = tibble::tibble(candidate_id = "candidate_001"),
        sel_abiotic_formula = stats::as.formula("~ abiotic"),
        config_model_fitting = base::list(
          spatial_mev = base::list(fast_seed = 100L)
        ),
        config_data_processing = base::list(),
        prepare_function = prepare_function,
        fit_function = fit_function,
        predict_function = predict_function
      )

    testthat::expect_equal(
      base::nrow(res[["data_benchmark_runs"]]),
      4L
    )
    testthat::expect_setequal(
      res[["data_benchmark_runs"]][["spatial_mev_strategy"]],
      base::c("exact", "fast")
    )
    testthat::expect_equal(
      dplyr::n_distinct(
        res[["data_benchmark_runs"]][["assignment_hash"]]
      ),
      1L
    )
    testthat::expect_equal(
      base::nrow(res[["data_fold_diagnostics"]]),
      8L
    )
    testthat::expect_true(
      base::all(
        base::c(
          "preparation_seconds",
          "mev_seconds",
          "fitting_seconds",
          "prediction_seconds",
          "engine_method",
          "basis_bytes",
          "estimated_dense_matrix_bytes"
        ) %in%
          base::colnames(res[["data_fold_diagnostics"]])
      )
    )
    testthat::expect_true(
      base::all(
        res[["data_fold_diagnostics"]][["preparation_seconds"]] >= 0
      )
    )
  }
)
