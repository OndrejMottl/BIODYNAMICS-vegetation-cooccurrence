#' @title Diagnose the sjSDM GPU Runtime
#' @description
#' Performs a non-aborting diagnostic of the Python, torch, and CUDA runtime
#' used by sjSDM. Strict GPU-only workflows should call
#' `validate_sjsdm_gpu_runtime()`.
#' @param verbose
#' Logical. If `TRUE` (default), progress and diagnostics are printed.
#' @return
#' A named list with diagnostic fields, including success flags,
#' torch version, CUDA version, and GPU names.
#' @details
#' This diagnostic always returns a result. Missing requirements are represented
#' by false or missing fields rather than an abort.
#' @seealso [fit_jsdm_model()], [validate_sjsdm_gpu_runtime()],
#'   [diagnose_sjsdm_setup()]
#' @export
diagnose_sjsdm_gpu_runtime <- function(
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.logical(verbose),
    base::length(verbose) == 1L,
    !base::is.na(verbose),
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
    base::isTRUE(verbose)
  ) {
    cli::cli_inform(c("i" = "Running GPU/CUDA preflight checks."))
  }

  if (
    base::isFALSE(base::requireNamespace("reticulate", quietly = TRUE))
  ) {
    if (
      base::isTRUE(verbose)
    ) {
      cli::cli_warn(c("!" = "reticulate is not installed."))
    }

    return(res_diagnostics)
  }

  res_diagnostics <-
    res_diagnostics |>
    purrr::list_modify(reticulate_available = TRUE)

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
    base::isFALSE(base::is.null(py_config))
  ) {
    python_path <-
      py_config |>
      purrr::chuck("python")

    res_diagnostics <-
      res_diagnostics |>
      purrr::list_modify(python_path = python_path)

    if (
      base::isTRUE(verbose)
    ) {
      cli::cli_inform(
        c(
          "v" = stringr::str_glue("Python: {python_path}")
        )
      )
    }
  }

  torch_results <-
    .diagnose_torch_cuda_details(
      verbose = verbose
    )

  res_diagnostics <-
    res_diagnostics |>
    purrr::list_modify(
      torch_available =
        torch_results |>
        purrr::chuck("torch_available"),
      torch_version =
        torch_results |>
        purrr::chuck("torch_version"),
      torch_compiled_cuda =
        torch_results |>
        purrr::chuck("torch_compiled_cuda"),
      cuda_version =
        torch_results |>
        purrr::chuck("cuda_version"),
      cuda_runtime_available =
        torch_results |>
        purrr::chuck("cuda_runtime_available"),
      gpu_device_count =
        torch_results |>
        purrr::chuck("gpu_device_count"),
      gpu_device_names =
        torch_results |>
        purrr::chuck("gpu_device_names"),
      status_ok =
        torch_results |>
        purrr::chuck("status_ok")
    )

  return(res_diagnostics)
}
