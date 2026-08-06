#' @title Diagnose the sjSDM Setup
#'
#' @description
#' Comprehensive non-aborting diagnosis of the sjSDM installation, including
#' Python, PyTorch, CUDA support, and sjSDM functionality.
#'
#' @param run_test_model Logical. Should a test model be fitted to
#' diagnose full functionality? Defaults to `interactive()`.
#'
#' @return Invisible list with diagnostic results. Called primarily for
#' side effects.
#'
#' @details
#' This function performs the following checks:
#' 1. Interactive runtime availability
#' 2. Python version and location
#' 3. PyTorch installation and version
#' 4. CUDA/GPU availability
#' 5. sjSDM package installation
#' 6. sjSDM Python dependencies
#' 7. Test model fitting (optional)
#'
#' All checks print their status with [OK], [WARN], or [FAIL]. Failures are
#' represented in the returned list rather than raised as errors.
#'
#' @seealso
#' \code{\link[reticulate]{py_config}}
#' \code{\link[sjSDM]{sjSDM}}
#'
#' @export
diagnose_sjsdm_setup <- function(run_test_model = base::interactive()) {
  # Detect runtime environment
  in_rstudio <- base::Sys.getenv("RSTUDIO") == "1"
  radian_path <- base::Sys.which("radian")

  # Initialize results list
  results <-
    base::list(
      radian_ok = in_rstudio || base::nzchar(radian_path),
      python_ok = FALSE,
      pytorch_ok = FALSE,
      cuda_available = FALSE,
      sjsdm_ok = FALSE,
      test_model_ok = FALSE
    )


  cat("=============================================================\n")
  cat("           sjSDM Setup Diagnostics\n")

  if (in_rstudio) {
    cat("           Running in: RStudio\n")
  } else {
    cat("           Running in: standard R session\n")
  }

  cat("=============================================================\n")



  #----------------------------------------------------------#
  # 1. Diagnose interactive runtime -----
  #----------------------------------------------------------#

  cat("1. Diagnosing Interactive Runtime\n")
  cat("   ----------------------------------------\n")

  if (in_rstudio) {
    cat("   [OK] Running in RStudio\n")
  } else if (base::nzchar(radian_path)) {
    cat("   [OK] Radian is available\n")
    cat("   Path: ", radian_path, "\n")
  } else {
    cat("   [WARN] Radian is not available on PATH\n")
    cat("   This does not prevent sjSDM from running in R\n")
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

  py_conf <-
    tryCatch(
      expr = {
        reticulate::py_config()
      },
      error = function(e) NULL
    )

  if (
    isFALSE(is.null(py_conf))
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

    if (base::nzchar(configured_python)) {
      cat("   [OK] RETICULATE_PYTHON is configured\n")
    } else {
      cat("   [WARN] RETICULATE_PYTHON is not explicitly configured\n")
    }
  } else {
    cat("   [FAIL] Python configuration failed\n")
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
    cat("\n   Install PyTorch in the active Python environment\n")
  }

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
      cat("\n   Fix: Reinstall sjSDM dependencies\n")
      cat("   sjSDM::install_sjSDM()\n")
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
  all_critical_ok <-
    python_ok && pytorch_ok && sjsdm_ok

  # In RStudio, radian_ok reflects RETICULATE_PYTHON configuration;
  # it is informational and doesn't block the critical check.

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
