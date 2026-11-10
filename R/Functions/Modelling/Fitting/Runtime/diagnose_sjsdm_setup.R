#' @title Diagnose the sjSDM Setup
#'
#' @description
#' Comprehensive non-aborting diagnosis of the sjSDM installation, including
#' the R console, Python, PyTorch, CUDA support, and sjSDM functionality.
#'
#' @param run_test_model Logical. Should a test model be fitted to
#' diagnose full functionality? Defaults to `interactive()`.
#'
#' @return
#' Invisible named list of logical flags: `radian_ok`, `python_ok`,
#' `pytorch_ok`, `cuda_available`, `sjsdm_ok`, and `test_model_ok`.
#' `radian_ok` is `FALSE` only when R runs inside radian and radian's own
#' Python cannot import PyTorch; it is `TRUE` in RStudio and plain R.
#' Called primarily for its printed report.
#'
#' @details
#' This function performs the following checks:
#' 1. R console: RStudio, radian, or plain R (`Rscript` or the R console)
#' 2. Python version and location, with reticulate's message when no
#'    usable Python is found
#' 3. PyTorch installation and version
#' 4. CUDA/GPU availability
#' 5. sjSDM package installation
#' 6. sjSDM Python dependencies
#' 7. Test model fitting (optional)
#'
#' R running inside radian shares its process with radian's Python, so
#' reticulate must use that Python and the project `RETICULATE_PYTHON` is
#' replaced by it. radian is therefore judged by whether its Python can
#' import PyTorch, not by whether a radian executable is on `PATH`. Outside
#' radian, reticulate follows `RETICULATE_PYTHON`.
#'
#' All checks print their status with [OK], [WARN], or [FAIL]. Failures are
#' represented in the returned list rather than raised as errors. Fixes point
#' to `Documentation/Materials/sjSDM_installation_guide.md`.
#'
#' @seealso
#' \code{\link[reticulate]{py_config}}
#' \code{\link[sjSDM]{sjSDM}}
#'
#' @export
diagnose_sjsdm_setup <- function(run_test_model = base::interactive()) {
  # Detect the R console. radian sets RADIAN_VERSION in its own process,
  #   so a radian executable on PATH says nothing about this session.
  in_rstudio <- base::Sys.getenv("RSTUDIO") == "1"
  radian_version <-
    base::Sys.getenv("RADIAN_VERSION")
  in_radian <-
    isFALSE(in_rstudio) && base::nzchar(radian_version)

  # Initialize results list. radian_ok is updated after the PyTorch check.
  results <-
    base::list(
      radian_ok = TRUE,
      python_ok = FALSE,
      pytorch_ok = FALSE,
      cuda_available = FALSE,
      sjsdm_ok = FALSE,
      test_model_ok = FALSE
    )


  cat("=============================================================\n")
  cat("           sjSDM Setup Diagnostics\n")

  if (
    in_rstudio
  ) {
    cat("           Running in: RStudio\n")
  } else if (
    in_radian
  ) {
    cat("           Running in: radian\n")
  } else {
    cat("           Running in: plain R session\n")
  }

  cat("=============================================================\n")



  #----------------------------------------------------------#
  # 1. Diagnose R console -----
  #----------------------------------------------------------#

  cat("1. Diagnosing R Console\n")
  cat("   ----------------------------------------\n")

  if (
    in_rstudio
  ) {
    cat("   [OK] Running in RStudio\n")
    cat("   reticulate follows RETICULATE_PYTHON\n")
  } else if (
    in_radian
  ) {
    cat("   [OK] Running in radian", radian_version, "\n")
    cat("   reticulate must use radian's own Python (see check 2)\n")
  } else {
    cat("   [OK] Running in plain R (Rscript or R console)\n")
    cat("   reticulate follows RETICULATE_PYTHON\n")
  }

  cat("\n")


  #----------------------------------------------------------#
  # 2. Check Python Configuration -----
  #----------------------------------------------------------#


  cat("2. Checking Python Configuration\n")
  cat("   ----------------------------------------\n")

  if (
    isFALSE(
      requireNamespace("reticulate", quietly = TRUE)
    )
  ) {
    cat("   [FAIL] reticulate package not installed\n")
    cat("   Fix: install.packages('reticulate')\n\n")
    return(invisible(results))
  }

  # Keep the error so its message can be shown (e.g. a missing
  #   RETICULATE_PYTHON target).
  py_conf <-
    tryCatch(
      expr = {
        reticulate::py_config()
      },
      error = function(e) e
    )

  if (
    isFALSE(base::inherits(py_conf, "error"))
  ) {
    results <-
      results |>
      purrr::list_modify(python_ok = TRUE)
    python_path <-
      py_conf |>
      purrr::chuck("python")
    python_version <-
      py_conf |>
      purrr::chuck("version")

    cat("   [OK] Python found\n")
    cat("   Version: ", as.character(python_version), "\n")
    cat("   Path: ", python_path, "\n")

    configured_python <- base::Sys.getenv("RETICULATE_PYTHON")

    if (
      in_radian
    ) {
      # radian replaces RETICULATE_PYTHON with its own Python at start-up.
      cat("   This is radian's own Python; .Renviron does not apply\n")
    } else if (
      base::nzchar(configured_python)
    ) {
      cat("   [OK] RETICULATE_PYTHON is configured\n")
    } else {
      cat("   [WARN] RETICULATE_PYTHON is not explicitly configured\n")
    }
  } else {
    cat("   [FAIL] Python configuration failed\n")
    cat("   Reason: ", base::conditionMessage(py_conf), "\n")
    cat("   Fix: check RETICULATE_PYTHON in the project .Renviron\n")
  }

  cat("\n")

  #----------------------------------------------------------#
  # 3. Check PyTorch Installation -----
  #----------------------------------------------------------#

  cat("3. Checking PyTorch Installation\n")
  cat("   ----------------------------------------\n")

  torch_results <-
    diagnose_sjsdm_gpu_runtime(verbose = FALSE)

  if (
    torch_results |>
      purrr::chuck("torch_available") |>
      isTRUE()
  ) {
    results <-
      results |>
      purrr::list_modify(pytorch_ok = TRUE)
    pytorch_version <-
      torch_results |>
      purrr::chuck("torch_version")

    cat("   [OK] PyTorch is installed\n")
    cat("   Version: ", pytorch_version, "\n")

    cuda_runtime_available <-
      torch_results |>
      purrr::chuck("cuda_runtime_available")
    results <-
      results |>
      purrr::list_modify(
        cuda_available = cuda_runtime_available
      )

    if (cuda_runtime_available) {
      cat("   [OK] CUDA available (GPU mode)\n")
      cuda_version <-
        torch_results |>
        purrr::chuck("cuda_version")
      gpu_device_names <-
        torch_results |>
        purrr::chuck("gpu_device_names")
      cat("   CUDA version: ", cuda_version, "\n")

      if (
        base::length(gpu_device_names) > 0L
      ) {
        cat(
          "   GPU: ",
          gpu_device_names |>
            purrr::chuck(1L),
          "\n"
        )
      }
    } else {
      cat("   [WARN] CUDA not available (CPU mode)\n")
      cat("   This is normal if you don't have NVIDIA GPU\n")
      cat("   sjSDM will work but slower for large datasets\n")
    }
  } else {
    cat("   [FAIL] PyTorch not found\n")

    if (
      in_radian
    ) {
      cat(
        "   radian runs on",
        torch_results |>
          purrr::chuck("python_path"),
        "which has no PyTorch\n"
      )
      cat("   Fix: start radian from the sjSDM Python environment\n")
      cat("   (r.consolePath in .vscode/settings.json)\n")
    } else {
      cat("   Fix: install PyTorch in the Python set by RETICULATE_PYTHON\n")
    }
  }

  # radian fails only when its own Python cannot provide PyTorch.
  results <-
    results |>
    purrr::list_modify(
      radian_ok = isFALSE(in_radian) ||
        results |>
          purrr::chuck("pytorch_ok")
    )

  cat("\n")

  #----------------------------------------------------------#
  # 4. Check sjSDM Package -----
  #----------------------------------------------------------#

  cat("4. Checking sjSDM Package\n")
  cat("   ----------------------------------------\n")

  sjsdm_installed <-
    requireNamespace("sjSDM", quietly = TRUE)

  if (sjsdm_installed) {
    cat("   [OK] sjSDM package is installed\n")

    # Try to load sjSDM
    sjsdm_loaded <-
      tryCatch(
        expr = {
          base::getExportedValue("sjSDM", "sjSDM")
          TRUE
        },
        error = function(e) FALSE,
        warning = function(w) {
          cat("   [WARN] Warning: ", conditionMessage(w), "\n")
          TRUE
        }
      )

    if (sjsdm_loaded) {
      results <-
        results |>
        purrr::list_modify(sjsdm_ok = TRUE)
      cat("   [OK] sjSDM loaded successfully\n")
      cat("   All Python dependencies available\n")
    } else {
      cat("   [FAIL] sjSDM failed to load\n")
      cat("\n   Fix: reinstall the Python dependencies as described in\n")
      cat("   Documentation/Materials/sjSDM_installation_guide.md\n")
    }
  } else {
    cat("   [FAIL] sjSDM package not installed\n")
    cat("\n   Fix: install.packages('sjSDM')\n")
  }

  cat("\n")

  #----------------------------------------------------------#
  # 5. Run Test Model -----
  #----------------------------------------------------------#

  if (
    run_test_model &&
      results |>
        purrr::chuck("sjsdm_ok")
  ) {
    cat("5. Running Test Model\n")
    cat("   ----------------------------------------\n")

    test_result <-
      tryCatch(
        expr = {
          set.seed(900723)
          community <-
            sjSDM::simulate_SDM(
              sites = 50,
              species = 5,
              env = 3
            )

          model <-
            sjSDM::sjSDM(
              Y =
                community |>
                purrr::chuck("response"),
              env = sjSDM::linear(
                data =
                  community |>
                  purrr::chuck("env_weights"),
                formula = ~ X1 + X2 + X3
              ),
              verbose = FALSE
            )

          cat("   [OK] Test model fitted successfully\n")
          model_log_likelihood <-
            model |>
            purrr::chuck("logLik") |>
            purrr::chuck(1L)
          cat("   LogLik: ", model_log_likelihood, "\n")

          TRUE
        },
        error = function(e) {
          cat("   [FAIL] Test model failed\n")
          cat("   Error: ", conditionMessage(e), "\n")
          FALSE
        }
      )

    if (isTRUE(test_result)) {
      results <-
        results |>
        purrr::list_modify(test_model_ok = TRUE)
    }
  }

  #----------------------------------------------------------#
  # 6. Summary -----
  #----------------------------------------------------------#

  python_ok <-
    results |>
    purrr::chuck("python_ok")
  pytorch_ok <-
    results |>
    purrr::chuck("pytorch_ok")
  sjsdm_ok <-
    results |>
    purrr::chuck("sjsdm_ok")
  radian_ok <-
    results |>
    purrr::chuck("radian_ok")
  all_critical_ok <-
    python_ok && pytorch_ok && sjsdm_ok

  # radian_ok is not part of the critical check: a radian without PyTorch
  #   already fails pytorch_ok; radian_ok only names the cause.

  if (!all_critical_ok) {
    cat("[FAIL] Some critical checks failed\n\n")
    cat("Issues found:\n")

    if (
      isFALSE(python_ok)
    ) {
      cat("  - Python configuration issue\n")
    }

    if (
      isFALSE(pytorch_ok)
    ) {
      cat("  - PyTorch not available\n")
    }

    if (
      isFALSE(radian_ok)
    ) {
      cat("  - radian runs on a Python without PyTorch\n")
    }

    if (
      isFALSE(sjsdm_ok)
    ) {
      cat("  - sjSDM not working\n")
    }

    cat("\nRefer to the detailed checks above for solutions.\n")
    cat("See: Documentation/Materials/sjSDM_installation_guide.md\n")
  }

  cat("\n=============================================================\n")

  return(
    invisible(results)
  )
}
