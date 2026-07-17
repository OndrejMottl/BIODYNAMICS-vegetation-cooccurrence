testthat::test_that(
  "configure_sjsdm_predictor_structure() maps component models",
  {
    config_model_fitting <-
      base::list(
        use_spatial = TRUE,
        spatial_mode = "spatial",
        n_iter = 100L
      )

    model_formula <-
      stats::as.formula("~ age + bio_1")

    list_expected <-
      base::list(
        intercept_only =
          base::list(FALSE, FALSE, TRUE, FALSE, "~1"),
        abiotic_only =
          base::list(TRUE, FALSE, TRUE, FALSE, "~age + bio_1"),
        spatial_only =
          base::list(FALSE, TRUE, TRUE, TRUE, "~1"),
        abiotic_spatial =
          base::list(TRUE, TRUE, TRUE, TRUE, "~age + bio_1"),
        abiotic_spatial_no_associations =
          base::list(TRUE, TRUE, FALSE, TRUE, "~age + bio_1")
      )

    purrr::iwalk(
      .x = list_expected,
      .f = ~ {
        res <-
          configure_sjsdm_predictor_structure(
            predictor_structure = .y,
            config_model_fitting = config_model_fitting,
            model_formula = model_formula
          )

        testthat::expect_named(
          res,
          base::c(
            "predictor_structure",
            "uses_abiotic",
            "uses_spatial",
            "uses_associations",
            "config_model_fitting",
            "model_formula"
          )
        )
        testthat::expect_equal(res[["predictor_structure"]], .y)
        testthat::expect_equal(res[["uses_abiotic"]], .x[[1L]])
        testthat::expect_equal(res[["uses_spatial"]], .x[[2L]])
        testthat::expect_equal(res[["uses_associations"]], .x[[3L]])
        testthat::expect_equal(
          res[["config_model_fitting"]][["use_spatial"]],
          .x[[4L]]
        )
        testthat::expect_equal(
          base::deparse(res[["model_formula"]], width.cutoff = 500L),
          .x[[5L]]
        )
      }
    )

    testthat::expect_true(config_model_fitting[["use_spatial"]])
  }
)

testthat::test_that(
  "configure_sjsdm_predictor_structure() validates its contract",
  {
    testthat::expect_error(
      configure_sjsdm_predictor_structure(
        predictor_structure = "unknown",
        config_model_fitting = base::list(use_spatial = TRUE),
        model_formula = stats::as.formula("~ age")
      ),
      "predictor_structure"
    )

    testthat::expect_error(
      configure_sjsdm_predictor_structure(
        predictor_structure = "abiotic_only",
        config_model_fitting = NULL,
        model_formula = stats::as.formula("~ age")
      ),
      "config_model_fitting"
    )

    testthat::expect_error(
      configure_sjsdm_predictor_structure(
        predictor_structure = "abiotic_only",
        config_model_fitting = base::list(use_spatial = TRUE),
        model_formula = "~ age"
      ),
      "model_formula"
    )
  }
)
