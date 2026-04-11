testthat::test_that(
  "fit_hclust() errors when dist_gower is not a dist object",
  {
    testthat::expect_error(
      fit_hclust(dist_gower = "not_a_dist")
    )
  }
)

testthat::test_that(
  "fit_hclust() errors when method is not character",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0),
        nrow = 3L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    testthat::expect_error(
      fit_hclust(
        dist_gower = dist_obj,
        method = 1L
      )
    )
  }
)

testthat::test_that(
  "fit_hclust() errors when method has length > 1",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0),
        nrow = 3L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    testthat::expect_error(
      fit_hclust(
        dist_gower = dist_obj,
        method = base::c("ward.D2", "complete")
      )
    )
  }
)

testthat::test_that(
  "fit_hclust() returns an object of class hclust",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 10.0, 11.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    res <-
      fit_hclust(dist_gower = dist_obj)

    testthat::expect_s3_class(res, "hclust")
  }
)

testthat::test_that(
  "fit_hclust() result has correct hclust structure",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 10.0, 11.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    res <-
      fit_hclust(dist_gower = dist_obj)

    vec_expected_names <-
      base::c(
        "merge", "height", "order", "labels",
        "method", "call", "dist.method"
      )

    testthat::expect_true(
      base::all(vec_expected_names %in% base::names(res))
    )
  }
)

testthat::test_that(
  "fit_hclust() result$method matches method argument",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 10.0, 11.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    res <-
      fit_hclust(dist_gower = dist_obj, method = "complete")

    testthat::expect_equal(purrr::chuck(res, "method"), "complete")
  }
)

testthat::test_that(
  "fit_hclust() has n-1 merges for n taxa",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 10.0, 11.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    res <-
      fit_hclust(dist_gower = dist_obj)

    testthat::expect_equal(base::nrow(purrr::chuck(res, "merge")), 4L)
  }
)

testthat::test_that(
  "fit_hclust() different methods produce different results",
  {
    # Points 0,1,2,3,10: ward.D2 forms balanced clusters while
    # single linkage chains; their merge heights always differ.
    mat_data <-
      base::matrix(
        base::c(0.0, 1.0, 2.0, 3.0, 10.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    res_ward <-
      fit_hclust(
        dist_gower = dist_obj,
        method = "ward.D2"
      )

    res_single <-
      fit_hclust(
        dist_gower = dist_obj,
        method = "single"
      )

    testthat::expect_false(
      base::identical(
        purrr::chuck(res_ward, "height"),
        purrr::chuck(res_single, "height")
      )
    )
  }
)
