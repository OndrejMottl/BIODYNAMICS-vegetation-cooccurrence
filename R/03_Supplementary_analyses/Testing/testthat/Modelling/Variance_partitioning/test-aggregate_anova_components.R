make_mock_anova_obj <- function(
    r2_values = c(
      0.10, 0.20, 0.30, 0.05, 0.05, 0.05, 0.25
    )) {
  obj <-
    base::list(
      results = tibble::tibble(
        models = c(
          "F_A", "F_B", "F_S",
          "F_AB", "F_AS", "F_BS", "F_ABS"
        ),
        `R2 Nagelkerke` = r2_values
      )
    )
  base::class(obj) <- "sjSDManova"
  return(obj)
}

testthat::test_that(
  "aggregate_anova_components() rejects non-list inputs",
  {
    testthat::expect_error(
      aggregate_anova_components(list_model_anova = NULL),
      "'list_model_anova' must be a list."
    )

    testthat::expect_error(
      aggregate_anova_components(
        list_model_anova = "a string"
      ),
      "'list_model_anova' must be a list."
    )

    testthat::expect_error(
      aggregate_anova_components(list_model_anova = 42),
      "'list_model_anova' must be a list."
    )
  }
)

testthat::test_that(
  "aggregate_anova_components() returns data frame with cols",
  {
    list_input <-
      base::list(
        timeslice_500 = make_mock_anova_obj()
      )

    res <-
      aggregate_anova_components(
        list_model_anova = list_input
      )

    testthat::expect_s3_class(res, "data.frame")
    testthat::expect_true(
      base::all(
        c("age", "component", "R2_Nagelkerke") %in%
          base::names(res)
      )
    )
  }
)

testthat::test_that(
  "aggregate_anova_components() returns 7 rows per slice",
  {
    list_input <-
      base::list(
        timeslice_500 = make_mock_anova_obj()
      )

    res <-
      aggregate_anova_components(
        list_model_anova = list_input
      )

    testthat::expect_equal(base::nrow(res), 7L)
  }
)

testthat::test_that(
  "aggregate_anova_components() parses age from slice name",
  {
    list_input <-
      base::list(
        timeslice_500 = make_mock_anova_obj()
      )

    res <-
      aggregate_anova_components(
        list_model_anova = list_input
      )

    vec_ages <-
      dplyr::pull(res, age) |>
      base::unique()

    testthat::expect_equal(vec_ages, 500)
  }
)

testthat::test_that(
  "aggregate_anova_components() aggregates multiple slices",
  {
    list_input <-
      base::list(
        timeslice_500 = make_mock_anova_obj(),
        timeslice_1000 = make_mock_anova_obj()
      )

    res <-
      aggregate_anova_components(
        list_model_anova = list_input
      )

    vec_ages <-
      dplyr::pull(res, age) |>
      base::unique() |>
      base::sort()

    testthat::expect_equal(base::nrow(res), 14L)
    testthat::expect_equal(vec_ages, c(500, 1000))
  }
)

testthat::test_that(
  "aggregate_anova_components() translates codes to labels",
  {
    list_input <-
      base::list(
        timeslice_500 = make_mock_anova_obj()
      )

    res <-
      aggregate_anova_components(
        list_model_anova = list_input
      )

    vec_components <-
      dplyr::pull(res, component)

    vec_raw_codes <-
      c(
        "F_A", "F_B", "F_S",
        "F_AB", "F_AS", "F_BS", "F_ABS"
      )

    testthat::expect_false(
      base::any(vec_raw_codes %in% vec_components)
    )
  }
)

testthat::test_that(
  "aggregate_anova_components() clamps negative R2 to zero",
  {
    vec_r2_neg <-
      c(-0.05, 0.20, 0.30, 0.05, -0.10, 0.05, 0.25)

    list_input <-
      base::list(
        timeslice_500 = make_mock_anova_obj(
          r2_values = vec_r2_neg
        )
      )

    res <-
      aggregate_anova_components(
        list_model_anova = list_input
      )

    vec_r2 <-
      dplyr::pull(res, R2_Nagelkerke)

    testthat::expect_true(base::all(vec_r2 >= 0))
  }
)

testthat::test_that(
  "aggregate_anova_components() silently drops NULL entries",
  {
    list_input <-
      base::list(
        timeslice_500 = make_mock_anova_obj(),
        timeslice_1000 = NULL
      )

    res <-
      aggregate_anova_components(
        list_model_anova = list_input
      )

    testthat::expect_equal(base::nrow(res), 7L)
  }
)

testthat::test_that(
  "aggregate_anova_components() drops entries without results",
  {
    list_no_results <-
      base::list(other_element = 1L)

    list_input <-
      base::list(
        timeslice_500 = make_mock_anova_obj(),
        timeslice_1000 = list_no_results
      )

    res <-
      aggregate_anova_components(
        list_model_anova = list_input
      )

    testthat::expect_equal(base::nrow(res), 7L)
  }
)

testthat::test_that(
  "aggregate_anova_components() returns empty tibble for empty list",
  {
    res <-
      aggregate_anova_components(
        list_model_anova = base::list()
      )

    testthat::expect_s3_class(res, "data.frame")
    testthat::expect_equal(base::nrow(res), 0L)
  }
)
