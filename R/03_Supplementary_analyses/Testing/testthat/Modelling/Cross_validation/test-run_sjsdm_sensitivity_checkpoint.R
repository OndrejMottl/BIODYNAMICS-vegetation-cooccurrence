testthat::test_that("phase checkpoints reuse only matching successful work", {
  path_checkpoint <-
    withr::local_tempdir()
  n_calls <- 0L
  res_first <-
    run_sjsdm_sensitivity_checkpoint(
      expr = {
        n_calls <- n_calls + 1L
        42L
      },
      path_checkpoint = path_checkpoint,
      signature = "inputs_a",
      phase = "fit",
      verbose = FALSE
    )
  res_cached <-
    run_sjsdm_sensitivity_checkpoint(
      expr = base::stop("must not run"),
      path_checkpoint = path_checkpoint,
      signature = "inputs_a",
      phase = "fit",
      verbose = FALSE
    )
  testthat::expect_identical(res_first, 42L)
  testthat::expect_identical(res_cached, 42L)
  testthat::expect_identical(n_calls, 1L)
  testthat::expect_identical(
    run_sjsdm_sensitivity_checkpoint(
      expr = 43L,
      path_checkpoint = path_checkpoint,
      signature = "inputs_b",
      phase = "fit",
      verbose = FALSE
    ),
    43L
  )
})

testthat::test_that("failed phases are retried without discarding prior work", {
  path_checkpoint <-
    withr::local_tempdir()
  testthat::expect_error(
    run_sjsdm_sensitivity_checkpoint(
      expr = base::stop("decomposition interrupted"),
      path_checkpoint = path_checkpoint,
      signature = "inputs_a",
      phase = "anova",
      verbose = FALSE
    ),
    "decomposition interrupted"
  )
  testthat::expect_length(base::list.files(path_checkpoint), 0L)
  testthat::expect_message(
    run_sjsdm_sensitivity_checkpoint(
      expr = 1L,
      path_checkpoint = path_checkpoint,
      signature = "inputs_a",
      phase = "anova"
    ),
    "UTC.*anova"
  )
})

testthat::test_that("checkpoint arguments and corrupt evidence fail clearly", {
  testthat::expect_error(
    run_sjsdm_sensitivity_checkpoint(
      expr = 1L,
      signature = NA_character_,
      phase = "fit"
    ),
    "signature"
  )
  testthat::expect_error(
    run_sjsdm_sensitivity_checkpoint(
      expr = 1L,
      signature = "abc",
      phase = "../escape"
    ),
    "phase"
  )
  path_checkpoint <-
    withr::local_tempdir()
  run_sjsdm_sensitivity_checkpoint(
    expr = 1L,
    path_checkpoint = path_checkpoint,
    signature = "inputs_a",
    phase = "fit",
    verbose = FALSE
  )
  file_checkpoint <-
    base::list.files(path = path_checkpoint, full.names = TRUE)[[1L]]
  base::saveRDS(
    object = base::list(signature = "wrong_inputs", phase = "fit",
      result = 1L),
    file = file_checkpoint
  )
  testthat::expect_error(
    run_sjsdm_sensitivity_checkpoint(
      expr = base::stop("must not silently replace evidence"),
      path_checkpoint = path_checkpoint,
      signature = "inputs_a",
      phase = "fit",
      verbose = FALSE
    ),
    "Incompatible sensitivity checkpoint"
  )
})
