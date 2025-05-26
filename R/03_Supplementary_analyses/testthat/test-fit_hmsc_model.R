testthat::test_that(
  desc = "return correct class",
  code = {
    mod_example <-
      Hmsc::Hmsc(
        Y = Hmsc::TD$Y,
        XData = Hmsc::TD$X,
        XFormula = ~ x1 + x2,
        distr = "probit"
      )

    invisible(
      capture.output({
        result <-
          fit_hmsc_model(
            mod_hmsc = mod_example,
            n_chains = 1,
            n_samples = 10,
            n_thin = 1,
            n_transient = 2,
            n_parallel = 1,
            n_samples_verbose = 1
          )
      })
    )

    testthat::expect_s3_class(
      result,
      "Hmsc"
    )
  }
)

testthat::test_that(
  desc = "return correct data structure",
  code = {
    mod_example <-
      Hmsc::Hmsc(
        Y = Hmsc::TD$Y,
        XData = Hmsc::TD$X,
        XFormula = ~ x1 + x2,
        distr = "probit"
      )

    invisible(
      capture.output({
        result <-
          fit_hmsc_model(
            mod_hmsc = mod_example,
            n_chains = 1,
            n_samples = 10,
            n_thin = 1,
            n_transient = 2,
            n_parallel = 1,
            n_samples_verbose = 1
          )
      })
    )

    testthat::expect_true(
      "repList" %in% names(result)
    )

    testthat::expect_true(
      !is.null(result$samples) &&
        !is.null(result$transient) &&
        !is.null(result$thin) &&
        !is.null(result$randSeed)
    )
  }
)

testthat::test_that(
  desc = "handels invalid input",
  code = {
    mod_example <-
      Hmsc::Hmsc(
        Y = Hmsc::TD$Y,
        XData = Hmsc::TD$X,
        XFormula = ~ x1 + x2,
        distr = "probit"
      )

    testthat::expect_error(
      fit_hmsc_model(
        mod_hmsc = NULL,
        n_chains = 1,
        n_samples = 10,
        n_thin = 1,
        n_transient = 2,
        n_parallel = 1,
        n_samples_verbose = 1
      )
    )

    testthat::expect_error(
      fit_hmsc_model(
        mod_hmsc = "invalid",
        n_chains = 1,
        n_samples = 10,
        n_thin = 1,
        n_transient = 2,
        n_parallel = 1,
        n_samples_verbose = 1
      )
    )

    testthat::expect_error(
      fit_hmsc_model(
        mod_hmsc = mod_example,
        n_chains = NULL,
        n_samples = 10,
        n_thin = 1,
        n_transient = 2,
        n_parallel = 1,
        n_samples_verbose = 1
      )
    )

    testthat::expect_error(
      fit_hmsc_model(
        mod_hmsc = mod_example,
        n_chains = -1,
        n_samples = 10,
        n_thin = 1,
        n_transient = 2,
        n_parallel = 1,
        n_samples_verbose = 1
      )
    )

    testthat::expect_error(
      fit_hmsc_model(
        mod_hmsc = mod_example,
        n_chains = 1,
        n_samples = NULL,
        n_thin = 1,
        n_transient = 2,
        n_parallel = 1,
        n_samples_verbose = 1
      )
    )

    testthat::expect_error(
      fit_hmsc_model(
        mod_hmsc = mod_example,
        n_chains = 1,
        n_samples = -1,
        n_thin = 1,
        n_transient = 2,
        n_parallel = 1,
        n_samples_verbose = 1
      )
    )

    testthat::expect_error(
      fit_hmsc_model(
        mod_hmsc = mod_example,
        n_chains = 1,
        n_samples = 10,
        n_thin = NULL,
        n_transient = 2,
        n_parallel = 1,
        n_samples_verbose = 1
      )
    )

    testthat::expect_error(
      fit_hmsc_model(
        mod_hmsc = mod_example,
        n_chains = 1,
        n_samples = 10,
        n_thin = -1,
        n_transient = 2,
        n_parallel = 1,
        n_samples_verbose = 1
      )
    )

    testthat::expect_error(
      fit_hmsc_model(
        mod_hmsc = mod_example,
        n_chains = 1,
        n_samples = 10,
        n_thin = 1,
        n_transient = NULL,
        n_parallel = 1,
        n_samples_verbose = 1
      )
    )

    testthat::expect_error(
      fit_hmsc_model(
        mod_hmsc = mod_example,
        n_chains = 1,
        n_samples = 10,
        n_thin = 1,
        n_transient = -1,
        n_parallel = 1,
        n_samples_verbose = 1
      )
    )

    testthat::expect_error(
      fit_hmsc_model(
        mod_hmsc = mod_example,
        n_chains = 1,
        n_samples = 10,
        n_thin = 1,
        n_transient = 1,
        n_parallel = NULL,
        n_samples_verbose = 1
      )
    )

    testthat::expect_error(
      fit_hmsc_model(
        mod_hmsc = mod_example,
        n_chains = 1,
        n_samples = 10,
        n_thin = 1,
        n_transient = 1,
        n_parallel = -1,
        n_samples_verbose = 1
      )
    )

    testthat::expect_error(
      fit_hmsc_model(
        mod_hmsc = mod_example,
        n_chains = 1,
        n_samples = 10,
        n_thin = 1,
        n_transient = 1,
        n_parallel = 1,
        n_samples_verbose = NULL
      )
    )

    testthat::expect_error(
      fit_hmsc_model(
        mod_hmsc = mod_example,
        n_chains = 1,
        n_samples = 10,
        n_thin = 1,
        n_transient = 1,
        n_parallel = 1,
        n_samples_verbose = -1
      )
    )
  }
)
