#' @title Diagnose Torch and CUDA Details
#' @description
#' Non-aborting internal helper shared by the GPU-runtime and setup
#' diagnostics. Safely introspects PyTorch and CUDA availability.
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
.diagnose_torch_cuda_details <- function(
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
      isTRUE(verbose)
    ) {
      cli::cli_warn(
        c("!" = "Python package {.pkg torch} is unavailable.")
      )
    }

    return(res)
  }

  res <-
    res |>
    purrr::list_modify(
      torch_available = TRUE,
      torch_version =
        torch |>
        reticulate::py_get_attr("__version__") |>
        base::as.character()
    )

  torch_cuda <-
    torch |>
    reticulate::py_get_attr("cuda")

  torch_cuda_version <-
    tryCatch(
      expr = {
        torch |>
          reticulate::py_get_attr("version") |>
          reticulate::py_get_attr("cuda")
      },
      error = function(e) {
        NULL
      }
    )

  flag_compiled_with_cuda <-
    isFALSE(is.null(torch_cuda_version)) &&
    nzchar(as.character(torch_cuda_version))

  res <-
    res |>
    purrr::list_modify(
      torch_compiled_cuda = flag_compiled_with_cuda,
      cuda_version = base::as.character(torch_cuda_version)
    )

  flag_cuda_runtime_available <-
    tryCatch(
      expr = {
        torch_cuda |>
          reticulate::py_get_attr("is_available") |>
          base::do.call(args = base::list()) |>
          base::isTRUE()
      },
      error = function(e) {
        FALSE
      }
    )

  res <-
    res |>
    purrr::list_modify(
      cuda_runtime_available = flag_cuda_runtime_available
    )

  if (
    isTRUE(flag_cuda_runtime_available)
  ) {
    device_count <-
      tryCatch(
        expr = {
          torch_cuda |>
            reticulate::py_get_attr("device_count") |>
            base::do.call(args = base::list()) |>
            base::as.integer()
        },
        error = function(e) {
          NA_integer_
        }
      )

    res <-
      res |>
      purrr::list_modify(gpu_device_count = device_count)

    if (
      isTRUE(!is.na(device_count)) && device_count > 0L
    ) {
      get_device_name <-
        torch_cuda |>
        reticulate::py_get_attr("get_device_name")

      gpu_device_names <-
        purrr::map_chr(
          .x = base::seq_len(device_count) - 1L,
          .f = ~ {
            tryCatch(
              expr = {
                get_device_name(.x) |>
                  base::as.character()
              },
              error = function(e) {
                "Unknown GPU"
              }
            )
          }
        )

      res <-
        res |>
        purrr::list_modify(gpu_device_names = gpu_device_names)
    }
  }

  status_ok <-
    isTRUE(flag_compiled_with_cuda) &&
    isTRUE(flag_cuda_runtime_available)

  res <-
    res |>
    purrr::list_modify(status_ok = status_ok)

  if (
    isFALSE(status_ok) &&
      isTRUE(verbose)
  ) {
    cli::cli_warn(
      c(
        "!" = "The current torch runtime cannot use a CUDA GPU.",
        "i" = stringr::str_c(
          "Check the torch build, device visibility, and the active",
          " Python environment."
        )
      )
    )
  }

  return(res)
}
