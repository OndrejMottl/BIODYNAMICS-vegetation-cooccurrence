#' @title Verify sjSDM Setup
#'
#' @description
#' Comprehensive verifimessageion of sjSDM installation, including Python
#' environment, PyTorch, CUDA support, and sjSDM functionality.
#' This function checks that Radian and sjSDM are using the same
#' Python environment and that all dependencies are properly installed.
#'
#' @param run_test_model Logical. Should a test model be fitted to
#' verify full functionality? Default is TRUE.
#'
#' @return Invisible list with verification results. Called primarily
#' for side effects (printing verification status).
#'
#' @details
#' This function performs the following checks:
#' 1. Radian configuration (correct Python environment)
#' 2. Python version and lomessageion
#' 3. PyTorch installation and version
#' 4. CUDA/GPU availability
#' 5. sjSDM package installation
#' 6. sjSDM Python dependencies
#' 7. Test model fitting (optional)
#'
#' All checks print their status with [OK] (success) or [FAIL] (failure).
#' If any critical check fails, the function provides troubleshooting
#' guidance.
#'
#' @seealso
#' \code{\link[reticulate]{py_config}}
#' \code{\link[sjSDM]{sjSDM}}
#'
#' @export
verify_sjsdm_setup <- function(run_test_model = interactive()) {
  # Detect runtime environment
  in_rstudio <- Sys.getenv("RSTUDIO") == "1"

  # Initialize results list
  results <-
    list(
      radian_ok = FALSE,
      python_ok = FALSE,
      pytorch_ok = FALSE,
      cuda_available = FALSE,
      sjsdm_ok = FALSE,
      test_model_ok = FALSE
    )


  cat("=============================================================\n")
  cat("           sjSDM Setup Verification\n")

  if (in_rstudio) {
    cat("           Running in: RStudio\n")
  } else {
    cat("           Running in: VS Code / Radian\n")
  }

  cat("=============================================================\n")



  #----------------------------------------------------------#
  # 1. Check Radian / Python environment configuration -----
  #----------------------------------------------------------#

  if (in_rstudio) {
    cat("1. Checking RStudio Python Configuration\n")
    cat("   ----------------------------------------\n")

    reticulate_python <- Sys.getenv("RETICULATE_PYTHON")

    if (
      nchar(reticulate_python) > 0 &&
        grepl("r-sjsdm", reticulate_python, ignore.case = TRUE)
    ) {
      results$radian_ok <- TRUE
      cat("   [OK] RETICULATE_PYTHON points to r-sjsdm environment\n")
      cat("   Path: ", reticulate_python, "\n")
    } else if (nchar(reticulate_python) > 0) {
      cat("   [WARN] RETICULATE_PYTHON is set but not pointing to r-sjsdm\n")
      cat("   Current: ", reticulate_python, "\n")
      cat("   Fix: Set RETICULATE_PYTHON in project .Renviron:\n")
      cat("   RETICULATE_PYTHON=C:/Users/ondre/AppData/Local/r-miniconda/envs/r-sjsdm/python.exe\n")
    } else {
      cat("   [WARN] RETICULATE_PYTHON not set in .Renviron\n")
      cat("   sjSDM may not find PyTorch\n")
      cat("   Fix: Add to project .Renviron file:\n")
      cat("   RETICULATE_PYTHON=C:/Users/ondre/AppData/Local/r-miniconda/envs/r-sjsdm/python.exe\n")
      cat("   Then restart R\n")
    }
  } else {
    cat("1. Checking Radian Configuration\n")
    cat("   ----------------------------------------\n")

    radian_path <-
      tryCatch(
        expr = {
          system("where radian", intern = TRUE)[1]
        },
        error = function(e) NA
      )

    expected_path <-
      "C:\\Users\\ondre\\AppData\\Local\\r-miniconda\\envs\\r-sjsdm\\Scripts\\radian.exe"

    if (
      isFALSE(is.na(radian_path)) &&
        grepl("r-sjsdm", radian_path, ignore.case = TRUE)
    ) {
      results$radian_ok <- TRUE
      cat("   [OK] Radian is from r-sjsdm environment\n")
      cat("   Path: ", radian_path, "\n")
    } else {
      cat("   [FAIL] Radian not from r-sjsdm environment\n")
      cat("   Current: ", radian_path, "\n")
      cat("   Expected: ", expected_path, "\n")
      cat("\n   Fix: Update VS Code settings:\n")
      cat('   "r.rterm.windows": "', expected_path, '"\n', sep = "")
    }
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
    results$python_ok <- TRUE
    python_path <- py_conf$python
    python_version <- py_conf$version

    cat("   [OK] Python found\n")
    cat("   Version: ", as.character(python_version), "\n")
    cat("   Path: ", python_path, "\n")

    if (
      grepl("r-sjsdm", python_path, ignore.case = TRUE)
    ) {
      cat("   [OK] Using r-sjsdm environment\n")
    } else {
      cat("   [WARN] Warning: Not using r-sjsdm environment\n")
      cat("   This may cause issues\n")
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

  torch <-
    tryCatch(
      expr = {
        reticulate::import("torch")
      },
      error = function(e) NULL
    )

  if (
    isFALSE(is.null(torch))
  ) {
    results$pytorch_ok <- TRUE
    pytorch_version <- torch$`__version__`

    cat("   [OK] PyTorch is installed\n")
    cat("   Version: ", pytorch_version, "\n")

    # Check CUDA
    cuda_available <-
      tryCatch(
        expr = {
          torch$cuda$is_available()
        },
        error = function(e) FALSE
      )

    results$cuda_available <- cuda_available

    if (cuda_available) {
      cat("   [OK] CUDA available (GPU mode)\n")
      cat("   CUDA version: ", torch$version$cuda, "\n")

      device_name <-
        tryCatch(
          expr = {
            torch$cuda$get_device_name(0L)
          },
          error = function(e) "Unknown"
        )
      cat("   GPU: ", device_name, "\n")
    } else {
      cat("   [WARN] CUDA not available (CPU mode)\n")
      cat("   This is normal if you don't have NVIDIA GPU\n")
      cat("   sjSDM will work but slower for large datasets\n")
    }
  } else {
    cat("   [FAIL] PyTorch not found\n")
    cat("\n   Fix: Reinstall PyTorch in r-sjsdm environment\n")
    cat("   Run in PowerShell:\n")
    cat('   & "C:\\Users\\ondre\\AppData\\Local\\r-miniconda\\Scripts\\conda.exe" run -n r-sjsdm pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121\n')
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
          library(sjSDM)
          TRUE
        },
        error = function(e) FALSE,
        warning = function(w) {
          cat("   [WARN] Warning: ", conditionMessage(w), "\n")
          TRUE
        }
      )

    if (sjsdm_loaded) {
      results$sjsdm_ok <- TRUE
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
      results$sjsdm_ok
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
              Y = community$response,
              env = sjSDM::linear(
                data = community$env_weights,
                formula = ~ X1 + X2 + X3
              ),
              verbose = FALSE
            )

          cat("   [OK] Test model fitted successfully\n")
          cat("   LogLik: ", model$logLik[[1]], "\n")

          results$test_model_ok <- TRUE
          TRUE
        },
        error = function(e) {
          cat("   [FAIL] Test model failed\n")
          cat("   Error: ", conditionMessage(e), "\n")
          FALSE
        }
      )
  }

  #----------------------------------------------------------#
  # 6. Summary -----
  #----------------------------------------------------------#

  all_critical_ok <-
    results$python_ok &&
      results$pytorch_ok &&
      results$sjsdm_ok

  # In RStudio, radian_ok reflects RETICULATE_PYTHON configuration;
  # it is informational and doesn't block the critical check.

  if (!all_critical_ok) {
    cat("[FAIL] Some critical checks failed\n\n")
    cat("Issues found:\n")

    if (
      isFALSE(results$python_ok)
    ) {
      cat("  - Python configuration issue\n")
    }

    if (
      isFALSE(results$pytorch_ok)
    ) {
      cat("  - PyTorch not available\n")
    }

    if (
      isFALSE(results$sjsdm_ok)
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
