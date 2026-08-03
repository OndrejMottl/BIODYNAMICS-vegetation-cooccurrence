# Input validation - mod_jsdm -----

testthat::test_that(
  "compute_jsdm_se() rejects NULL mod_jsdm",
  {
    testthat::expect_error(
      compute_jsdm_se(mod_jsdm = NULL),
      "`mod_jsdm` must be an object of class 'sjSDM'"
    )
  }
)

testthat::test_that(
  "compute_jsdm_se() rejects non-sjSDM mod_jsdm",
  {
    mock_not_sjsdm <-
      base::list(x = 1)

    testthat::expect_error(
      compute_jsdm_se(mod_jsdm = mock_not_sjsdm),
      "`mod_jsdm` must be an object of class 'sjSDM'"
    )

    testthat::expect_error(
      compute_jsdm_se(mod_jsdm = "text"),
      "`mod_jsdm` must be an object of class 'sjSDM'"
    )
  }
)

# Input validation - parallel -----

testthat::test_that(
  "compute_jsdm_se() validates parallel argument",
  {
    mock_sjsdm <-
      base::structure(base::list(), class = "sjSDM")

    testthat::expect_error(
      compute_jsdm_se(
        mod_jsdm = mock_sjsdm,
        parallel = "a"
      ),
      "`parallel` must be a single non-negative numeric"
    )

    testthat::expect_error(
      compute_jsdm_se(
        mod_jsdm = mock_sjsdm,
        parallel = -1
      ),
      "`parallel` must be a single non-negative numeric"
    )

    testthat::expect_error(
      compute_jsdm_se(
        mod_jsdm = mock_sjsdm,
        parallel = c(1, 2)
      ),
      "`parallel` must be a single non-negative numeric"
    )
  }
)

# Input validation - step_size -----

testthat::test_that(
  "compute_jsdm_se() validates step_size argument",
  {
    mock_sjsdm <-
      base::structure(base::list(), class = "sjSDM")

    testthat::expect_error(
      compute_jsdm_se(
        mod_jsdm = mock_sjsdm,
        step_size = 0
      ),
      "`step_size` must be NULL or a single positive"
    )

    testthat::expect_error(
      compute_jsdm_se(
        mod_jsdm = mock_sjsdm,
        step_size = -5
      ),
      "`step_size` must be NULL or a single positive"
    )

    testthat::expect_error(
      compute_jsdm_se(
        mod_jsdm = mock_sjsdm,
        step_size = "x"
      ),
      "`step_size` must be NULL or a single positive"
    )
  }
)

# Input validation - verbose -----

testthat::test_that(
  "compute_jsdm_se() validates verbose argument",
  {
    mock_sjsdm <-
      base::structure(base::list(), class = "sjSDM")

    testthat::expect_error(
      compute_jsdm_se(
        mod_jsdm = mock_sjsdm,
        verbose = "yes"
      ),
      "`verbose` must be a single non-NA logical value"
    )

    testthat::expect_error(
      compute_jsdm_se(
        mod_jsdm = mock_sjsdm,
        verbose = 1
      ),
      "`verbose` must be a single non-NA logical value"
    )

    testthat::expect_error(
      compute_jsdm_se(
        mod_jsdm = mock_sjsdm,
        verbose = NULL
      ),
      "`verbose` must be a single non-NA logical value"
    )

    testthat::expect_error(
      compute_jsdm_se(
        mod_jsdm = mock_sjsdm,
        verbose = c(TRUE, FALSE)
      ),
      "`verbose` must be a single non-NA logical value"
    )

    testthat::expect_error(
      compute_jsdm_se(
        mod_jsdm = mock_sjsdm,
        verbose = NA
      ),
      "`verbose` must be a single non-NA logical value"
    )
  }
)

# Happy path -----

testthat::test_that(
  "compute_jsdm_se() returns sjSDM with se populated",
  {
    testthat::skip_if_not(
      sjSDM::is_torch_available(),
      message = "PyTorch not available, skipping sjSDM tests"
    )

    set.seed(900723)

    com <-
      sjSDM::simulate_SDM(
        env = 3L,
        species = 5L,
        sites = 50L
      )

    mod_jsdm <-
      sjSDM::sjSDM(
        Y = com$response,
        env = sjSDM::linear(
          data = com$env_weights,
          formula = ~ X1 + X2 + X3
        ),
        iter = 5L,
        se = FALSE,
        verbose = FALSE
      )

    res <-
      compute_jsdm_se(
        mod_jsdm = mod_jsdm,
        parallel = 0L
      )

    testthat::expect_s3_class(res, "sjSDM")
    testthat::expect_true(
      !base::is.null(purrr::pluck(res, "se"))
    )
  }
)

testthat::test_that(
  "compute_jsdm_se() works with explicit step_size",
  {
    testthat::skip_if_not(
      sjSDM::is_torch_available(),
      message = "PyTorch not available, skipping sjSDM tests"
    )

    set.seed(900723)

    com <-
      sjSDM::simulate_SDM(
        env = 3L,
        species = 5L,
        sites = 50L
      )

    mod_jsdm <-
      sjSDM::sjSDM(
        Y = com$response,
        env = sjSDM::linear(
          data = com$env_weights,
          formula = ~ X1 + X2 + X3
        ),
        iter = 5L,
        se = FALSE,
        verbose = FALSE
      )

    res <-
      compute_jsdm_se(
        mod_jsdm = mod_jsdm,
        parallel = 0L,
        step_size = 32L
      )

    testthat::expect_s3_class(res, "sjSDM")
    testthat::expect_true(
      !base::is.null(purrr::pluck(res, "se"))
    )
  }
)
