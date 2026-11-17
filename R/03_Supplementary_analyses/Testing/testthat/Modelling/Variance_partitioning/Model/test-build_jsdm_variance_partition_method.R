fit_test_partition_model <- function(lambda_cov, seed, alpha_cov = 0.5) {
  base::set.seed(900723)
  data_dummy <-
    sjSDM::simulate_SDM(env = 3L, species = 6L, sites = 60L)
  data_abiotic <-
    base::data.frame(purrr::pluck(data_dummy, "env_weights"))
  base::names(data_abiotic) <- base::c("X1", "X2", "X3")
  data_coords <-
    base::data.frame(
      base::matrix(
        data = stats::rnorm(n = 120, mean = 0, sd = 0.3),
        nrow = 60,
        ncol = 2
      )
    )

  mod <-
    sjSDM::sjSDM(
      Y = purrr::pluck(data_dummy, "response"),
      env = sjSDM::linear(data = data_abiotic, formula = ~ X1 + X2 + X3),
      spatial = sjSDM::linear(data = data_coords, formula = ~ 0 + X1 * X2),
      biotic = sjSDM::bioticStruct(lambda = lambda_cov, alpha = alpha_cov),
      family = stats::binomial(link = "probit"),
      iter = 10L,
      verbose = FALSE,
      seed = seed,
      device = "cpu"
    )

  return(mod)
}

testthat::test_that(
  "build_jsdm_variance_partition_method() validates its inputs",
  {
    testthat::expect_error(
      build_jsdm_variance_partition_method(mod = stats::lm(mpg ~ wt, mtcars)),
      "sjSDM model"
    )
    testthat::expect_error(
      build_jsdm_variance_partition_method(
        mod = structure(base::list(), class = "sjSDM"),
        anova_function = "anova"
      ),
      "must be functions"
    )
  }
)

testthat::test_that(
  "build_jsdm_variance_partition_method() passes the penalty and seed",
  {
    testthat::skip_if_not_installed("sjSDM")

    # alpha = 0.2 makes the L1 and L2 shares differ, so a swapped mapping
    #   fails: sjSDM stores l1_cov = (1 - alpha) * lambda and
    #   l2_cov = alpha * lambda.
    mod <-
      fit_test_partition_model(lambda_cov = 0.1, seed = 123L, alpha_cov = 0.2)
    list_captured <- base::list()

    # The ANOVA stub refits two sub-models the way anova.sjSDM() does.
    anova_stub <- function(object, samples = 10L, verbose = FALSE, ...) {
      update(
        object,
        env_formula = NULL,
        spatial_formula = ~0,
        biotic = bioticStruct(diag = TRUE),
        verbose = verbose
      )
      update(
        object,
        env_formula = ~0,
        spatial_formula = ~0,
        biotic = bioticStruct(diag = FALSE),
        verbose = verbose
      )
      return("stub")
    }
    fit_capture <- function(...) {
      list_arguments <- base::list(...)
      list_captured[[base::length(list_captured) + 1L]] <<-
        list_arguments[base::c("biotic", "seed")]
      return(NULL)
    }

    method_partition <-
      build_jsdm_variance_partition_method(
        mod = mod,
        anova_function = anova_stub,
        fit_function = fit_capture
      )

    testthat::expect_equal(
      method_partition(object = mod, samples = 10L, verbose = FALSE),
      "stub"
    )
    testthat::expect_length(list_captured, 2L)
    purrr::walk(
      .x = list_captured,
      .f = ~ {
        testthat::expect_equal(.x[["seed"]], 123L)
        testthat::expect_equal(.x[["biotic"]][["l1_cov"]], 0.08)
        testthat::expect_equal(.x[["biotic"]][["l2_cov"]], 0.02)
      }
    )
    testthat::expect_equal(
      purrr::map_lgl(list_captured, ~ .x[["biotic"]][["diag"]]),
      base::c(TRUE, FALSE)
    )
  }
)

testthat::test_that(
  "build_jsdm_variance_partition_method() matches unpenalised installed ANOVA",
  {
    testthat::skip_if_not_installed("sjSDM")

    # With lambda_cov = 0 and the sjSDM default seed, nothing the adapter
    #   carries differs from what anova.sjSDM() uses, so CPU results are equal.
    seed_default <-
      base::eval(base::formals(sjSDM::sjSDM)[["seed"]])
    mod <-
      fit_test_partition_model(lambda_cov = 0, seed = seed_default)

    res_installed <-
      sjSDM:::anova.sjSDM(mod, samples = 200L, verbose = FALSE)
    res_adapter <-
      build_jsdm_variance_partition_method(mod = mod)(
        object = mod,
        samples = 200L,
        verbose = FALSE
      )

    testthat::expect_s3_class(res_adapter, "sjSDManova")
    testthat::expect_equal(
      res_adapter[["results"]],
      res_installed[["results"]]
    )
    testthat::expect_named(
      res_adapter,
      base::names(res_installed)
    )
  }
)
