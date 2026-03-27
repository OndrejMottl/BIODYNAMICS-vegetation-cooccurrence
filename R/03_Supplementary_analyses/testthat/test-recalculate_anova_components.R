#----------------------------------------------------------#
# Shared fixtures -----
#----------------------------------------------------------#

# Three unique components only — Shapley allocation reduces
#   to the raw values when no intersection terms are present.
data_three_unique <-
  tibble::tibble(
    age = c(0, 0, 0, 500, 500, 500),
    component = c(
      "Abiotic", "Associations", "Spatial",
      "Abiotic", "Associations", "Spatial"
    ),
    R2_Nagelkerke = c(0.3, 0.5, 0.2, 0.1, 0.6, 0.3)
  )

# All seven fractions — exercises Shapley allocation.
# F_A=0.3, F_B=0.4, F_S=0.2, F_AB=0.05, F_AS=0.02,
# F_BS=0.01, F_ABS=0.01; total = 0.99.
# Shapley adjusted values:
#   Abiotic:      0.3 + 0.05/2 + 0.02/2 + 0.01/3
#   Associations: 0.4 + 0.05/2 + 0.01/2 + 0.01/3
#   Spatial:      0.2 + 0.02/2 + 0.01/2 + 0.01/3
data_all_seven <-
  tibble::tibble(
    age = base::rep(0, 7),
    component = c(
      "Abiotic", "Associations", "Spatial",
      "Abiotic&Associations", "Abiotic&Spatial",
      "Associations&Spatial",
      "Abiotic&Associations&Spatial"
    ),
    R2_Nagelkerke = c(0.3, 0.4, 0.2, 0.05, 0.02, 0.01, 0.01)
  )

# All unique components are zero -> sum = 0 -> NA result.
data_zero_sum <-
  tibble::tibble(
    age = c(0, 0, 0),
    component = c("Abiotic", "Associations", "Spatial"),
    R2_Nagelkerke = c(0.0, 0.0, 0.0)
  )

# Negative unique + negative intersection -> clamped to 0,
#   leaving only Associations=0.5 and Spatial=0.2 positive.
data_with_negatives <-
  tibble::tibble(
    age = c(0, 0, 0, 0),
    component = c(
      "Abiotic", "Associations", "Spatial",
      "Abiotic&Spatial"
    ),
    R2_Nagelkerke = c(-0.1, 0.5, 0.2, -0.3)
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
        component = base::character(0),
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

    data_no_component <-
      tibble::tibble(
        age = c(0L),
        R2_Nagelkerke = c(0.1)
      )

    testthat::expect_error(
      recalculate_anova_components(data_source = data_no_component)
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
      recalculate_anova_components(data_source = data_three_unique)

    testthat::expect_true(
      base::is.data.frame(res)
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() adds percentage column",
  {
    res <-
      recalculate_anova_components(data_source = data_three_unique)

    testthat::expect_true(
      "R2_Nagelkerke_percentage" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() preserves age and component columns",
  {
    res <-
      recalculate_anova_components(data_source = data_three_unique)

    testthat::expect_true(
      base::all(
        c("age", "component") %in% base::colnames(res)
      )
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() adds R2_Nagelkerke_adjusted column",
  {
    res <-
      recalculate_anova_components(data_source = data_three_unique)

    testthat::expect_true(
      "R2_Nagelkerke_adjusted" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() returns 3 rows per age",
  {
    res <-
      recalculate_anova_components(data_source = data_three_unique)

    # data_three_unique has 2 ages, each with 3 unique components
    testthat::expect_equal(
      base::nrow(res),
      6L
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() drops intersection rows",
  {
    res <-
      recalculate_anova_components(data_source = data_all_seven)

    vec_components <-
      dplyr::pull(res, component)

    # Only the 3 unique components should remain
    testthat::expect_equal(
      base::length(vec_components),
      3L
    )

    testthat::expect_true(
      base::all(
        vec_components %in%
          c("Abiotic", "Associations", "Spatial")
      )
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
      recalculate_anova_components(data_source = data_three_unique)

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
    # Three unique components, no intersections: Shapley equals
    # the raw unique fractions.  Abiotic=0.3, Assoc=0.5,
    # Spatial=0.2 -> total=1.0 -> percentages 30, 50, 20.
    data_simple <-
      tibble::tibble(
        age = c(0, 0, 0),
        component = c("Abiotic", "Associations", "Spatial"),
        R2_Nagelkerke = c(0.3, 0.5, 0.2)
      )

    res <-
      recalculate_anova_components(data_source = data_simple)

    vec_pct <-
      dplyr::pull(res, R2_Nagelkerke_percentage)

    testthat::expect_equal(
      vec_pct,
      c(30, 50, 20),
      tolerance = 1e-8
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() single unique row gives 100%",
  {
    # One component per age; with Shapley (3 rows always) the
    # present component must reach 100% and others 0%.
    data_single_per_age <-
      tibble::tibble(
        age = c(0, 500),
        component = c("Abiotic", "Spatial"),
        R2_Nagelkerke = c(0.4, 0.6)
      )

    res <-
      recalculate_anova_components(data_source = data_single_per_age)

    # age = 0: Abiotic_adj = 0.4, others 0 -> Abiotic = 100%
    pct_abiotic_age0 <-
      res |>
      dplyr::filter(age == 0, component == "Abiotic") |>
      dplyr::pull(R2_Nagelkerke_percentage)

    # age = 500: Spatial_adj = 0.6, others 0 -> Spatial = 100%
    pct_spatial_age500 <-
      res |>
      dplyr::filter(age == 500, component == "Spatial") |>
      dplyr::pull(R2_Nagelkerke_percentage)

    testthat::expect_equal(
      pct_abiotic_age0,
      100,
      tolerance = 1e-8
    )

    testthat::expect_equal(
      pct_spatial_age500,
      100,
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
        component = c("Abiotic", "Associations", "Spatial"),
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
    # Two unique components per age; output has 3 rows per age.
    # Filter to the present components to verify independence.
    data_two_ages <-
      tibble::tibble(
        age = c(0, 0, 1000, 1000),
        component = c(
          "Abiotic", "Spatial",
          "Abiotic", "Spatial"
        ),
        R2_Nagelkerke = c(0.6, 0.4, 0.1, 0.9)
      )

    res <-
      recalculate_anova_components(data_source = data_two_ages)

    # age = 0: Abiotic_adj=0.6, Spatial_adj=0.4 -> 60%, 40%
    vec_pct_age0 <-
      res |>
      dplyr::filter(
        age == 0,
        component %in% c("Abiotic", "Spatial")
      ) |>
      dplyr::pull(R2_Nagelkerke_percentage)

    # age = 1000: Abiotic_adj=0.1, Spatial_adj=0.9 -> 10%, 90%
    vec_pct_age1000 <-
      res |>
      dplyr::filter(
        age == 1000,
        component %in% c("Abiotic", "Spatial")
      ) |>
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
  "recalculate_anova_components() Shapley adjusted values sum to total",
  {
    # data_all_seven total = sum of all 7 fractions = 0.99.
    # Shapley adjusted values must also sum to 0.99.
    res <-
      recalculate_anova_components(data_source = data_all_seven)

    vec_adj <-
      dplyr::pull(res, R2_Nagelkerke_adjusted)

    testthat::expect_equal(
      base::sum(vec_adj),
      0.99,
      tolerance = 1e-8
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() Shapley correctly allocates intersection terms",
  {
    # data_all_seven: F_A=0.3, F_B=0.4, F_S=0.2,
    #   F_AB=0.05, F_AS=0.02, F_BS=0.01, F_ABS=0.01
    # Abiotic_adj  = 0.3  + 0.05/2 + 0.02/2 + 0.01/3
    # Assoc_adj    = 0.4  + 0.05/2 + 0.01/2 + 0.01/3
    # Spatial_adj  = 0.2  + 0.02/2 + 0.01/2 + 0.01/3
    res <-
      recalculate_anova_components(data_source = data_all_seven)

    vec_adj <-
      dplyr::pull(res, R2_Nagelkerke_adjusted)

    vec_expected <-
      c(
        0.3  + 0.05 / 2 + 0.02 / 2 + 0.01 / 3,
        0.4  + 0.05 / 2 + 0.01 / 2 + 0.01 / 3,
        0.2  + 0.02 / 2 + 0.01 / 2 + 0.01 / 3
      )

    testthat::expect_equal(
      vec_adj,
      vec_expected,
      tolerance = 1e-8
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() clamps negatives before allocation",
  {
    # data_with_negatives: F_A=-0.1 -> 0, F_B=0.5, F_S=0.2,
    #   F_AS=-0.3 -> 0
    # Abiotic_adj = 0, Assoc_adj = 0.5, Spatial_adj = 0.2
    # total = 0.7
    res <-
      recalculate_anova_components(data_source = data_with_negatives)

    vec_adj <-
      dplyr::pull(res, R2_Nagelkerke_adjusted)

    testthat::expect_equal(
      vec_adj,
      c(0, 0.5, 0.2),
      tolerance = 1e-8
    )

    vec_pct <-
      dplyr::pull(res, R2_Nagelkerke_percentage)

    testthat::expect_equal(
      vec_pct,
      c(0, 0.5, 0.2) / 0.7 * 100,
      tolerance = 1e-6
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() large intersection does not inflate unique component",
  {
    # User scenario: F_A=0.1, F_B=0.2, F_S=0.1, F_AS=5.0.
    # Without Shapley, the unique denominator would be 0.4 and
    #   Associations would appear to be 50%.  With Shapley:
    # Abiotic_adj  = 0.1 + 5.0/2 = 2.6
    # Assoc_adj    = 0.2
    # Spatial_adj  = 0.1 + 5.0/2 = 2.6
    # total = 5.4 -> Assoc pct = 0.2/5.4*100 ≈ 3.70%
    data_large_intersection <-
      tibble::tibble(
        age = c(0, 0, 0, 0),
        component = c(
          "Abiotic", "Associations", "Spatial",
          "Abiotic&Spatial"
        ),
        R2_Nagelkerke = c(0.1, 0.2, 0.1, 5.0)
      )

    res <-
      recalculate_anova_components(
        data_source = data_large_intersection
      )

    vec_adj <-
      dplyr::pull(res, R2_Nagelkerke_adjusted)

    testthat::expect_equal(
      vec_adj,
      c(2.6, 0.2, 2.6),
      tolerance = 1e-8
    )

    pct_assoc <-
      res |>
      dplyr::filter(component == "Associations") |>
      dplyr::pull(R2_Nagelkerke_percentage)

    testthat::expect_equal(
      pct_assoc,
      0.2 / 5.4 * 100,
      tolerance = 1e-6
    )
  }
)

testthat::test_that(
  "recalculate_anova_components() zero sum produces NA",
  {
    res <-
      recalculate_anova_components(data_source = data_zero_sum)

    vec_pct <-
      dplyr::pull(res, R2_Nagelkerke_percentage)

    testthat::expect_true(
      base::all(base::is.na(vec_pct))
    )
  }
)
