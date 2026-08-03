#' @title Check CUDA GPU Runtime for sjSDM
#' @description
#' Performs a strict preflight check for GPU-enabled sjSDM workflows.
#' Verifies torch import, CUDA compilation, and CUDA runtime visibility.
#' Does not fall back to CPU mode.
#' @param fail_on_error
#' Logical. If `TRUE` (default), the function aborts when a critical
#' GPU requirement is not met.
#' @param verbose
#' Logical. If `TRUE` (default), progress and diagnostics are printed.
#' @return
#' A named list with diagnostic fields, including success flags,
#' torch version, CUDA version, and GPU names.
#' @details
#' This function is a strict preflight for GPU-only workflows. It uses
#' `.check_torch_cuda_details()` internally to avoid code duplication
#' with `verify_sjsdm_setup()`.
#' @seealso fit_jsdm_model, verify_sjsdm_setup
#' @export
check_cuda_gpu_runtime <- function(
    fail_on_error = TRUE,
    verbose = TRUE) {
  assertthat::assert_that(
    is.logical(fail_on_error),
    length(fail_on_error) == 1,
    msg = "`fail_on_error` must be a logical value of length 1"
  )

  assertthat::assert_that(
    is.logical(verbose),
    length(verbose) == 1,
    msg = "`verbose` must be a logical value of length 1"
  )

  res_diagnostics <-
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

  if (
    isTRUE(verbose)
  ) {
    cli::cli_inform(c("i" = "Running GPU/CUDA preflight checks."))
  }

  if (
    isFALSE(requireNamespace("reticulate", quietly = TRUE))
  ) {
    if (
      isTRUE(fail_on_error)
    ) {
      cli::cli_abort(
        c(
          "GPU preflight failed: {.pkg reticulate} is not installed.",
          "i" = "Install with install.packages('reticulate')."
        )
      )
    }

    if (
      isTRUE(verbose)
    ) {
      cli::cli_warn(c("!" = "reticulate is not installed."))
    }

    return(res_diagnostics)
  }

  res_diagnostics$reticulate_available <- TRUE

  py_config <-
    tryCatch(
      expr = {
        reticulate::py_config()
      },
      error = function(e) {
        NULL
      }
    )

  if (
    isFALSE(is.null(py_config))
  ) {
    res_diagnostics$python_path <- py_config$python

    if (
      isTRUE(verbose)
    ) {
      cli::cli_inform(
        c(
          "v" = paste0("Python: ", py_config$python)
        )
      )
    }
  }

  torch_results <-
    .check_torch_cuda_details(
      fail_on_error = fail_on_error,
      verbose = verbose
    )

  res_diagnostics$torch_available <-
    torch_results$torch_available
  res_diagnostics$torch_version <-
    torch_results$torch_version
  res_diagnostics$torch_compiled_cuda <-
    torch_results$torch_compiled_cuda
  res_diagnostics$cuda_version <-
    torch_results$cuda_version
  res_diagnostics$cuda_runtime_available <-
    torch_results$cuda_runtime_available
  res_diagnostics$gpu_device_count <-
    torch_results$gpu_device_count
  res_diagnostics$gpu_device_names <-
    torch_results$gpu_device_names
  res_diagnostics$status_ok <-
    torch_results$status_ok

  return(res_diagnostics)
}
