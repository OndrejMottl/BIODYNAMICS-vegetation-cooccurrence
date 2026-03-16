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
  "extract_anova_fractions() errors if anova_object not list",
  {
    testthat::expect_error(
      extract_anova_fractions(
        anova_object = "not a list",
        vec_anova_fractions = c("F_A")
      ),
      "'anova_object' must be a list."
    )

    testthat::expect_error(
      extract_anova_fractions(
        anova_object = 42L,
        vec_anova_fractions = c("F_A")
      ),
      "'anova_object' must be a list."
    )
  }
)

testthat::test_that(
  "extract_anova_fractions() errors if fractions not character",
  {
    obj <-
      make_mock_anova_obj()

    testthat::expect_error(
      extract_anova_fractions(
        anova_object = obj,
        vec_anova_fractions = c(1L, 2L)
      ),
      "'vec_anova_fractions' must be a character vector."
    )
  }
)

testthat::test_that(
  "extract_anova_fractions() errors if fractions is empty",
  {
    obj <-
      make_mock_anova_obj()

    testthat::expect_error(
      extract_anova_fractions(
        anova_object = obj,
        vec_anova_fractions = base::character(0)
      ),
      "'vec_anova_fractions' must not be empty."
    )
  }
)

testthat::test_that(
  "extract_anova_fractions() errors if clamp_negative not flag",
  {
    obj <-
      make_mock_anova_obj()

    testthat::expect_error(
      extract_anova_fractions(
        anova_object = obj,
        vec_anova_fractions = c("F_A"),
        clamp_negative = c(TRUE, FALSE)
      ),
      "'clamp_negative' must be a single logical value."
    )

    testthat::expect_error(
      extract_anova_fractions(
        anova_object = obj,
        vec_anova_fractions = c("F_A"),
        clamp_negative = "yes"
      ),
      "'clamp_negative' must be a single logical value."
    )

    testthat::expect_error(
      extract_anova_fractions(
        anova_object = obj,
        vec_anova_fractions = c("F_A"),
        clamp_negative = 1L
      ),
      "'clamp_negative' must be a single logical value."
    )
  }
)

testthat::test_that(
  "extract_anova_fractions() returns data frame with correct cols",
  {
    obj <-
      make_mock_anova_obj()

    res <-
      extract_anova_fractions(
        anova_object = obj,
        vec_anova_fractions = c("F_A", "F_B")
      )

    testthat::expect_s3_class(res, "data.frame")
    testthat::expect_equal(base::ncol(res), 2L)
    testthat::expect_named(
      res,
      c("component", "R2_Nagelkerke")
    )
  }
)

testthat::test_that(
  "extract_anova_fractions() returns correct number of rows",
  {
    obj <-
      make_mock_anova_obj()

    res_three <-
      extract_anova_fractions(
        anova_object = obj,
        vec_anova_fractions = c("F_A", "F_B", "F_S")
      )

    res_all <-
      extract_anova_fractions(
        anova_object = obj,
        vec_anova_fractions = c(
          "F_A", "F_B", "F_S",
          "F_AB", "F_AS", "F_BS", "F_ABS"
        )
      )

    testthat::expect_equal(base::nrow(res_three), 3L)
    testthat::expect_equal(base::nrow(res_all), 7L)
  }
)

testthat::test_that(
  "extract_anova_fractions() returns only requested fractions",
  {
    obj <-
      make_mock_anova_obj()

    res <-
      extract_anova_fractions(
        anova_object = obj,
        vec_anova_fractions = c("F_A", "F_S")
      )

    vec_components <-
      dplyr::pull(res, component)

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_true("Abiotic" %in% vec_components)
    testthat::expect_true("Spatial" %in% vec_components)
    testthat::expect_false(
      "Associations" %in% vec_components
    )
  }
)

testthat::test_that(
  "extract_anova_fractions() translates all codes to labels",
  {
    obj <-
      make_mock_anova_obj()

    res <-
      extract_anova_fractions(
        anova_object = obj,
        vec_anova_fractions = c(
          "F_A", "F_B", "F_S",
          "F_AB", "F_AS", "F_BS", "F_ABS"
        )
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
    testthat::expect_true("Abiotic" %in% vec_components)
    testthat::expect_true(
      "Associations" %in% vec_components
    )
    testthat::expect_true("Spatial" %in% vec_components)
    testthat::expect_true(
      "Abiotic&Associations" %in% vec_components
    )
    testthat::expect_true(
      "Abiotic&Spatial" %in% vec_components
    )
    testthat::expect_true(
      "Associations&Spatial" %in% vec_components
    )
    testthat::expect_true(
      "Abiotic&Associations&Spatial" %in% vec_components
    )
  }
)

testthat::test_that(
  "extract_anova_fractions() clamps negative R2 to 0",
  {
    vec_r2_neg <-
      c(-0.05, 0.20, 0.30, 0.05, -0.10, 0.05, 0.25)

    obj <-
      make_mock_anova_obj(r2_values = vec_r2_neg)

    res <-
      extract_anova_fractions(
        anova_object = obj,
        vec_anova_fractions = c("F_A", "F_AS"),
        clamp_negative = TRUE
      )

    vec_r2_out <-
      dplyr::pull(res, R2_Nagelkerke)

    testthat::expect_true(base::all(vec_r2_out >= 0))
  }
)

testthat::test_that(
  "extract_anova_fractions() preserves negative R2 values",
  {
    vec_r2_neg <-
      c(-0.05, 0.20, 0.30, 0.05, -0.10, 0.05, 0.25)

    obj <-
      make_mock_anova_obj(r2_values = vec_r2_neg)

    res <-
      extract_anova_fractions(
        anova_object = obj,
        vec_anova_fractions = c("F_A", "F_AS"),
        clamp_negative = FALSE
      )

    vec_r2_out <-
      dplyr::pull(res, R2_Nagelkerke)

    testthat::expect_true(base::any(vec_r2_out < 0))

    vec_abiotic_r2 <-
      dplyr::filter(res, component == "Abiotic") |>
      dplyr::pull(R2_Nagelkerke)

    testthat::expect_equal(vec_abiotic_r2, -0.05)
  }
)

testthat::test_that(
  "extract_anova_fractions() errors if results element missing",
  {
    obj_no_results <-
      base::list(other_element = 1L)
    base::class(obj_no_results) <- "sjSDManova"

    testthat::expect_error(
      extract_anova_fractions(
        anova_object = obj_no_results,
        vec_anova_fractions = c("F_A")
      )
    )
  }
)

