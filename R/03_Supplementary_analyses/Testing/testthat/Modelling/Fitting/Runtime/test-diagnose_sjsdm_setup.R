testthat::test_that(
  "diagnose_sjsdm_setup() is non-aborting and preserves result names",
  {
    testthat::expect_no_error(
      result <-
        base::withVisible(
          diagnose_sjsdm_setup(run_test_model = FALSE)
        )
    )

    testthat::expect_false(
      result |>
        purrr::chuck("visible")
    )
    testthat::expect_named(
      result |>
        purrr::chuck("value"),
      base::c(
        "radian_ok",
        "python_ok",
        "pytorch_ok",
        "cuda_available",
        "sjsdm_ok",
        "test_model_ok"
      )
    )
  }
)

testthat::test_that(
  "diagnose_sjsdm_setup() contains no machine-specific setup paths",
  {
    body_text <-
      base::deparse(base::body(diagnose_sjsdm_setup)) |>
      stringr::str_c(collapse = "\n")

    testthat::expect_false(
      base::grepl("C:\\\\Users\\\\ondre", body_text)
    )
    testthat::expect_false(
      base::grepl("where radian", body_text, fixed = TRUE)
    )
  }
)

testthat::test_that(
  "diagnose_sjsdm_setup() does not recommend install_sjSDM()",
  {
    body_text <-
      base::deparse(base::body(diagnose_sjsdm_setup)) |>
      stringr::str_c(collapse = "\n")

    testthat::expect_false(
      base::grepl("install_sjSDM", body_text, fixed = TRUE)
    )
  }
)

testthat::test_that(
  "diagnose_sjsdm_setup() ignores radian on PATH outside radian",
  {
    withr::local_envvar(
      RADIAN_VERSION = NA,
      RSTUDIO = NA,
      PATH = ""
    )

    testthat::expect_output(
      res <-
        diagnose_sjsdm_setup(run_test_model = FALSE),
      regexp = "plain R"
    )

    testthat::expect_true(
      res |>
        purrr::chuck("radian_ok")
    )
  }
)

testthat::test_that(
  "diagnose_sjsdm_setup() flags radian whose Python lacks PyTorch",
  {
    withr::local_envvar(
      RADIAN_VERSION = "0.8.0",
      RSTUDIO = NA
    )

    testthat::local_mocked_bindings(
      py_config = function(...) {
        base::list(
          python = "C:/host/python.exe",
          version = "3.12"
        )
      },
      import = function(...) {
        base::stop("No module named 'torch'")
      },
      .package = "reticulate"
    )

    output_text <-
      utils::capture.output(
        res <-
          diagnose_sjsdm_setup(run_test_model = FALSE)
      ) |>
      stringr::str_c(collapse = "\n")

    testthat::expect_false(
      res |>
        purrr::chuck("radian_ok")
    )
    testthat::expect_false(
      res |>
        purrr::chuck("pytorch_ok")
    )
    testthat::expect_match(output_text, "C:/host/python.exe", fixed = TRUE)
    testthat::expect_match(output_text, "r.consolePath", fixed = TRUE)
    testthat::expect_no_match(output_text, "Radian is available")
  }
)

testthat::test_that(
  "diagnose_sjsdm_setup() accepts radian whose Python has PyTorch",
  {
    testthat::skip_if_not(
      reticulate::py_module_available("torch")
    )

    withr::local_envvar(
      RADIAN_VERSION = "0.8.0",
      RSTUDIO = NA,
      PATH = ""
    )

    testthat::expect_output(
      res <-
        diagnose_sjsdm_setup(run_test_model = FALSE),
      regexp = "Running in radian"
    )

    testthat::expect_true(
      res |>
        purrr::chuck("radian_ok")
    )
  }
)

testthat::test_that(
  "diagnose_sjsdm_setup() prints why no Python could be configured",
  {
    testthat::local_mocked_bindings(
      py_config = function(...) {
        base::stop(
          "Python specified in RETICULATE_PYTHON (C:/x.exe) does not exist"
        )
      },
      .package = "reticulate"
    )

    testthat::expect_output(
      res <-
        diagnose_sjsdm_setup(run_test_model = FALSE),
      regexp = "does not exist"
    )

    testthat::expect_false(
      res |>
        purrr::chuck("python_ok")
    )
  }
)
