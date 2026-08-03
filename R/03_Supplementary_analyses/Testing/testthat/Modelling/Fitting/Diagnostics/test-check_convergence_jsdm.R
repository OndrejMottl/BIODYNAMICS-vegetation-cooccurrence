testthat::test_that(
  "check_convergence_jsdm() rejects non-sjSDM input",
  {
    testthat::skip_if_not_installed("sjSDM")

    testthat::expect_error(
      check_convergence_jsdm(mod_jsdm = NULL),
      "mod_jsdm must be of class 'sjSDM'"
    )

    testthat::expect_error(
      check_convergence_jsdm(mod_jsdm = base::list()),
      "mod_jsdm must be of class 'sjSDM'"
    )

    testthat::expect_error(
      check_convergence_jsdm(mod_jsdm = "not a model"),
      "mod_jsdm must be of class 'sjSDM'"
    )
  }
)

testthat::test_that(
  "check_convergence_jsdm() errors when history is too short",
  {
    testthat::skip_if_not_installed("sjSDM")

    set.seed(900723)

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
    mod_short <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = base::as.matrix(data_community),
          data_abiotic_to_fit = data_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        error_family = "binomial",
        iter = 5L,
        sampling = 5L,
        step_size = 5L,
        verbose = FALSE
      )

    # Patch history to be too short
    mod_short[["history"]] <-
      purrr::chuck(mod_short, "history")[1:5]

    testthat::expect_error(
      check_convergence_jsdm(mod_jsdm = mod_short),
      "mod_jsdm\\$history must be a numeric vector of length >= 10"
    )
  }
)

testthat::test_that(
  "check_convergence_jsdm() returns list with correct names",
  {
    testthat::skip_if_not_installed("sjSDM")

    set.seed(900723)

    data_community <-
      base::data.frame(
        sp1 = base::c(1, 0, 1, 0, 1, 0, 1, 0, 1, 0),
        sp2 = base::c(0, 1, 1, 0, 1, 1, 0, 1, 0, 1)
      )
    data_abiotic <-
      base::data.frame(
        temp = base::seq(10, 55, by = 5),
        precip = base::seq(100, 1000, by = 100)
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
        iter = 20L,
        n_early_stopping = 0L,
        sampling = 5L,
        step_size = 5L,
        verbose = FALSE
      )

    result <-
      check_convergence_jsdm(mod_jsdm = mod_example)

    testthat::expect_type(result, "list")
    testthat::expect_named(
      result,
      base::c(
        "linear_trend_slope",
        "median_diff",
        "convergence_plot",
        "note",
        "epochs_run",
        "early_stopping_triggered"
      )
    )
  }
)

testthat::test_that(
  "check_convergence_jsdm() returns correct types for each element",
  {
    testthat::skip_if_not_installed("sjSDM")

    set.seed(900723)

    data_community <-
      base::data.frame(
        sp1 = base::c(1, 0, 1, 0, 1, 0, 1, 0, 1, 0),
        sp2 = base::c(0, 1, 1, 0, 1, 1, 0, 1, 0, 1)
      )
    data_abiotic <-
      base::data.frame(
        temp = base::seq(10, 55, by = 5),
        precip = base::seq(100, 1000, by = 100)
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
        iter = 20L,
        n_early_stopping = 0L,
        sampling = 5L,
        step_size = 5L,
        verbose = FALSE
      )

    result <-
      check_convergence_jsdm(mod_jsdm = mod_example)

    # Numeric diagnostics
    testthat::expect_type(
      purrr::chuck(result, "linear_trend_slope"), "double"
    )
    testthat::expect_length(
      purrr::chuck(result, "linear_trend_slope"), 1L
    )
    testthat::expect_true(
      purrr::chuck(result, "linear_trend_slope") >= 0
    )

    testthat::expect_type(
      purrr::chuck(result, "median_diff"), "double"
    )
    testthat::expect_length(
      purrr::chuck(result, "median_diff"), 1L
    )
    testthat::expect_true(
      purrr::chuck(result, "median_diff") >= 0
    )

    # Plot is a ggplot
    testthat::expect_s3_class(
      purrr::chuck(result, "convergence_plot"), "ggplot"
    )

    # Note is a character string
    testthat::expect_type(
      purrr::chuck(result, "note"), "character"
    )
    testthat::expect_length(
      purrr::chuck(result, "note"), 1L
    )

    # epochs_run is numeric, length 1, >= 1
    testthat::expect_true(
      base::is.numeric(purrr::chuck(result, "epochs_run"))
    )
    testthat::expect_length(
      purrr::chuck(result, "epochs_run"), 1L
    )
    testthat::expect_true(
      purrr::chuck(result, "epochs_run") >= 1
    )

    # early_stopping_triggered is logical, length 1
    testthat::expect_type(
      purrr::chuck(result, "early_stopping_triggered"),
      "logical"
    )
    testthat::expect_length(
      purrr::chuck(result, "early_stopping_triggered"), 1L
    )
  }
)

testthat::test_that(
  "check_convergence_jsdm() detects trailing zeros (early stopping)",
  {
    testthat::skip_if_not_installed("sjSDM")

    set.seed(900723)

    data_community <-
      base::data.frame(
        sp1 = base::c(1, 0, 1, 0, 1, 0, 1, 0, 1, 0),
        sp2 = base::c(0, 1, 1, 0, 1, 1, 0, 1, 0, 1)
      )
    data_abiotic <-
      base::data.frame(
        temp = base::seq(10, 55, by = 5),
        precip = base::seq(100, 1000, by = 100)
      )
    mod_es <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = base::as.matrix(data_community),
          data_abiotic_to_fit = data_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        error_family = "binomial",
        iter = 20L,
        sampling = 5L,
        step_size = 5L,
        verbose = FALSE
      )

    # Patch: 30 real loss values followed by 20 trailing zeros
    mod_es[["history"]] <-
      base::c(
        base::seq(5, 1, length.out = 30),
        base::rep(0, 20)
      )

    result <-
      check_convergence_jsdm(mod_jsdm = mod_es)

    testthat::expect_true(
      purrr::chuck(result, "epochs_run") == 30
    )
    testthat::expect_true(
      purrr::chuck(result, "early_stopping_triggered")
    )
    testthat::expect_true(
      purrr::chuck(result, "linear_trend_slope") >= 0
    )
    testthat::expect_true(
      purrr::chuck(result, "median_diff") >= 0
    )
  }
)

testthat::test_that(
  "check_convergence_jsdm() no early stopping if no trailing zeros",
  {
    testthat::skip_if_not_installed("sjSDM")

    set.seed(900723)

    data_community <-
      base::data.frame(
        sp1 = base::c(1, 0, 1, 0, 1, 0, 1, 0, 1, 0),
        sp2 = base::c(0, 1, 1, 0, 1, 1, 0, 1, 0, 1)
      )
    data_abiotic <-
      base::data.frame(
        temp = base::seq(10, 55, by = 5),
        precip = base::seq(100, 1000, by = 100)
      )
    mod_full <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = base::as.matrix(data_community),
          data_abiotic_to_fit = data_abiotic
        ),
        sel_abiotic_formula = stats::as.formula("~ temp + precip"),
        spatial_method = "none",
        error_family = "binomial",
        iter = 20L,
        sampling = 5L,
        step_size = 5L,
        verbose = FALSE
      )

    # Patch history with no trailing zeros (all values > 0)
    mod_full[["history"]] <-
      base::seq(5, 1, length.out = 50)

    result <-
      check_convergence_jsdm(mod_jsdm = mod_full)

    testthat::expect_false(
      purrr::chuck(result, "early_stopping_triggered")
    )
    testthat::expect_true(
      purrr::chuck(result, "epochs_run") ==
        base::length(purrr::chuck(mod_full, "history"))
    )
  }
)
