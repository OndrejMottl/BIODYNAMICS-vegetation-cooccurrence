testthat::test_that(
  "fit_hierarchical_clustering() errors when trait_dissimilarity is not a dist object",
  {
    testthat::expect_error(
      fit_hierarchical_clustering(trait_dissimilarity = "not_a_dist")
    )
  }
)

testthat::test_that(
  "fit_hierarchical_clustering() errors when clustering_method is not character",
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
      fit_hierarchical_clustering(
        trait_dissimilarity = dist_obj,
        clustering_method = 1L
      )
    )
  }
)

testthat::test_that(
  "fit_hierarchical_clustering() errors when clustering_method has length > 1",
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
      fit_hierarchical_clustering(
        trait_dissimilarity = dist_obj,
        clustering_method = base::c("ward.D2", "complete")
      )
    )
  }
)

testthat::test_that(
  "fit_hierarchical_clustering() returns an object of class hclust",
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
      fit_hierarchical_clustering(trait_dissimilarity = dist_obj)

    testthat::expect_s3_class(res, "hclust")
  }
)

testthat::test_that(
  "fit_hierarchical_clustering() result has correct hclust structure",
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
      fit_hierarchical_clustering(trait_dissimilarity = dist_obj)

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
  "fit_hierarchical_clustering() result$method matches clustering_method",
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
      fit_hierarchical_clustering(
        trait_dissimilarity = dist_obj,
        clustering_method = "complete"
      )

    testthat::expect_equal(
      purrr::chuck(res, "method"),
      "complete"
    )
  }
)

testthat::test_that(
  "fit_hierarchical_clustering() has n-1 merges for n taxa",
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
      fit_hierarchical_clustering(trait_dissimilarity = dist_obj)

    testthat::expect_equal(base::nrow(purrr::chuck(res, "merge")), 4L)
  }
)

testthat::test_that(
  "fit_hierarchical_clustering() different methods produce different results",
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
      fit_hierarchical_clustering(
        trait_dissimilarity = dist_obj,
        clustering_method = "ward.D2"
      )

    res_single <-
      fit_hierarchical_clustering(
        trait_dissimilarity = dist_obj,
        clustering_method = "single"
      )

    testthat::expect_false(
      base::identical(
        purrr::chuck(res_ward, "height"),
        purrr::chuck(res_single, "height")
      )
    )
  }
)
