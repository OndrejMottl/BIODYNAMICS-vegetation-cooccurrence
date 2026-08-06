testthat::test_that(
  "diagnose_sjsdm_gpu_runtime() is non-aborting and structured",
  {
    testthat::expect_false(
      "fail_on_error" %in%
        base::names(base::formals(diagnose_sjsdm_gpu_runtime))
    )

    testthat::expect_no_error(
      result <- diagnose_sjsdm_gpu_runtime(verbose = FALSE)
    )

    testthat::expect_named(
      result,
      base::c(
        "reticulate_available",
        "python_path",
        "torch_available",
        "torch_version",
        "torch_compiled_cuda",
        "cuda_version",
        "cuda_runtime_available",
        "gpu_device_count",
        "gpu_device_names",
        "status_ok"
      )
    )
  }
)

testthat::test_that(
  "diagnose_sjsdm_gpu_runtime() validates verbosity",
  {
    testthat::expect_error(
      diagnose_sjsdm_gpu_runtime(verbose = NA),
      "verbose"
    )
  }
)
