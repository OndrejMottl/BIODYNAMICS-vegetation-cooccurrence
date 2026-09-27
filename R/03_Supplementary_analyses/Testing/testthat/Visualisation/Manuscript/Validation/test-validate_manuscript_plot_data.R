testthat::test_that(
  "validate_manuscript_plot_data() accepts bounded missing values",
  {
    data_plot <-
      tibble::tibble(
        unit_id = base::c("a", "b"),
        estimate = base::c(25, NA_real_)
      )

    testthat::expect_invisible(
      validate_manuscript_plot_data(
        data_plot = data_plot,
        required_columns = base::c("unit_id", "estimate"),
        numeric_bounds = base::list(
          estimate = base::c(0, 100)
        )
      )
    )
  }
)

testthat::test_that(
  "validate_manuscript_plot_data() rejects incomplete data",
  {
    testthat::expect_error(
      validate_manuscript_plot_data(
        data_plot = tibble::tibble(unit_id = "a"),
        required_columns = base::c("unit_id", "estimate")
      ),
      "Missing"
    )
    testthat::expect_error(
      validate_manuscript_plot_data(
        data_plot = tibble::tibble(estimate = 101),
        required_columns = "estimate",
        numeric_bounds = base::list(
          estimate = base::c(0, 100)
        )
      ),
      "bounds"
    )
    testthat::expect_error(
      validate_manuscript_plot_data(
        data_plot = tibble::tibble(estimate = base::numeric()),
        required_columns = "estimate"
      ),
      "at least one row"
    )
  }
)
