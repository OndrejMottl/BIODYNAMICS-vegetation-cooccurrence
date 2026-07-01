testthat::test_that(
  "run_sjsdm_tuning_candidates() isolates folds and returns metrics",
  {
    data_assignments <-
      tibble::tibble(
        repeat_id = base::rep(1L, 4L),
        fold_id = base::c(1L, 1L, 2L, 2L),
        location_id = base::letters[1:4],
        n_samples = base::rep(1L, 4L),
        row_indices = base::as.list(base::seq_len(4L)),
        cv_strategy = "spatially_stratified_group_kfold"
      )

    data_candidates <-
      make_sjsdm_regularization_candidates(
        lambda_cov = base::c(0, 0.1)
      )

    environment_capture <-
      base::new.env(parent = base::emptyenv())

    environment_capture[["partitions"]] <-
      base::list()

    environment_capture[["fits"]] <-
      base::list()

    prepare_fold_function <- function(
        train_indices,
        test_indices,
        repeat_id,
        fold_id) {
      partition_key <-
        stringr::str_glue("repeat_{repeat_id}_fold_{fold_id}")

      environment_capture[["partitions"]][[partition_key]] <-
        base::list(
          train_indices = train_indices,
          test_indices = test_indices
        )

      data_observed_full <-
        base::matrix(
          data = base::c(
            0, 1,
            1, 0,
            0, 1,
            1, 0
          ),
          nrow = 4L,
          byrow = TRUE,
          dimnames = base::list(
            base::letters[1:4],
            base::c("taxon_a", "taxon_b")
          )
        )

      res <-
        base::list(
          data_train_input = base::list(row_indices = train_indices),
          data_test_input = base::list(row_indices = test_indices),
          data_test_observed = data_observed_full[
            test_indices,
            ,
            drop = FALSE
          ]
        )

      return(res)
    }

    fit_function <- function(data_train_input, candidate, seed) {
      fit_key <-
        stringr::str_c(
          candidate[["candidate_id"]],
          "_",
          seed
        )

      environment_capture[["fits"]][[fit_key]] <-
        data_train_input[["row_indices"]]

      res <-
        base::list(candidate_id = candidate[["candidate_id"]])

      return(res)
    }

    predict_function <- function(object, data_test_input) {
      data_observed_full <-
        base::matrix(
          data = base::c(
            0, 1,
            1, 0,
            0, 1,
            1, 0
          ),
          nrow = 4L,
          byrow = TRUE,
          dimnames = base::list(
            base::letters[1:4],
            base::c("taxon_a", "taxon_b")
          )
        )

      data_observed <-
        data_observed_full[
          data_test_input[["row_indices"]],
          ,
          drop = FALSE
        ]

      res <-
        data_observed * 0.8 + 0.1

      return(res)
    }

    res <-
      run_sjsdm_tuning_candidates(
        data_assignments = data_assignments,
        data_candidates = data_candidates,
        prepare_fold_function = prepare_fold_function,
        fit_function = fit_function,
        predict_function = predict_function,
        seed = 100L
      )

    testthat::expect_equal(base::nrow(res), 4L)
    testthat::expect_named(
      res,
      base::c(
        "repeat_id",
        "fold_id",
        "candidate_id",
        "alpha_cov",
        "alpha_coef",
        "alpha_spatial",
        "lambda_cov",
        "lambda_coef",
        "lambda_spatial",
        "fit_seed",
        "n_train_locations",
        "n_test_locations",
        "n_train_samples",
        "n_test_samples",
        "n_taxa_retained",
        "n_response_values",
        "negative_log_likelihood_test",
        "negative_log_likelihood_per_response",
        "auc_macro_test",
        "fit_status",
        "error_message",
        "cv_strategy",
        "regularization_source"
      )
    )
    testthat::expect_true(base::all(res[["fit_status"]] == "ok"))
    testthat::expect_equal(
      res[["negative_log_likelihood_per_response"]],
      base::rep(-base::log(0.9), 4L)
    )
    testthat::expect_equal(res[["auc_macro_test"]], base::rep(1, 4L))
    testthat::expect_false(base::any(purrr::map_lgl(res, base::is.list)))
    testthat::expect_equal(
      environment_capture[["partitions"]][["repeat_1_fold_1"]],
      base::list(
        train_indices = base::c(3L, 4L),
        test_indices = base::c(1L, 2L)
      )
    )
    testthat::expect_equal(
      environment_capture[["partitions"]][["repeat_1_fold_2"]],
      base::list(
        train_indices = base::c(1L, 2L),
        test_indices = base::c(3L, 4L)
      )
    )
    testthat::expect_length(environment_capture[["partitions"]], 2L)
    testthat::expect_length(environment_capture[["fits"]], 4L)

    res_repeated <-
      run_sjsdm_tuning_candidates(
        data_assignments = data_assignments,
        data_candidates = data_candidates,
        prepare_fold_function = prepare_fold_function,
        fit_function = fit_function,
        predict_function = predict_function,
        seed = 100L
      )

    testthat::expect_equal(res, res_repeated)
  }
)

testthat::test_that(
  "run_sjsdm_tuning_candidates() retains candidate fit errors",
  {
    data_assignments <-
      tibble::tibble(
        repeat_id = base::rep(1L, 4L),
        fold_id = base::c(1L, 1L, 2L, 2L),
        location_id = base::letters[1:4],
        n_samples = base::rep(1L, 4L),
        row_indices = base::as.list(base::seq_len(4L)),
        cv_strategy = "spatially_stratified_group_kfold"
      )

    data_candidates <-
      make_sjsdm_regularization_candidates(
        lambda_cov = base::c(0, 0.1)
      )

    prepare_fold_function <- function(
        train_indices,
        test_indices,
        repeat_id,
        fold_id) {
      data_observed <-
        base::matrix(
          data = base::c(0, 1, 1, 0),
          nrow = 2L,
          dimnames = base::list(
            base::letters[test_indices],
            base::c("taxon_a", "taxon_b")
          )
        )

      res <-
        base::list(
          data_train_input = base::list(row_indices = train_indices),
          data_test_input = base::list(row_indices = test_indices),
          data_test_observed = data_observed
        )

      return(res)
    }

    fit_function <- function(data_train_input, candidate, seed) {
      if (
        candidate[["lambda_cov"]] > 0
      ) {
        base::stop("candidate failed")
      }

      return(base::list())
    }

    predict_function <- function(object, data_test_input) {
      res <-
        base::matrix(
          data = base::c(0.1, 0.9, 0.9, 0.1),
          nrow = 2L
        )

      return(res)
    }

    res <-
      run_sjsdm_tuning_candidates(
        data_assignments = data_assignments,
        data_candidates = data_candidates,
        prepare_fold_function = prepare_fold_function,
        fit_function = fit_function,
        predict_function = predict_function
      )

    testthat::expect_equal(
      base::sum(res[["fit_status"]] == "ok"),
      2L
    )
    testthat::expect_equal(
      base::sum(res[["fit_status"]] == "fit_error"),
      2L
    )
    testthat::expect_true(
      base::all(
        base::is.na(
          res[["negative_log_likelihood_test"]][
            res[["fit_status"]] == "fit_error"
          ]
        )
      )
    )
    testthat::expect_match(
      res[["error_message"]][res[["fit_status"]] == "fit_error"],
      "candidate failed",
      all = TRUE
    )
  }
)
