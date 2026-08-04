testthat::test_that(
  ".prepare_sjsdm_response() preserves Gaussian responses",
  {
    data_community <-
      base::matrix(
        base::c(0, 2, 3, 0),
        nrow = 2L
      )

    result <-
      .prepare_sjsdm_response(
        data_community = data_community,
        error_family = "gaussian"
      )

    testthat::expect_named(
      result,
      base::c("data_community", "error_family")
    )
    testthat::expect_identical(
      result |>
        purrr::chuck("data_community"),
      data_community
    )
    testthat::expect_identical(
      result |>
        purrr::chuck("error_family") |>
        purrr::chuck("family"),
      "gaussian"
    )
  }
)

testthat::test_that(
  ".prepare_sjsdm_response() builds probit presence-absence responses",
  {
    data_community <-
      base::matrix(
        base::c(0, 2, 3, 0),
        nrow = 2L
      )

    result <-
      .prepare_sjsdm_response(
        data_community = data_community,
        error_family = "binomial"
      )

    testthat::expect_identical(
      result |>
        purrr::chuck("data_community"),
      data_community > 0
    )
    testthat::expect_identical(
      result |>
        purrr::chuck("error_family") |>
        purrr::chuck("family"),
      "binomial"
    )
    testthat::expect_identical(
      result |>
        purrr::chuck("error_family") |>
        purrr::chuck("link"),
      "probit"
    )
  }
)
