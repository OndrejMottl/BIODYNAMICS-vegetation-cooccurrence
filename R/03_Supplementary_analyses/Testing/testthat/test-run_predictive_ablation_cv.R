testthat::test_that(
  "run_predictive_ablation_cv() runs all variants",
  {
    mat_community <-
      base::matrix(
        data = c(
          1, 0,
          0, 1,
          1, 1,
          0, 0
        ),
        nrow = 4L,
        byrow = TRUE
      )

    base::colnames(mat_community) <-
      c("taxon_a", "taxon_b")

    data_abiotic <-
      base::data.frame(
        bio_one = c(0.1, 0.2, 0.3, 0.4),
        age = c(0, 100, 200, 300)
      )

    data_spatial <-
      base::data.frame(
        mev_one = c(-1, -0.5, 0.5, 1),
        mev_two = c(1, 0.5, -0.5, -1)
      )

    vec_rows <-
      stringr::str_glue("sample_{base::seq_len(4L)}")

    base::rownames(mat_community) <-
      vec_rows
    base::rownames(data_abiotic) <-
      vec_rows
    base::rownames(data_spatial) <-
      vec_rows

    data_model_input <-
      base::list(
        data_community_to_fit = mat_community,
        data_abiotic_to_fit = data_abiotic,
        data_spatial_to_fit = data_spatial
      )

    list_calls <- base::list()

    dummy_cv_fn <- function(
        Y,
        env,
        biotic,
        spatial,
        tune,
        CV,
        ...) {
      list_calls[[base::length(list_calls) + 1L]] <<-
        tibble::tibble(
          n_rows = base::nrow(Y),
          has_spatial = !base::is.null(spatial),
          biotic_diag = biotic[["diag"]],
          n_folds = base::length(CV)
        )

      res <-
        base::list(
          summary = tibble::tibble(
            CV_set = base::seq_along(CV),
            ll_test = -base::seq_along(CV),
            AUC_test = base::rep(0.6, base::length(CV)),
            AUC_macro_test = base::rep(0.7, base::length(CV))
          )
        )

      return(res)
    }

    cv_indices <-
      make_repeated_cv_indices(
        n_samples = 4L,
        n_folds = 2L,
        n_repeats = 1L,
        seed = 900723L
      )

    res <-
      run_predictive_ablation_cv(
        data_model_input = data_model_input,
        cv_indices = cv_indices,
        config_model_fitting = base::list(
          error_family = "binomial",
          use_age_in_formula = FALSE,
          n_iter = 2L,
          n_sampling = 2L,
          n_step_size = 1L
        ),
        device = "cpu",
        cv_fn = dummy_cv_fn,
        verbose = FALSE
      )

    data_calls <-
      purrr::list_rbind(list_calls)

    testthat::expect_equal(base::nrow(res), 8L)
    testthat::expect_equal(base::length(list_calls), 4L)
    testthat::expect_true(
      base::all(
        c("full", "no_abiotic", "no_spatial", "no_associations") %in%
          dplyr::pull(res, variant)
      )
    )
    testthat::expect_true(
      base::any(!dplyr::pull(data_calls, has_spatial))
    )
    testthat::expect_true(
      base::any(dplyr::pull(data_calls, biotic_diag))
    )
    testthat::expect_true(base::all(dplyr::pull(res, status) == "ok"))
    testthat::expect_equal(
      dplyr::pull(res, loss),
      dplyr::pull(res, ll_test)
    )
  }
)

testthat::test_that(
  "run_predictive_ablation_cv() selects best tuning row",
  {
    mat_community <-
      base::matrix(
        data = c(
          1, 0,
          0, 1,
          1, 1,
          0, 0
        ),
        nrow = 4L,
        byrow = TRUE
      )

    base::colnames(mat_community) <-
      c("taxon_a", "taxon_b")

    data_abiotic <-
      base::data.frame(
        bio_one = c(0.1, 0.2, 0.3, 0.4)
      )

    data_spatial <-
      base::data.frame(
        mev_one = c(-1, -0.5, 0.5, 1)
      )

    vec_rows <-
      stringr::str_glue("sample_{base::seq_len(4L)}")

    base::rownames(mat_community) <-
      vec_rows
    base::rownames(data_abiotic) <-
      vec_rows
    base::rownames(data_spatial) <-
      vec_rows

    data_model_input <-
      base::list(
        data_community_to_fit = mat_community,
        data_abiotic_to_fit = data_abiotic,
        data_spatial_to_fit = data_spatial
      )

    dummy_cv_fn <- function(
        Y,
        env,
        biotic,
        spatial,
        tune,
        CV,
        ...) {
      list_result <-
        base::list(
          base::list(
            base::list(
              indices = CV[[1L]],
              pred_test = base::matrix(
                data = 0.5,
                nrow = base::length(CV[[1L]]),
                ncol = base::ncol(Y)
              )
            ),
            base::list(
              indices = CV[[2L]],
              pred_test = base::matrix(
                data = 0.5,
                nrow = base::length(CV[[2L]]),
                ncol = base::ncol(Y)
              )
            )
          ),
          base::list(
            base::list(
              indices = CV[[1L]],
              pred_test = base::matrix(
                data = 0.4,
                nrow = base::length(CV[[1L]]),
                ncol = base::ncol(Y)
              )
            ),
            base::list(
              indices = CV[[2L]],
              pred_test = base::matrix(
                data = 0.4,
                nrow = base::length(CV[[2L]]),
                ncol = base::ncol(Y)
              )
            )
          )
        )

      res <-
        base::list(
          summary = tibble::tibble(
            alpha_cov = c(0.5, 0.5, 0.5, 0.5),
            alpha_coef = c(0.5, 0.5, 0.5, 0.5),
            lambda_cov = c(0.01, 0.10, 0.01, 0.10),
            lambda_coef = c(0.01, 0.10, 0.01, 0.10),
            iter = c(1L, 2L, 1L, 2L),
            CV_set = c(1L, 1L, 2L, 2L),
            ll_test = c(10, 8, 12, 13),
            AUC_test = c(0.6, 0.7, 0.7, 0.6),
            AUC_macro_test = c(0.6, 0.7, 0.7, 0.6)
          ),
          tune_results = list_result
        )

      return(res)
    }

    cv_indices <-
      make_repeated_cv_indices(
        n_samples = 4L,
        n_folds = 2L,
        n_repeats = 1L,
        seed = 900723L
      )

    res <-
      run_predictive_ablation_cv(
        data_model_input = data_model_input,
        cv_indices = cv_indices,
        config_model_fitting = base::list(
          error_family = "binomial",
          use_age_in_formula = FALSE,
          n_iter = 2L,
          n_sampling = 2L,
          n_step_size = 1L
        ),
        device = "cpu",
        selection_metric = "loss",
        cv_fn = dummy_cv_fn,
        verbose = FALSE
      )

    data_full <-
      res |>
      dplyr::filter(.data$variant == "full") |>
      dplyr::arrange(.data$fold_id)

    testthat::expect_equal(
      dplyr::pull(data_full, tune_step),
      c(2L, 1L)
    )
    testthat::expect_equal(
      dplyr::pull(data_full, loss),
      c(8, 12)
    )
    testthat::expect_true(
      base::all(base::is.finite(dplyr::pull(data_full, pred_brier)))
    )
  }
)
