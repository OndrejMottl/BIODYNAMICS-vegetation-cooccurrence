testthat::test_that(
  "build_sjsdm_selected_fold_artifacts() aligns cached probabilities",
  {
    data_sample_ids <-
      tibble::tibble(
        sample_id = base::c("a__0", "b__0"),
        row_index = 1:2,
        location_id = base::c("a", "b"),
        dataset_name = base::c("a", "b"),
        age = 0
      )

    data_train <-
      base::matrix(
        base::c(0, 1),
        ncol = 1L,
        dimnames = base::list(base::c("c__0", "d__0"), "taxon_a")
      )

    data_test_full <-
      base::matrix(
        base::c(1, 0, 0, 1),
        nrow = 2L,
        byrow = TRUE,
        dimnames = base::list(
          base::c("a__0", "b__0"),
          base::c("taxon_a", "taxon_b")
        )
      )

    list_prepared_fold <-
      base::list(
        data_train_input = base::list(data_spatial_to_fit = NULL),
        data_test_input = base::list(),
        data_train_observed = data_train,
        data_test_observed =
          data_test_full[, "taxon_a", drop = FALSE],
        data_test_observed_full = data_test_full,
        test_sample_ids = base::rownames(data_test_full),
        data_taxa_mapping = tibble::tibble(
          taxon = base::c("taxon_a", "taxon_b"),
          retained = base::c(TRUE, FALSE),
          status = base::c("retained", "constant_in_training")
        )
      )

    data_predicted <-
      base::matrix(
        base::c(0.8, 0.2),
        ncol = 1L,
        dimnames = base::list(base::c("a__0", "b__0"), "taxon_a")
      )

    res <-
      build_sjsdm_selected_fold_artifacts(
        list_prepared_fold = list_prepared_fold,
        list_fold_context = base::list(
          repeat_id = 1L,
          fold_id = 2L,
          test_indices = 1:2,
          cv_strategy = "leave_one_location_out"
        ),
        data_sample_ids = data_sample_ids,
        taxon_names = base::c("taxon_a", "taxon_b"),
        candidate_id = "candidate_001",
        fit_seed = 101L,
        regularization_source = "unit_cv",
        data_predicted = data_predicted
      )

    testthat::expect_equal(base::nrow(res[["data_predictions"]]), 4L)
    testthat::expect_identical(
      res[["data_diagnostics"]][["fit_seed"]],
      101L
    )
    testthat::expect_equal(
      res[["data_predictions"]][["null_probability"]][
        res[["data_predictions"]][["taxon"]] == "taxon_a"
      ],
      base::rep(0.5, 2L)
    )
    testthat::expect_identical(
      res[["data_predictions"]][["prediction_status"]],
      base::rep(base::c("ok", "constant_in_training"), 2L)
    )
  }
)
