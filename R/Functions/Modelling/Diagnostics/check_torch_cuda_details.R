#' @title Internal: Check Torch and CUDA Details
#' @description
#' Shared helper function to avoid code duplication between
#' `verify_sjsdm_setup()` and `check_cuda_gpu_runtime()`.
#' Safely introspects PyTorch and CUDA availability.
#' @param fail_on_error
#' Logical. If `TRUE`, abort on torch/CUDA errors.
#' @param verbose
#' Logical. If `TRUE`, print diagnostic messages.
#' @return
#' Named list with torch/CUDA diagnostic results:
#' - `torch_available`: torch import success
#' - `torch_version`: version string
#' - `torch_compiled_cuda`: CUDA compilation flag
#' - `cuda_version`: CUDA version (if compiled)
#' - `cuda_runtime_available`: GPU visibility at runtime
#' - `gpu_device_count`: number of visible GPUs
#' - `gpu_device_names`: names of visible GPU devices
#' - `status_ok`: both compilation and runtime successful
#' @keywords internal
#' @noRd
.check_torch_cuda_details <- function(
    fail_on_error = FALSE,
    verbose = FALSE) {
  res <-
    base::list(
      torch_available = FALSE,
      torch_version = NA_character_,
      torch_compiled_cuda = FALSE,
      cuda_version = NA_character_,
      cuda_runtime_available = FALSE,
      gpu_device_count = NA_integer_,
      gpu_device_names = character(0),
      status_ok = FALSE
    )

  torch <-
    tryCatch(
      expr = {
        reticulate::import("torch")
      },
      error = function(e) {
        NULL
      }
    )

  if (
    is.null(torch)
  ) {
    if (
      isTRUE(fail_on_error)
    ) {
      cli::cli_abort(
        c(
          "GPU preflight failed: Python package {.pkg torch} not found.",
          "i" = paste0(
            "Install CUDA wheels in the active environment with: ",
            "pip install --upgrade --force-reinstall torch torchvision ",
            "torchaudio --index-url https://download.pytorch.org/whl/cu121"
          )
        )
      )
    }

    return(res)
  }

  res$torch_available <- TRUE
  res$torch_version <- as.character(torch$`__version__`)

  torch_cuda_version <-
    tryCatch(
      expr = {
        torch$version$cuda
      },
      error = function(e) {
        NULL
      }
    )

  flag_compiled_with_cuda <-
    isFALSE(is.null(torch_cuda_version)) &&
    nzchar(as.character(torch_cuda_version))

  res$torch_compiled_cuda <- flag_compiled_with_cuda
  res$cuda_version <- as.character(torch_cuda_version)

  flag_cuda_runtime_available <-
    tryCatch(
      expr = {
        isTRUE(torch$cuda$is_available())
      },
      error = function(e) {
        FALSE
      }
    )

  res$cuda_runtime_available <- flag_cuda_runtime_available

  if (
    isTRUE(flag_cuda_runtime_available)
  ) {
    device_count <-
      tryCatch(
        expr = {
          as.integer(torch$cuda$device_count())
        },
        error = function(e) {
          NA_integer_
        }
      )

    res$gpu_device_count <- device_count

    if (
      isTRUE(!is.na(device_count)) && device_count > 0L
    ) {
      res$gpu_device_names <-
        purrr::map_chr(
          .x = base::seq_len(device_count) - 1L,
          .f = ~ {
            tryCatch(
              expr = {
                as.character(torch$cuda$get_device_name(.x))
              },
              error = function(e) {
                "Unknown GPU"
              }
            )
          }
        )
    }
  }

  res$status_ok <-
    isTRUE(flag_compiled_with_cuda) &&
    isTRUE(flag_cuda_runtime_available)

  if (
    isFALSE(res$status_ok) &&
      isTRUE(fail_on_error)
  ) {
    cli::cli_abort(
      c(
        "GPU preflight failed.",
        "i" = "Torch is CUDA-compiled but runtime cannot see a GPU,",
        "i" = "or torch is not CUDA-compiled in this environment.",
        "i" = "Fix NVIDIA driver/device visibility and verify the active",
        "i" = "RETICULATE_PYTHON environment uses CUDA torch wheels."
      )
    )
  }

  return(res)
}
