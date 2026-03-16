data_test_anova <-
  tibble::tibble(
    age = c(0, 500, 1000, 0, 500, 1000),
    component = c(
      "Abiotic", "Abiotic", "Abiotic",
      "Spatial", "Spatial", "Spatial"
    ),
    R2_Nagelkerke_percentage = c(0.1, 0.15, 0.2, 0.3, 0.25, 0.2)
  )

testthat::test_that(
  "plot_anova_components_by_age() rejects non-data-frame input",
  {
    testthat::expect_error(
      plot_anova_components_by_age(
        data_anova_components = NULL
      ),
      "'data_anova_components' must be a data frame."
    )

    testthat::expect_error(
      plot_anova_components_by_age(
        data_anova_components = base::list(a = 1)
      ),
      "'data_anova_components' must be a data frame."
    )

    testthat::expect_error(
      plot_anova_components_by_age(
        data_anova_components = "a string"
      ),
      "'data_anova_components' must be a data frame."
    )
  }
)

testthat::test_that(
  "plot_anova_components_by_age() rejects df with missing columns",
  {
    data_no_age <-
      tibble::tibble(
        component = c("Abiotic"),
        R2_Nagelkerke_percentage = c(0.1)
      )

    testthat::expect_error(
      plot_anova_components_by_age(
        data_anova_components = data_no_age
      )
    )

    data_no_component <-
      tibble::tibble(
        age = c(0L),
        R2_Nagelkerke_percentage = c(0.1)
      )

    testthat::expect_error(
      plot_anova_components_by_age(
        data_anova_components = data_no_component
      )
    )

    data_no_r2 <-
      tibble::tibble(
        age = c(0L),
        component = c("Abiotic")
      )

    testthat::expect_error(
      plot_anova_components_by_age(
        data_anova_components = data_no_r2
      )
    )
  }
)

testthat::test_that(
  "plot_anova_components_by_age() returns a ggplot object",
  {
    plot_res <-
      plot_anova_components_by_age(
        data_anova_components = data_test_anova
      )

    testthat::expect_s3_class(plot_res, "gg")
    testthat::expect_s3_class(plot_res, "ggplot")
  }
)

testthat::test_that(
  "plot_anova_components_by_age() uses NULL titles by default",
  {
    plot_res <-
      plot_anova_components_by_age(
        data_anova_components = data_test_anova
      )

    title_val <-
      purrr::pluck(plot_res, "labels", "title")

    subtitle_val <-
      purrr::pluck(plot_res, "labels", "subtitle")

    testthat::expect_null(title_val)
    testthat::expect_null(subtitle_val)
  }
)

testthat::test_that(
  "plot_anova_components_by_age() sets custom title and subtitle",
  {
    plot_res <-
      plot_anova_components_by_age(
        data_anova_components = data_test_anova,
        title = "My title",
        subtitle = "My sub"
      )

    title_val <-
      purrr::pluck(plot_res, "labels", "title")

    subtitle_val <-
      purrr::pluck(plot_res, "labels", "subtitle")

    testthat::expect_equal(title_val, "My title")
    testthat::expect_equal(subtitle_val, "My sub")
  }
)

testthat::test_that(
  "plot_anova_components_by_age() maps correct aesthetics",
  {
    plot_res <-
      plot_anova_components_by_age(
        data_anova_components = data_test_anova
      )

    mapping_obj <-
      purrr::pluck(plot_res, "mapping")

    testthat::expect_equal(
      rlang::quo_name(purrr::pluck(mapping_obj, "x")),
      "age"
    )

    testthat::expect_equal(
      rlang::quo_name(purrr::pluck(mapping_obj, "y")),
      "R2_Nagelkerke_percentage"
    )

    testthat::expect_equal(
      rlang::quo_name(purrr::pluck(mapping_obj, "colour")),
      "component"
    )

    testthat::expect_equal(
      rlang::quo_name(purrr::pluck(mapping_obj, "group")),
      "component"
    )
  }
)
