testthat::test_that(
  "make_sjsdm_regularization_candidates() is deterministic",
  {
    data_candidates <-
      make_sjsdm_regularization_candidates(
        alpha_cov = base::c(0.5, 0),
        alpha_coef = 0.5,
        alpha_spatial = 0.5,
        lambda_cov = base::c(0.1, 0),
        lambda_coef = 0,
        lambda_spatial = 0
      )

    data_reordered <-
      make_sjsdm_regularization_candidates(
        alpha_cov = base::c(0, 0.5),
        alpha_coef = 0.5,
        alpha_spatial = 0.5,
        lambda_cov = base::c(0, 0.1),
        lambda_coef = 0,
        lambda_spatial = 0
      )

    testthat::expect_equal(data_candidates, data_reordered)
    testthat::expect_named(
      data_candidates,
      base::c(
        "candidate_id",
        "alpha_cov",
        "alpha_coef",
        "alpha_spatial",
        "lambda_cov",
        "lambda_coef",
        "lambda_spatial"
      )
    )
    testthat::expect_equal(
      dplyr::pull(data_candidates, candidate_id),
      stringr::str_c("candidate_", base::sprintf("%03d", 1:4))
    )
    testthat::expect_equal(
      dplyr::pull(data_candidates, alpha_cov),
      base::c(0, 0, 0.5, 0.5)
    )
    testthat::expect_equal(
      dplyr::pull(data_candidates, lambda_cov),
      base::c(0, 0.1, 0, 0.1)
    )
  }
)

testthat::test_that(
  "make_sjsdm_regularization_candidates() validates configured ranges",
  {
    testthat::expect_error(
      make_sjsdm_regularization_candidates(alpha_cov = base::c(0, 1.1)),
      "alpha_cov"
    )
    testthat::expect_error(
      make_sjsdm_regularization_candidates(lambda_cov = base::c(0, -0.1)),
      "lambda_cov"
    )
    testthat::expect_error(
      make_sjsdm_regularization_candidates(lambda_cov = base::c(0, 0)),
      "lambda_cov"
    )
  }
)
