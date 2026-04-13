testthat::test_that(
  "select_ft_groups_by_silhouette() rejects non-dist dist_mat",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_local <-
      stats::dist(mat_data)

    hclust_obj <-
      stats::hclust(dist_local, method = "ward.D2")

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = mat_data,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 3L
      ),
      regexp = "dist_mat"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects NULL dist_mat",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_local <-
      stats::dist(mat_data)

    hclust_obj <-
      stats::hclust(dist_local, method = "ward.D2")

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = NULL,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 3L
      ),
      regexp = "dist_mat"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects non-hclust hclust_obj",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = base::list(merge = base::integer(0)),
        ft_groups_min = 2L,
        ft_groups_max = 3L
      ),
      regexp = "hclust_obj"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects NULL hclust_obj",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = NULL,
        ft_groups_min = 2L,
        ft_groups_max = 3L
      ),
      regexp = "hclust_obj"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects non-integer ft_groups_max",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hclust_obj <-
      stats::hclust(dist_obj, method = "ward.D2")

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = "five"
      ),
      regexp = "ft_groups_max"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects ft_groups_max below 2",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hclust_obj <-
      stats::hclust(dist_obj, method = "ward.D2")

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 1L
      ),
      regexp = "ft_groups_max"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects ft_groups_max of 0L",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hclust_obj <-
      stats::hclust(dist_obj, method = "ward.D2")

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 0L
      ),
      regexp = "ft_groups_max"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects non-integer ft_groups_min",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hclust_obj <-
      stats::hclust(dist_obj, method = "ward.D2")

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = "two",
        ft_groups_max = 3L
      ),
      regexp = "ft_groups_min"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects ft_groups_min below 2",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hclust_obj <-
      stats::hclust(dist_obj, method = "ward.D2")

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 1L,
        ft_groups_max = 3L
      ),
      regexp = "ft_groups_min"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects ft_groups_min > ft_groups_max",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hclust_obj <-
      stats::hclust(dist_obj, method = "ward.D2")

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 5L,
        ft_groups_max = 3L
      ),
      regexp = "ft_groups_min"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() clamps ft_groups_max to n_obs - 1",
  {
    # 6 observations; ft_groups_max = 6L equals n_obs — should be clamped to 5
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0, 6.0),
        nrow = 6L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hclust_obj <-
      stats::hclust(dist_obj, method = "ward.D2")

    res <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 6L
      )

    testthat::expect_type(res, "integer")
    testthat::expect_length(res, 1L)
    testthat::expect_true(res >= 2L && res <= 5L)
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() clamps ft_groups_min for small n_obs",
  {
    # 4 observations; ft_groups_min = 4L would mean ft_groups_min >= n_obs
    # after clamping ft_groups_max to 3L, ft_groups_min should be clamped to 3L
    mat_data <-
      base::matrix(
        base::c(1.0, 10.0, 50.0, 100.0),
        nrow = 4L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hclust_obj <-
      stats::hclust(dist_obj, method = "ward.D2")

    res <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 4L,
        ft_groups_max = 6L
      )

    testthat::expect_type(res, "integer")
    testthat::expect_length(res, 1L)
    testthat::expect_true(res >= 2L && res <= 3L)
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() returns an integer type",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(10L)),
        trait_1 = base::c(
          0.01, 0.02, 0.01, 0.02, 0.01,
          0.99, 0.98, 0.99, 0.98, 0.99
        )
      )

    dist_obj <-
      compute_dissimilarity_matrix(data = data_traits)

    hclust_obj <-
      fit_hclust(dist_mat = dist_obj)

    res <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 5L
      )

    testthat::expect_type(res, "integer")
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() returns a length-1 scalar",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(10L)),
        trait_1 = base::c(
          0.01, 0.02, 0.01, 0.02, 0.01,
          0.99, 0.98, 0.99, 0.98, 0.99
        )
      )

    dist_obj <-
      compute_dissimilarity_matrix(data = data_traits)

    hclust_obj <-
      fit_hclust(dist_mat = dist_obj)

    res <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 5L
      )

    testthat::expect_length(res, 1L)
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() picks 2 groups for clear two groups",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(10L)),
        trait_1 = base::c(
          base::rep(0.1, 5L),
          base::rep(0.9, 5L)
        )
      )

    dist_obj <-
      compute_dissimilarity_matrix(data = data_traits)

    hclust_obj <-
      fit_hclust(dist_mat = dist_obj)

    res <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 5L
      )

    testthat::expect_equal(res, 2L)
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() returns value within ft_groups range",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(8L)),
        trait_1 = base::c(
          0.1, 0.2, 0.3, 0.4, 0.6, 0.7, 0.8, 0.9
        )
      )

    dist_obj <-
      compute_dissimilarity_matrix(data = data_traits)

    hclust_obj <-
      fit_hclust(dist_mat = dist_obj)

    res <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 4L
      )

    testthat::expect_true(res >= 2L && res <= 4L)
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() returns min for single-value sweep",
  {
    # ft_groups_min = ft_groups_max = 2L: only one value to compare, must return 2
    data_traits <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(10L)),
        trait_1 = base::c(
          0.01, 0.02, 0.01, 0.02, 0.01,
          0.99, 0.98, 0.99, 0.98, 0.99
        )
      )

    dist_obj <-
      compute_dissimilarity_matrix(data = data_traits)

    hclust_obj <-
      fit_hclust(dist_mat = dist_obj)

    res <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 2L
      )

    testthat::expect_equal(res, 2L)
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() handles a larger dataset with default bounds",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(30L)),
        trait_1 = base::c(
          base::rep(0.1, 10L),
          base::rep(0.5, 10L),
          base::rep(0.9, 10L)
        )
      )

    dist_obj <-
      compute_dissimilarity_matrix(data = data_traits)

    hclust_obj <-
      fit_hclust(dist_mat = dist_obj)

    res <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 8L
      )

    testthat::expect_type(res, "integer")
    testthat::expect_length(res, 1L)
    testthat::expect_true(res >= 2L && res <= 8L)
  }
)
