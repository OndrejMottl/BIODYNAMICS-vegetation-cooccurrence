make_predictor_inclusive_fraction_fixture <- function(
    age = 100,
    values = base::c(0.1, 0.2, 0.3, 0.04, 0.06, 0.08, 0.09)) {
  tibble::tibble(
    age = age,
    component = base::c(
      "Abiotic",
      "Associations",
      "Spatial",
      "Abiotic&Associations",
      "Abiotic&Spatial",
      "Associations&Spatial",
      "Abiotic&Associations&Spatial"
    ),
    R2_Nagelkerke = values
  )
}

testthat::test_that(
  "predictor-inclusive components use every shared fraction in full",
  {
    data_source <-
      make_predictor_inclusive_fraction_fixture()

    res <-
      compute_predictor_inclusive_variance_components(data_source)

    vec_expected_totals <-
      base::c(0.29, 0.41, 0.53)
    vec_expected_percentages <-
      vec_expected_totals / 0.87 * 100

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(base::nrow(res), 3L)
    testthat::expect_equal(
      dplyr::pull(res, component),
      base::c("Abiotic", "Associations", "Spatial")
    )
    testthat::expect_equal(
      dplyr::pull(res, R2_Nagelkerke_predictor_inclusive),
      vec_expected_totals,
      tolerance = 1e-12
    )
    testthat::expect_equal(
      dplyr::pull(
        res,
        R2_Nagelkerke_predictor_inclusive_percentage
      ),
      vec_expected_percentages,
      tolerance = 1e-12
    )
    testthat::expect_gt(base::sum(vec_expected_percentages), 100)
  }
)

testthat::test_that(
  "predictor-inclusive components clamp negatives and fill absent fractions",
  {
    data_source <-
      tibble::tibble(
        age = 0,
        component = base::c(
          "Abiotic",
          "Associations",
          "Abiotic&Associations",
          "unrecognised"
        ),
        R2_Nagelkerke = base::c(-0.4, 0.2, 0.3, 100)
      )

    res <-
      compute_predictor_inclusive_variance_components(data_source)

    testthat::expect_equal(
      dplyr::pull(res, R2_Nagelkerke_predictor_inclusive),
      base::c(0.3, 0.5, 0)
    )
    testthat::expect_equal(
      dplyr::pull(
        res,
        R2_Nagelkerke_predictor_inclusive_percentage
      ),
      base::c(60, 100, 0)
    )
  }
)

testthat::test_that(
  "predictor-inclusive components process ages independently",
  {
    data_source <-
      dplyr::bind_rows(
        make_predictor_inclusive_fraction_fixture(age = 0),
        make_predictor_inclusive_fraction_fixture(
          age = 100,
          values = base::c(0.2, 0, 0, 0, 0, 0, 0)
        )
      )

    res <-
      compute_predictor_inclusive_variance_components(data_source)

    testthat::expect_equal(base::nrow(res), 6L)
    testthat::expect_equal(
      res |>
        dplyr::filter(.data$age == 100) |>
        dplyr::pull(R2_Nagelkerke_predictor_inclusive_percentage),
      base::c(100, 0, 0)
    )
  }
)

testthat::test_that(
  "predictor-inclusive zero denominator returns missing percentages",
  {
    data_source <-
      make_predictor_inclusive_fraction_fixture(
        values = base::rep(0, 7L)
      )

    res <-
      compute_predictor_inclusive_variance_components(data_source)

    testthat::expect_true(
      base::all(
        base::is.na(
          dplyr::pull(
            res,
            R2_Nagelkerke_predictor_inclusive_percentage
          )
        )
      )
    )
  }
)

testthat::test_that(
  "predictor-inclusive components validate their input contract",
  {
    testthat::expect_error(
      compute_predictor_inclusive_variance_components(NULL),
      regexp = "non-empty data frame"
    )
    testthat::expect_error(
      compute_predictor_inclusive_variance_components(
        tibble::tibble(age = 0)
      ),
      regexp = "must contain columns"
    )
  }
)
