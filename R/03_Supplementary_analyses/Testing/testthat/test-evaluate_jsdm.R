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
      evaluate_jsdm(mod_jsdm = list(a = 1))
    )
  }
)

testthat::test_that(
  desc = "evaluate_jsdm() returns a list with correct top-level names",
  code = {
    testthat::skip_if_not_installed("sjSDM")

    set.seed(900723)

    data_community <-
      data.frame(
        sp1 = c(1, 0, 1, 0, 1),
        sp2 = c(0, 1, 1, 0, 1),
        sp3 = c(1, 1, 0, 1, 0)
      )
    data_abiotic <-
      data.frame(
        temp = c(10, 15, 20, 25, 30),
        precip = c(100, 200, 300, 400, 500)
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
        sampling = 5L,
        step_size = 5L,
        verbose = FALSE
      )

    result <-
      evaluate_jsdm(mod_jsdm = mod_example)

    testthat::expect_type(result, "list")
    testthat::expect_length(result, 3)
    testthat::expect_named(result, c("model", "species", "convergence"))
  }
)

testthat::test_that(
  desc = "evaluate_jsdm() model element has correct R2 names and values",
  code = {
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
    mod_example <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(data_community),
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

    testthat::expect_type(result$model, "double")
    testthat::expect_named(result$model, c("R2-McFadden", "R2-Nagelkerke"))
    testthat::expect_true(is.numeric(result$model[["R2-McFadden"]]))
    testthat::expect_true(is.numeric(result$model[["R2-Nagelkerke"]]))
  }
)

testthat::test_that(
  desc = paste0(
    "evaluate_jsdm() species element is a tibble with correct columns",
    " for binomial family"
  ),
  code = {
    testthat::skip_if_not_installed("sjSDM")

    set.seed(900723)

    data_community <-
      data.frame(
        sp1 = c(1, 0, 1, 0, 1, 1, 0, 1),
        sp2 = c(0, 1, 1, 0, 1, 0, 1, 0),
        sp3 = c(1, 0, 0, 1, 1, 0, 0, 1)
      )
    data_abiotic <-
      data.frame(
        temp = c(10, 15, 20, 25, 30, 35, 40, 45),
        precip = c(100, 200, 300, 400, 500, 600, 700, 800)
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
        sampling = 10L,
        step_size = 5L,
        verbose = FALSE
      )

    result <-
      evaluate_jsdm(mod_jsdm = mod_example)

    # Class and dimensions
    testthat::expect_s3_class(result$species, "tbl_df")
    testthat::expect_equal(nrow(result$species), ncol(data_community))
    testthat::expect_named(
      result$species,
      c("species", "AUC", "Accuracy", "LogLoss")
    )

    # Species names match community columns
    testthat::expect_equal(
      result$species$species,
      colnames(data_community)
    )

    # AUC bounded [0, 1]
    testthat::expect_true(
      all(
        result$species$AUC >= 0 & result$species$AUC <= 1,
        na.rm = TRUE
      )
    )

    # Accuracy bounded [0, 1]
    testthat::expect_true(
      all(
        result$species$Accuracy >= 0 & result$species$Accuracy <= 1,
        na.rm = TRUE
      )
    )

    # LogLoss is non-negative
    testthat::expect_true(
      all(result$species$LogLoss >= 0, na.rm = TRUE)
    )
  }
)

testthat::test_that(
  desc = paste0(
    "evaluate_jsdm() species element contains RMSE column",
    " for non-binomial family"
  ),
  code = {
    testthat::skip_if_not_installed("sjSDM")

    set.seed(900723)

    data_community <-
      data.frame(
        sp1 = c(0.2, 0.5, 0.8, 0.1, 0.9),
        sp2 = c(0.4, 0.3, 0.7, 0.6, 0.2)
      )
    data_abiotic <-
      data.frame(
        temp = c(10, 15, 20, 25, 30),
        precip = c(100, 200, 300, 400, 500)
      )
    mod_example <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(data_community),
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

    testthat::expect_s3_class(result$species, "tbl_df")
    testthat::expect_equal(nrow(result$species), ncol(data_community))
    testthat::expect_named(result$species, c("species", "RMSE"))

    testthat::expect_equal(
      result$species$species,
      colnames(data_community)
    )

    testthat::expect_true(
      all(result$species$RMSE >= 0, na.rm = TRUE)
    )
  }
)

testthat::test_that(
  desc = "evaluate_jsdm() convergence element has expected structure",
  code = {
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
    mod_example <-
      fit_jsdm_model(
        data_to_fit = base::list(
          data_community_to_fit = as.matrix(data_community),
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

    convergence <- result$convergence

    testthat::expect_type(convergence, "list")
    testthat::expect_length(convergence, 6L)
    testthat::expect_named(
      convergence,
      c(
        "linear_trend_slope",
        "median_diff",
        "convergence_plot",
        "note",
        "epochs_run",
        "early_stopping_triggered"
      )
    )

    testthat::expect_type(convergence$linear_trend_slope, "double")
    testthat::expect_length(convergence$linear_trend_slope, 1L)
    testthat::expect_true(convergence$linear_trend_slope >= 0)

    testthat::expect_type(convergence$median_diff, "double")
    testthat::expect_length(convergence$median_diff, 1L)
    testthat::expect_true(convergence$median_diff >= 0)

    testthat::expect_s3_class(convergence$convergence_plot, "ggplot")

    testthat::expect_type(convergence$note, "character")
    testthat::expect_length(convergence$note, 1L)
  }
)
