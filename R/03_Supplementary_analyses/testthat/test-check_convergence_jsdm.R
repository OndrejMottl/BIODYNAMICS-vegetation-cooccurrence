testthat::test_that(
  "check_convergence_jsdm() rejects non-sjSDM input",
  {
    testthat::skip_if_not_installed("sjSDM")

    testthat::expect_error(
      check_convergence_jsdm(mod_jsdm = NULL),
      "mod_jsdm must be of class 'sjSDM'"
    )

    testthat::expect_error(
      check_convergence_jsdm(mod_jsdm = list()),
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
      data.frame(
        sp1 = c(1, 0, 1, 0, 1),
        sp2 = c(0, 1, 1, 0, 1)
      )
    data_abiotic <-
      data.frame(
        temp = c(10, 15, 20, 25, 30),
        precip = c(100, 200, 300, 400, 500)
      )
    mod_short <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(data_community),
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
    mod_short$history <- mod_short$history[1:5]

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
      data.frame(
        sp1 = c(1, 0, 1, 0, 1, 0, 1, 0, 1, 0),
        sp2 = c(0, 1, 1, 0, 1, 1, 0, 1, 0, 1)
      )
    data_abiotic <-
      data.frame(
        temp = seq(10, 55, by = 5),
        precip = seq(100, 1000, by = 100)
      )
    mod_example <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(data_community),
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

    result <-
      check_convergence_jsdm(mod_jsdm = mod_example)

    testthat::expect_type(result, "list")
    testthat::expect_named(
      result,
      c(
        "linear_trend_slope",
        "median_diff",
        "convergence_plot",
        "note"
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
      data.frame(
        sp1 = c(1, 0, 1, 0, 1, 0, 1, 0, 1, 0),
        sp2 = c(0, 1, 1, 0, 1, 1, 0, 1, 0, 1)
      )
    data_abiotic <-
      data.frame(
        temp = seq(10, 55, by = 5),
        precip = seq(100, 1000, by = 100)
      )
    mod_example <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(data_community),
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

    result <-
      check_convergence_jsdm(mod_jsdm = mod_example)

    # Numeric diagnostics
    testthat::expect_type(
      result$linear_trend_slope, "double"
    )
    testthat::expect_length(result$linear_trend_slope, 1L)
    testthat::expect_true(result$linear_trend_slope >= 0)

    testthat::expect_type(result$median_diff, "double")
    testthat::expect_length(result$median_diff, 1L)
    testthat::expect_true(result$median_diff >= 0)

    # Plot is a ggplot
    testthat::expect_s3_class(
      result$convergence_plot, "ggplot"
    )

    # Note is a character string
    testthat::expect_type(result$note, "character")
    testthat::expect_length(result$note, 1L)
  }
)
