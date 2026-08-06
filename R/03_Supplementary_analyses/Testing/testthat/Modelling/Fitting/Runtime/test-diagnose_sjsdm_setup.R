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
