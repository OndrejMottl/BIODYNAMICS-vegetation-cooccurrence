#' @title Validate the sjSDM GPU Runtime
#' @description
#' Runs strict validation for GPU-only sjSDM workflows using the structured
#' result from `diagnose_sjsdm_gpu_runtime()`.
#' @param verbose Logical. If `TRUE` (default), diagnostics are printed.
#' @return The successful named GPU-runtime diagnostic list.
#' @details
#' Unlike `diagnose_sjsdm_gpu_runtime()`, this function aborts when reticulate,
#' torch, a CUDA-enabled torch build, or a visible CUDA device is unavailable.
#' @seealso [diagnose_sjsdm_gpu_runtime()], [fit_jsdm_model()]
#' @export
validate_sjsdm_gpu_runtime <- function(verbose = TRUE) {
  assertthat::assert_that(
    base::is.logical(verbose),
    base::length(verbose) == 1L,
    !base::is.na(verbose),
    msg = "`verbose` must be a logical value of length 1"
  )

  diagnostics <-
    diagnose_sjsdm_gpu_runtime(verbose = verbose)

  if (
    diagnostics |>
      purrr::chuck("reticulate_available") |>
      base::isFALSE()
  ) {
    cli::cli_abort(
      c(
        "GPU mode requires the {.pkg reticulate} package.",
        "i" = "Install it with install.packages('reticulate')."
      )
    )
  }

  if (
    diagnostics |>
      purrr::chuck("torch_available") |>
      base::isFALSE()
  ) {
    cli::cli_abort(
      c(
        "GPU mode requires Python package {.pkg torch}.",
        "i" = stringr::str_c(
          "Install a CUDA-enabled torch build in the active",
          " Python environment."
        )
      )
    )
  }

  if (
    diagnostics |>
      purrr::chuck("torch_compiled_cuda") |>
      base::isFALSE()
  ) {
    cli::cli_abort(
      c(
        "Torch is installed, but not compiled with CUDA.",
        "i" = stringr::str_c(
          "Install a CUDA-enabled torch build in the active",
          " Python environment."
        )
      )
    )
  }

  if (
    diagnostics |>
      purrr::chuck("cuda_runtime_available") |>
      base::isFALSE()
  ) {
    cli::cli_abort(
      c(
        "GPU mode requested, but CUDA runtime is not available.",
        "i" = "Check driver health and GPU visibility on this host."
      )
    )
  }

  return(diagnostics)
}
