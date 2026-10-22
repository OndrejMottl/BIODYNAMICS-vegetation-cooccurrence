testthat::test_that("likelihood iteration preserves values and RNG state", {
  base::set.seed(seed = 900723L)
  mat_expected <-
    base::matrix(
      data = stats::runif(n = 12L) + base::rep(1:3, each = 4L),
      nrow = 4L,
      ncol = 3L
    )
  vec_seed_expected <-
    base::get(x = ".Random.seed", envir = base::globalenv())
  base::set.seed(seed = 900723L)
  mat_actual <-
    run_sjsdm_likelihood_sequence(
      X = 1:3,
      FUN = function(i) stats::runif(n = 4L) + i,
      verbose = FALSE
    )
  testthat::expect_identical(mat_actual, mat_expected)
  testthat::expect_identical(
    base::get(x = ".Random.seed", envir = base::globalenv()),
    vec_seed_expected
  )
})

testthat::test_that("likelihood progress identifies starts and completions", {
  testthat::expect_message(
    run_sjsdm_likelihood_sequence(
      X = 1:2,
      FUN = base::identity
    ),
    "UTC.*taxon 1/2.*starting"
  )
  testthat::expect_message(
    run_sjsdm_likelihood_sequence(
      X = 1L,
      FUN = base::identity
    ),
    "UTC.*taxon 1/1.*completed.*seconds"
  )
  testthat::expect_error(
    run_sjsdm_likelihood_sequence(
      X = 1L,
      FUN = function(i) base::stop("likelihood error"),
      verbose = FALSE
    ),
    "likelihood error"
  )
})

testthat::test_that("likelihood mapping keeps empty and list contracts", {
  testthat::expect_identical(
    run_sjsdm_likelihood_sequence(
      X = base::integer(),
      FUN = base::identity,
      verbose = FALSE
    ),
    base::list()
  )
  testthat::expect_identical(
    run_sjsdm_likelihood_sequence(
      X = base::c(a = 1, b = 2),
      FUN = base::identity,
      simplify = FALSE,
      verbose = FALSE
    ),
    base::list(a = 1, b = 2)
  )
})

testthat::test_that("likelihood messages distinguish decomposition passes", {
  environment_progress <-
    rlang::env(index_pass = 0L,
      phase_ids = base::c("full", "saturated"))
  testthat::expect_message(
    run_sjsdm_likelihood_sequence(X = 1L, FUN = base::identity,
      progress_state = environment_progress),
    "likelihood full, taxon"
  )
  testthat::expect_message(
    run_sjsdm_likelihood_sequence(X = 1L, FUN = base::identity,
      progress_state = environment_progress),
    "likelihood saturated, taxon"
  )
})
