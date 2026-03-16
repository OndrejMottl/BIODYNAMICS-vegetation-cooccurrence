data_valid_two_ages <-
  tibble::tibble(
    age = c(0, 0, 500, 500),
    component = c("Abiotic", "Spatial", "Abiotic", "Spatial"),
    R2_Nagelkerke = c(0.3, 0.1, 0.2, 0.4)
  )

#----------------------------------------------------------#
# Input validation -----
#----------------------------------------------------------#

testthat::test_that(
  "recalculate_anova_components() rejects non-data-frame",
  {
    testthat::expect_error(
      recalculate_anova_components(data_source = NULL)
    )

    testthat::expect_error(
      recalculate_anova_components(
        data_source = base::list(age = 1, R2_Nagelkerke = 1)
      )
    )

    testthat::expect_error(
      recalculate_anova_components(data_source = "string")
    )

    testthat::expect_error(
      recalculate_anova_components(data_source = 42)
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() rejects empty data frame",
  {
    data_empty <-
      tibble::tibble(
        age = base::numeric(0),
        R2_Nagelkerke = base::numeric(0)
      )

    testthat::expect_error(
      recalculate_anova_components(data_source = data_empty)
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() rejects missing columns",
  {
    data_no_age <-
      tibble::tibble(
        component = c("Abiotic"),
        R2_Nagelkerke = c(0.1)
      )

    testthat::expect_error(
      recalculate_anova_components(data_source = data_no_age)
    )

    data_no_r2 <-
      tibble::tibble(
        age = c(0L),
        component = c("Abiotic")
      )

    testthat::expect_error(
      recalculate_anova_components(data_source = data_no_r2)
    )
  }
)

#----------------------------------------------------------#
# Output structure -----
#----------------------------------------------------------#

testthat::test_that(
  "recalculate_anova_components() returns a data frame",
  {
    res <-
      recalculate_anova_components(data_source = data_valid_two_ages)

    testthat::expect_true(
      base::is.data.frame(res)
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() preserves row count",
  {
    res <-
      recalculate_anova_components(data_source = data_valid_two_ages)

    testthat::expect_equal(
      base::nrow(res),
      base::nrow(data_valid_two_ages)
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() adds percentage column",
  {
    res <-
      recalculate_anova_components(data_source = data_valid_two_ages)

    testthat::expect_true(
      "R2_Nagelkerke_percentage" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() preserves original columns",
  {
    res <-
      recalculate_anova_components(data_source = data_valid_two_ages)

    vec_original_cols <-
      base::colnames(data_valid_two_ages)

    testthat::expect_true(
      base::all(vec_original_cols %in% base::colnames(res))
    )
  }
)

#----------------------------------------------------------#
# Functional correctness -----
#----------------------------------------------------------#

testthat::test_that(
  "recalculate_anova_components() percentages sum to 100 per age",
  {
    res <-
      recalculate_anova_components(data_source = data_valid_two_ages)

    vec_sums <-
      res |>
      dplyr::group_by(age) |>
      dplyr::summarise(
        total = base::sum(R2_Nagelkerke_percentage),
        .groups = "drop"
      ) |>
      dplyr::pull(total)

    testthat::expect_true(
      base::all(base::abs(vec_sums - 100) < 1e-8)
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() computes correct percentages",
  {
    data_simple <-
      tibble::tibble(
        age = c(0, 0),
        R2_Nagelkerke = c(0.3, 0.1)
      )

    res <-
      recalculate_anova_components(data_source = data_simple)

    vec_pct <-
      dplyr::pull(res, R2_Nagelkerke_percentage)

    # 0.3 / 0.4 * 100 = 75, 0.1 / 0.4 * 100 = 25
    testthat::expect_equal(
      vec_pct,
      c(75, 25),
      tolerance = 1e-8
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() single row per age gives 100%",
  {
    data_single_per_age <-
      tibble::tibble(
        age = c(0, 500),
        R2_Nagelkerke = c(0.4, 0.6)
      )

    res <-
      recalculate_anova_components(data_source = data_single_per_age)

    vec_pct <-
      dplyr::pull(res, R2_Nagelkerke_percentage)

    testthat::expect_equal(
      vec_pct,
      c(100, 100),
      tolerance = 1e-8
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() equal R2 values split evenly",
  {
    data_equal <-
      tibble::tibble(
        age = c(0, 0, 0),
        R2_Nagelkerke = c(0.2, 0.2, 0.2)
      )

    res <-
      recalculate_anova_components(data_source = data_equal)

    vec_pct <-
      dplyr::pull(res, R2_Nagelkerke_percentage)

    testthat::expect_equal(
      vec_pct,
      base::rep(100 / 3, 3),
      tolerance = 1e-8
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() ages computed independently",
  {
    data_two_ages <-
      tibble::tibble(
        age = c(0, 0, 1000, 1000),
        R2_Nagelkerke = c(0.6, 0.4, 0.1, 0.9)
      )

    res <-
      recalculate_anova_components(data_source = data_two_ages)

    # age = 0: 60%, 40%; age = 1000: 10%, 90%
    vec_pct_age0 <-
      res |>
      dplyr::filter(age == 0) |>
      dplyr::pull(R2_Nagelkerke_percentage)

    vec_pct_age1000 <-
      res |>
      dplyr::filter(age == 1000) |>
      dplyr::pull(R2_Nagelkerke_percentage)

    testthat::expect_equal(
      vec_pct_age0,
      c(60, 40),
      tolerance = 1e-8
    )

    testthat::expect_equal(
      vec_pct_age1000,
      c(10, 90),
      tolerance = 1e-8
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() preserves extra columns",
  {
    data_extra_col <-
      tibble::tibble(
        age = c(0, 0),
        component = c("A", "B"),
        R2_Nagelkerke = c(0.5, 0.5),
        other = c("x", "y")
      )

    res <-
      recalculate_anova_components(data_source = data_extra_col)

    testthat::expect_true("other" %in% base::colnames(res))

    testthat::expect_equal(
      dplyr::pull(res, other),
      c("x", "y")
    )
  }
)
