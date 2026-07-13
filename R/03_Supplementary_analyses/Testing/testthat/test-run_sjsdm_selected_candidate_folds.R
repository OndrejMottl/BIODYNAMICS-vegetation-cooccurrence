make_selected_candidate_runner_test_data <- function() {
  data_assignments <-
    tibble::tibble(
      repeat_id = base::rep(1L, 4L),
      fold_id = base::c(1L, 1L, 2L, 2L),
      location_id = base::letters[1:4],
      n_samples = 1L,
      row_indices = base::as.list(base::seq_len(4L)),
      cv_strategy = "spatially_stratified_group_kfold"
    )

  data_sample_ids <-
    tibble::tibble(
      sample_id = stringr::str_c(base::letters[1:4], "__0"),
      row_index = base::seq_len(4L),
      location_id = base::letters[1:4],
      dataset_name = base::letters[1:4],
      age = 0
    )

  data_community <-
    base::matrix(
      data = base::c(
        0, 1, 1,
        0, 1, 1,
        1, 0, 0,
        0, 1, 0
      ),
      nrow = 4L,
      byrow = TRUE,
      dimnames = base::list(
        data_sample_ids[["sample_id"]],
        base::c("taxon_a", "taxon_b", "taxon_drop")
      )
    )

  data_selected_candidate <-
    tibble::tibble(
      candidate_id = "candidate_001",
      alpha_cov = 0.5,
      alpha_coef = 0.5,
      alpha_spatial = 0.5,
      lambda_cov = 0.1,
      lambda_coef = 0.1,
      lambda_spatial = 0.1,
      regularization_source = "unit_cv"
    )

  res <-
    base::list(
      data_assignments = data_assignments,
      data_sample_ids = data_sample_ids,
      data_community = data_community,
      data_selected_candidate = data_selected_candidate
    )

  return(res)
}

testthat::test_that(
  "run_sjsdm_selected_candidate_folds() supports unavailable folds",
  {
    list_data <-
      make_selected_candidate_runner_test_data()

    data_assignments <-
      list_data[["data_assignments"]][0, , drop = FALSE]

    res <-
      run_sjsdm_selected_candidate_folds(
        data_assignments = data_assignments,
        data_selected_candidate =
          list_data[["data_selected_candidate"]],
        data_sample_ids = list_data[["data_sample_ids"]],
        taxon_names = base::colnames(list_data[["data_community"]]),
        prepare_fold_function = base::identity,
        fit_function = base::identity,
        predict_function = base::identity
      )

    testthat::expect_equal(
      base::nrow(res[["data_predictions"]]),
      0L
    )
    testthat::expect_equal(
      base::nrow(res[["data_diagnostics"]]),
      0L
    )
  }
)

testthat::test_that(
  "run_sjsdm_selected_candidate_folds() returns complete OOF rows",
  {
    list_data <-
      make_selected_candidate_runner_test_data()

    environment_capture <-
      base::new.env(parent = base::emptyenv())

    environment_capture[["fits"]] <-
      base::list()

    prepare_fold_function <- function(
        train_indices,
        test_indices,
        repeat_id,
        fold_id) {
      data_train_full <-
        list_data[["data_community"]][
          train_indices,
          ,
          drop = FALSE
        ]

      data_test_full <-
        list_data[["data_community"]][
          test_indices,
          ,
          drop = FALSE
        ]

      res <-
        base::list(
          data_train_input = base::list(row_indices = train_indices),
          data_test_input = base::list(
            data_observed = data_test_full[, 1:2, drop = FALSE]
          ),
          data_train_observed =
            data_train_full[, 1:2, drop = FALSE],
          data_test_observed =
            data_test_full[, 1:2, drop = FALSE],
          data_test_observed_full = data_test_full,
          test_sample_ids = base::rownames(data_test_full),
          data_taxa_mapping = tibble::tibble(
            taxon = base::colnames(data_test_full),
            retained = base::c(TRUE, TRUE, FALSE),
            status = base::c(
              "retained",
              "retained",
              "constant_in_training"
            )
          )
        )

      return(res)
    }

    fit_function <- function(data_train_input, candidate, seed) {
      environment_capture[["fits"]][[base::as.character(seed)]] <-
        data_train_input[["row_indices"]]

      res <-
        base::list(candidate = candidate)

      return(res)
    }

    predict_function <- function(object, data_test_input) {
      res <-
        data_test_input[["data_observed"]] * 0.8 + 0.1

      return(res)
    }

    res <-
      run_sjsdm_selected_candidate_folds(
        data_assignments = list_data[["data_assignments"]],
        data_selected_candidate =
          list_data[["data_selected_candidate"]],
        data_sample_ids = list_data[["data_sample_ids"]],
        taxon_names = base::colnames(list_data[["data_community"]]),
        prepare_fold_function = prepare_fold_function,
        fit_function = fit_function,
        predict_function = predict_function,
        seed = 100L
      )

    data_predictions <-
      res[["data_predictions"]]

    data_diagnostics <-
      res[["data_diagnostics"]]

    testthat::expect_named(
      data_predictions,
      base::c(
        "repeat_id",
        "fold_id",
        "row_index",
        "location_id",
        "dataset_name",
        "age",
        "taxon",
        "observed",
        "predicted_probability",
        "null_probability",
        "prediction_status"
      )
    )
    testthat::expect_equal(base::nrow(data_predictions), 12L)
    testthat::expect_equal(
      base::nrow(
        dplyr::distinct(
          data_predictions,
          .data[["repeat_id"]],
          .data[["row_index"]],
          .data[["taxon"]]
        )
      ),
      12L
    )
    testthat::expect_false(
      "candidate_id" %in% base::colnames(data_predictions)
    )
    testthat::expect_equal(base::nrow(data_diagnostics), 2L)
    testthat::expect_true(
      base::all(data_diagnostics[["fit_status"]] == "ok")
    )
    testthat::expect_equal(
      data_diagnostics[["n_effective_mev"]],
      base::rep(0L, 2L)
    )
    testthat::expect_length(environment_capture[["fits"]], 2L)

    data_fold_two_a <-
      data_predictions |>
      dplyr::filter(
        .data[["fold_id"]] == 2L,
        .data[["taxon"]] == "taxon_a"
      )

    data_fold_two_b <-
      data_predictions |>
      dplyr::filter(
        .data[["fold_id"]] == 2L,
        .data[["taxon"]] == "taxon_b"
      )

    testthat::expect_equal(
      data_fold_two_a[["null_probability"]],
      base::rep(0, 2L)
    )
    testthat::expect_equal(
      data_fold_two_b[["null_probability"]],
      base::rep(1, 2L)
    )

    data_dropped <-
      data_predictions |>
      dplyr::filter(.data[["taxon"]] == "taxon_drop")

    testthat::expect_true(
      base::all(base::is.na(data_dropped[["predicted_probability"]]))
    )
    testthat::expect_true(
      base::all(base::is.na(data_dropped[["null_probability"]]))
    )
    testthat::expect_true(
      base::all(
        data_dropped[["prediction_status"]] ==
          "constant_in_training"
      )
    )
  }
)

testthat::test_that(
  "run_sjsdm_selected_candidate_folds() retains selected-fit errors",
  {
    list_data <-
      make_selected_candidate_runner_test_data()

    prepare_fold_function <- function(
        train_indices,
        test_indices,
        repeat_id,
        fold_id) {
      data_train_full <-
        list_data[["data_community"]][
          train_indices,
          ,
          drop = FALSE
        ]

      data_test_full <-
        list_data[["data_community"]][
          test_indices,
          ,
          drop = FALSE
        ]

      res <-
        base::list(
          data_train_input = base::list(fold_id = fold_id),
          data_test_input = base::list(
            data_observed = data_test_full[, 1:2, drop = FALSE]
          ),
          data_train_observed =
            data_train_full[, 1:2, drop = FALSE],
          data_test_observed =
            data_test_full[, 1:2, drop = FALSE],
          data_test_observed_full = data_test_full,
          test_sample_ids = base::rownames(data_test_full),
          data_taxa_mapping = tibble::tibble(
            taxon = base::colnames(data_test_full),
            retained = base::c(TRUE, TRUE, FALSE),
            status = base::c(
              "retained",
              "retained",
              "constant_in_training"
            )
          )
        )

      return(res)
    }

    fit_function <- function(data_train_input, candidate, seed) {
      if (
        data_train_input[["fold_id"]] == 2L
      ) {
        base::stop("selected fit failed")
      }

      return(base::list())
    }

    predict_function <- function(object, data_test_input) {
      return(data_test_input[["data_observed"]] * 0.8 + 0.1)
    }

    res <-
      run_sjsdm_selected_candidate_folds(
        data_assignments = list_data[["data_assignments"]],
        data_selected_candidate =
          list_data[["data_selected_candidate"]],
        data_sample_ids = list_data[["data_sample_ids"]],
        taxon_names = base::colnames(list_data[["data_community"]]),
        prepare_fold_function = prepare_fold_function,
        fit_function = fit_function,
        predict_function = predict_function
      )

    data_failed_predictions <-
      res[["data_predictions"]] |>
      dplyr::filter(
        .data[["fold_id"]] == 2L,
        .data[["taxon"]] != "taxon_drop"
      )

    testthat::expect_true(
      base::all(
        data_failed_predictions[["prediction_status"]] == "fit_error"
      )
    )
    testthat::expect_true(
      base::all(
        base::is.na(
          data_failed_predictions[["predicted_probability"]]
        )
      )
    )
    testthat::expect_match(
      res[["data_diagnostics"]][["error_message"]][
        res[["data_diagnostics"]][["fold_id"]] == 2L
      ],
      "selected fit failed"
    )
  }
)
