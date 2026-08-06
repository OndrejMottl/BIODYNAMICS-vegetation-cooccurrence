testthat::test_that(
  ".resolve_sjsdm_device() preserves CPU parallel settings",
  {
    validator_called <- FALSE
    validator <- function(verbose = TRUE) {
      validator_called <<- TRUE
    }

    result <-
      .resolve_sjsdm_device(
        device = "cpu",
        parallel = 2L,
        gpu_runtime_validator = validator
      )

    testthat::expect_identical(
      result,
      base::list(device = "cpu", parallel = 2L)
    )
    testthat::expect_false(validator_called)
  }
)

testthat::test_that(
  ".resolve_sjsdm_device() validates GPU and disables parallelism",
  {
    validator_called <- FALSE
    validator <- function(verbose = TRUE) {
      validator_called <<- TRUE
      testthat::expect_false(verbose)
    }

    testthat::expect_message(
      result <-
        .resolve_sjsdm_device(
          device = "gpu",
          parallel = 2L,
          gpu_runtime_validator = validator
        ),
      "Setting parallel to 0L"
    )

    testthat::expect_true(validator_called)
    testthat::expect_identical(
      result,
      base::list(device = "gpu", parallel = 0L)
    )
  }
)
