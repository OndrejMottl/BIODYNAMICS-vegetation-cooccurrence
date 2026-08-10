testthat::test_that(
  desc = "evaluate_jsdm() rejects invalid mod_jsdm input",
  code = {
    testthat::skip_if_not_installed("sjSDM")

    testthat::expect_error(
      evaluate_jsdm(mod_jsdm = NULL)
    )

    testthat::expect_error(
      evaluate_jsdm(mod_jsdm = "invalid_model")
    )

    testthat::expect_error(
      evaluate_jsdm(mod_jsdm = base::list(a = 1))
    )
  }
)

testthat::test_that(
  desc = "evaluate_jsdm() returns a list with correct top-level names",
  code = {
    testthat::skip_if_not_installed("sjSDM")

    base::set.seed(900723)

    data_community <-
      base::data.frame(
        sp1 = base::c(1, 0, 1, 0, 1),
        sp2 = base::c(0, 1, 1, 0, 1),
        sp3 = base::c(1, 1, 0, 1, 0)
      )
    data_abiotic <-
      base::data.frame(
        temp = base::c(10, 15, 20, 25, 30),
        precip = base::c(100, 200, 300, 400, 500)
      )
    mod_example <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = base::as.matrix(data_community),
          data_abiotic_to_fit = data_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        error_family = "binomial",
        sampling = 5L,
        step_size = 5L,
        verbose = FALSE
      )

    result <-
      evaluate_jsdm(mod_jsdm = mod_example)

    testthat::expect_type(result, "list")
    testthat::expect_length(result, 3)
    testthat::expect_named(
      result,
      base::c(
        "vec_model_metrics",
        "data_taxon_metrics",
        "list_convergence_diagnostics"
      )
    )
  }
)

testthat::test_that(
  desc = "evaluate_jsdm() model element has correct R2 names and values",
  code = {
    testthat::skip_if_not_installed("sjSDM")

    base::set.seed(900723)

    data_community <-
      base::data.frame(
        sp1 = base::c(1, 0, 1, 0, 1),
        sp2 = base::c(0, 1, 1, 0, 1)
      )
    data_abiotic <-
      base::data.frame(
        temp = base::c(10, 15, 20, 25, 30),
        precip = base::c(100, 200, 300, 400, 500)
      )
    mod_example <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = base::as.matrix(data_community),
          data_abiotic_to_fit = data_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        error_family = "binomial",
        sampling = 5L,
        step_size = 5L,
        verbose = FALSE
      )

    result <-
      evaluate_jsdm(mod_jsdm = mod_example)

    vec_model_metrics <-
      result |>
      purrr::chuck("vec_model_metrics")

    testthat::expect_type(vec_model_metrics, "double")
    testthat::expect_named(
      vec_model_metrics,
      base::c("r2_mcfadden", "r2_nagelkerke")
    )
    testthat::expect_true(
      base::is.numeric(purrr::chuck(vec_model_metrics, "r2_mcfadden"))
    )
    testthat::expect_true(
      base::is.numeric(purrr::chuck(vec_model_metrics, "r2_nagelkerke"))
    )
  }
)

testthat::test_that(
  desc = stringr::str_c(
    "evaluate_jsdm() species element is a tibble with correct columns",
    " for binomial family"
  ),
  code = {
    testthat::skip_if_not_installed("sjSDM")

    base::set.seed(900723)

    data_community <-
      base::data.frame(
        sp1 = base::c(1, 0, 1, 0, 1, 1, 0, 1),
        sp2 = base::c(0, 1, 1, 0, 1, 0, 1, 0),
        sp3 = base::c(1, 0, 0, 1, 1, 0, 0, 1)
      )
    data_abiotic <-
      base::data.frame(
        temp = base::c(10, 15, 20, 25, 30, 35, 40, 45),
        precip = base::c(100, 200, 300, 400, 500, 600, 700, 800)
      )
    mod_example <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = base::as.matrix(data_community),
          data_abiotic_to_fit = data_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        error_family = "binomial",
        sampling = 10L,
        step_size = 5L,
        verbose = FALSE
      )

    result <-
      evaluate_jsdm(mod_jsdm = mod_example)

    data_taxon_metrics <-
      result |>
      purrr::chuck("data_taxon_metrics")

    # Class and dimensions
    testthat::expect_s3_class(data_taxon_metrics, "tbl_df")
    testthat::expect_equal(
      base::nrow(data_taxon_metrics),
      base::ncol(data_community)
    )
    testthat::expect_named(
      data_taxon_metrics,
      base::c("taxon_name", "auc", "accuracy", "log_loss")
    )

    # Species names match community columns
    testthat::expect_equal(
      dplyr::pull(data_taxon_metrics, "taxon_name"),
      base::colnames(data_community)
    )

    # AUC bounded [0, 1]
    testthat::expect_true(
      base::all(
        dplyr::pull(data_taxon_metrics, "auc") >= 0 &
          dplyr::pull(data_taxon_metrics, "auc") <= 1,
        na.rm = TRUE
      )
    )

    # Accuracy bounded [0, 1]
    testthat::expect_true(
      base::all(
        dplyr::pull(data_taxon_metrics, "accuracy") >= 0 &
          dplyr::pull(data_taxon_metrics, "accuracy") <= 1,
        na.rm = TRUE
      )
    )

    # LogLoss is non-negative
    testthat::expect_true(
      base::all(
        dplyr::pull(data_taxon_metrics, "log_loss") >= 0,
        na.rm = TRUE
      )
    )
  }
)

testthat::test_that(
  desc = stringr::str_c(
    "evaluate_jsdm() species element contains RMSE column",
    " for non-binomial family"
  ),
  code = {
    testthat::skip_if_not_installed("sjSDM")

    base::set.seed(900723)

    data_community <-
      base::data.frame(
        sp1 = base::c(0.2, 0.5, 0.8, 0.1, 0.9),
        sp2 = base::c(0.4, 0.3, 0.7, 0.6, 0.2)
      )
    data_abiotic <-
      base::data.frame(
        temp = base::c(10, 15, 20, 25, 30),
        precip = base::c(100, 200, 300, 400, 500)
      )
    mod_example <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = base::as.matrix(data_community),
          data_abiotic_to_fit = data_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        error_family = "gaussian",
        sampling = 5L,
        step_size = 5L,
        verbose = FALSE
      )

    result <-
      evaluate_jsdm(mod_jsdm = mod_example)

    data_taxon_metrics <-
      result |>
      purrr::chuck("data_taxon_metrics")

    testthat::expect_s3_class(data_taxon_metrics, "tbl_df")
    testthat::expect_equal(
      base::nrow(data_taxon_metrics),
      base::ncol(data_community)
    )
    testthat::expect_named(
      data_taxon_metrics,
      base::c("taxon_name", "rmse")
    )

    testthat::expect_equal(
      dplyr::pull(data_taxon_metrics, "taxon_name"),
      base::colnames(data_community)
    )

    testthat::expect_true(
      base::all(
        dplyr::pull(data_taxon_metrics, "rmse") >= 0,
        na.rm = TRUE
      )
    )
  }
)

testthat::test_that(
  desc = "evaluate_jsdm() convergence element has expected structure",
  code = {
    testthat::skip_if_not_installed("sjSDM")

    base::set.seed(900723)

    data_community <-
      base::data.frame(
        sp1 = base::c(1, 0, 1, 0, 1),
        sp2 = base::c(0, 1, 1, 0, 1)
      )
    data_abiotic <-
      base::data.frame(
        temp = base::c(10, 15, 20, 25, 30),
        precip = base::c(100, 200, 300, 400, 500)
      )
    mod_example <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = base::as.matrix(data_community),
          data_abiotic_to_fit = data_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        error_family = "binomial",
        sampling = 5L,
        step_size = 5L,
        verbose = FALSE
      )

    result <-
      evaluate_jsdm(mod_jsdm = mod_example)

    convergence <-
      result |>
      purrr::chuck("list_convergence_diagnostics")

    testthat::expect_type(convergence, "list")
    testthat::expect_length(convergence, 6L)
    testthat::expect_named(
      convergence,
      base::c(
        "linear_trend_slope",
        "median_diff",
        "convergence_plot",
        "note",
        "epochs_run",
        "early_stopping_triggered"
      )
    )

    linear_trend_slope <-
      convergence |>
      purrr::chuck("linear_trend_slope")

    median_diff <-
      convergence |>
      purrr::chuck("median_diff")

    convergence_plot <-
      convergence |>
      purrr::chuck("convergence_plot")

    note <-
      convergence |>
      purrr::chuck("note")

    testthat::expect_type(linear_trend_slope, "double")
    testthat::expect_length(linear_trend_slope, 1L)
    testthat::expect_true(linear_trend_slope >= 0)

    testthat::expect_type(median_diff, "double")
    testthat::expect_length(median_diff, 1L)
    testthat::expect_true(median_diff >= 0)

    testthat::expect_s3_class(convergence_plot, "ggplot")

    testthat::expect_type(note, "character")
    testthat::expect_length(note, 1L)
  }
)
