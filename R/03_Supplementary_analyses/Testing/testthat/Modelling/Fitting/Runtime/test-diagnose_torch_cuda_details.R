testthat::test_that(
  "diagnose_torch_cuda_details() returns the runtime detail contract",
  {
    testthat::expect_no_error(
      result <- diagnose_torch_cuda_details(verbose = FALSE)
    )

    testthat::expect_named(
      result,
      base::c(
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

    testthat::expect_type(result[["status_ok"]], "logical")

    testthat::expect_error(
      diagnose_torch_cuda_details(verbose = NA),
      "verbose"
    )
  }
)
