testthat::test_that("progress ANOVA rejects invalid model and draw counts", {
  testthat::expect_error(
    compute_jsdm_variance_partition_with_progress(mod = NULL),
    "sjSDM"
  )
  testthat::expect_error(
    compute_jsdm_variance_partition_with_progress(
      mod = base::structure(base::list(), class = "sjSDM"),
      n_samples = 0L
    ),
    "n_samples"
  )
})

testthat::test_that("progress ANOVA leaves the package namespace untouched", {
  conditional_original <-
    base::get(
      x = "get_conditional_lls",
      envir = base::asNamespace("sjSDM")
    )
  anova_function <- function(object, samples, verbose) {
    base::list(
      samples = samples,
      instrumented = !base::identical(
        base::environment(get_conditional_lls),
        base::asNamespace("sjSDM")
      )
    )
  }
  res <-
    compute_jsdm_variance_partition_with_progress(
      mod = base::structure(base::list(), class = "sjSDM"),
      n_samples = 1000L,
      anova_function = anova_function
    )
  testthat::expect_identical(res[["samples"]], 1000L)
  testthat::expect_true(res[["instrumented"]])
  testthat::expect_identical(
    base::get(
      x = "get_conditional_lls",
      envir = base::asNamespace("sjSDM")
    ),
    conditional_original
  )
})
