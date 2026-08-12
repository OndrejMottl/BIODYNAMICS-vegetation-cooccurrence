testthat::test_that(
  "build_sjsdm_structured_regularization_candidates() builds 16 rows",
  {
    vec_lambda_values <-
      base::c(0, 0.01, 0.03, 0.1, 0.3, 1)

    res <-
      build_sjsdm_structured_regularization_candidates(
        lambda_values = vec_lambda_values
      )

    testthat::expect_named(
      res,
      base::c("data_candidates", "data_search_design")
    )

    data_candidates <-
      res[["data_candidates"]]

    data_search_design <-
      res[["data_search_design"]]

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
    testthat::expect_equal(base::nrow(data_candidates), 16L)
    testthat::expect_equal(
      data_candidates[["candidate_id"]],
      stringr::str_c("candidate_", base::sprintf("%03d", 1:16))
    )
    testthat::expect_equal(
      data_candidates[1L, base::c(
        "lambda_cov",
        "lambda_coef",
        "lambda_spatial"
      )],
      tibble::tibble(
        lambda_cov = 0.1,
        lambda_coef = 0.1,
        lambda_spatial = 0.1
      )
    )

    testthat::expect_equal(
      dplyr::count(data_search_design, .data[["search_axis"]]),
      tibble::tibble(
        search_axis = base::c(
          "lambda_coef",
          "lambda_cov",
          "lambda_spatial",
          "reference"
        ),
        n = base::c(5L, 5L, 5L, 1L)
      )
    )
    testthat::expect_equal(
      base::sum(data_search_design[["is_lower_search_boundary"]]),
      3L
    )
    testthat::expect_equal(
      base::sum(data_search_design[["is_upper_search_boundary"]]),
      3L
    )
    testthat::expect_true(data_search_design[["is_reference"]][[1L]])

    res_reordered <-
      build_sjsdm_structured_regularization_candidates(
        lambda_values = base::rev(vec_lambda_values)
      )

    testthat::expect_equal(res, res_reordered)
  }
)

testthat::test_that(
  "build_sjsdm_structured_regularization_candidates() validates ranges",
  {
    testthat::expect_error(
      build_sjsdm_structured_regularization_candidates(
        lambda_values = base::c(0, 0.1, 0.1, 1)
      ),
      "unique"
    )
    testthat::expect_error(
      build_sjsdm_structured_regularization_candidates(
        lambda_values = base::c(0, 0.03, 0.3, 1)
      ),
      "contain every reference"
    )
    testthat::expect_error(
      build_sjsdm_structured_regularization_candidates(
        lambda_cov_reference = 0,
        lambda_values = base::c(0, 0.1, 1)
      ),
      "strictly inside"
    )
    testthat::expect_error(
      build_sjsdm_structured_regularization_candidates(alpha_cov = 1.1),
      "alpha_cov"
    )
  }
)
