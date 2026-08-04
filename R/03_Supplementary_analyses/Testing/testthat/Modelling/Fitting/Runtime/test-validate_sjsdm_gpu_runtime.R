testthat::test_that(
  "validate_sjsdm_gpu_runtime() returns successful diagnostics",
  {
    diagnostics <-
      base::list(
        reticulate_available = TRUE,
        python_path = "python",
        torch_available = TRUE,
        torch_version = "test",
        torch_compiled_cuda = TRUE,
        cuda_version = "test",
        cuda_runtime_available = TRUE,
        gpu_device_count = 1L,
        gpu_device_names = "GPU",
        status_ok = TRUE
      )

    rlang::local_bindings(
      diagnose_sjsdm_gpu_runtime = function(verbose = TRUE) diagnostics,
      .env = environment(validate_sjsdm_gpu_runtime)
    )

    result <- validate_sjsdm_gpu_runtime(verbose = FALSE)

    testthat::expect_identical(result, diagnostics)
  }
)

testthat::test_that(
  "validate_sjsdm_gpu_runtime() aborts for unavailable requirements",
  {
    diagnostics <-
      base::list(
        reticulate_available = FALSE,
        python_path = NA_character_,
        torch_available = FALSE,
        torch_version = NA_character_,
        torch_compiled_cuda = FALSE,
        cuda_version = NA_character_,
        cuda_runtime_available = FALSE,
        gpu_device_count = NA_integer_,
        gpu_device_names = character(0),
        status_ok = FALSE
      )

    rlang::local_bindings(
      diagnose_sjsdm_gpu_runtime = function(verbose = TRUE) diagnostics,
      .env = environment(validate_sjsdm_gpu_runtime)
    )

    testthat::expect_error(
      validate_sjsdm_gpu_runtime(verbose = FALSE),
      "reticulate"
    )

    diagnostics <-
      diagnostics |>
      purrr::list_modify(reticulate_available = TRUE)

    testthat::expect_error(
      validate_sjsdm_gpu_runtime(verbose = FALSE),
      "torch"
    )

    diagnostics <-
      diagnostics |>
      purrr::list_modify(torch_available = TRUE)

    testthat::expect_error(
      validate_sjsdm_gpu_runtime(verbose = FALSE),
      "not compiled with CUDA"
    )

    diagnostics <-
      diagnostics |>
      purrr::list_modify(torch_compiled_cuda = TRUE)

    testthat::expect_error(
      validate_sjsdm_gpu_runtime(verbose = FALSE),
      "CUDA runtime is not available"
    )
  }
)
