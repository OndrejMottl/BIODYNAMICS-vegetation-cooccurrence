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
        ncol = 1L,
        dimnames = base::list(base::as.character(base::seq_len(6L)), NULL)
      )

    dist_obj <-
      stats::dist(mat_data)

    hclust_obj <-
      stats::hclust(dist_obj, method = "ward.D2")

    data_community_fix <-
      tibble::tibble(
        taxon = base::rep(base::as.character(base::seq_len(6L)), 2L),
        dataset_name = base::c(
          base::rep("d1", 6L),
          base::rep("d2", 6L)
        ),
        age = base::rep(1.0, 12L),
        pollen_prop = base::c(
          base::ifelse(base::seq_len(6L) <= 3L, 0.2, 0.0),
          base::ifelse(base::seq_len(6L) > 3L, 0.2, 0.0)
        )
      )
    res_k <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 6L,
        data_community = data_community_fix,
        minimal_proportion = 0.05,
        min_n_taxa = 1L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      )

    testthat::expect_type(res_k, "integer")
    testthat::expect_length(res_k, 1L)
    testthat::expect_true(res_k >= 2L && res_k <= 5L)
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
        ncol = 1L,
        dimnames = base::list(base::as.character(base::seq_len(4L)), NULL)
      )

    dist_obj <-
      stats::dist(mat_data)

    hclust_obj <-
      stats::hclust(dist_obj, method = "ward.D2")

    data_community_fix <-
      tibble::tibble(
        taxon = base::rep(base::as.character(base::seq_len(4L)), 2L),
        dataset_name = base::c(
          base::rep("d1", 4L),
          base::rep("d2", 4L)
        ),
        age = base::rep(1.0, 8L),
        pollen_prop = base::c(
          base::ifelse(base::seq_len(4L) <= 2L, 0.2, 0.0),
          base::ifelse(base::seq_len(4L) > 2L, 0.2, 0.0)
        )
      )
    res_k <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 4L,
        ft_groups_max = 6L,
        data_community = data_community_fix,
        minimal_proportion = 0.05,
        min_n_taxa = 1L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      )

    testthat::expect_type(res_k, "integer")
    testthat::expect_length(res_k, 1L)
    testthat::expect_true(res_k >= 2L && res_k <= 3L)
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

    data_community_fix <-
      tibble::tibble(
        taxon = base::rep(
          stringr::str_c("sp_", base::seq_len(10L)),
          2L
        ),
        dataset_name = base::c(
          base::rep("d1", 10L),
          base::rep("d2", 10L)
        ),
        age = base::rep(1.0, 20L),
        pollen_prop = base::c(
          base::ifelse(base::seq_len(10L) <= 5L, 0.2, 0.0),
          base::ifelse(base::seq_len(10L) > 5L, 0.2, 0.0)
        )
      )
    res_k <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 5L,
        data_community = data_community_fix,
        minimal_proportion = 0.05,
        min_n_taxa = 1L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      )

    testthat::expect_type(res_k, "integer")
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

    data_community_fix <-
      tibble::tibble(
        taxon = base::rep(
          stringr::str_c("sp_", base::seq_len(10L)),
          2L
        ),
        dataset_name = base::c(
          base::rep("d1", 10L),
          base::rep("d2", 10L)
        ),
        age = base::rep(1.0, 20L),
        pollen_prop = base::c(
          base::ifelse(base::seq_len(10L) <= 5L, 0.2, 0.0),
          base::ifelse(base::seq_len(10L) > 5L, 0.2, 0.0)
        )
      )
    res_k <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 5L,
        data_community = data_community_fix,
        minimal_proportion = 0.05,
        min_n_taxa = 1L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      )

    testthat::expect_length(res_k, 1L)
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() picks 2 groups for clear two groups",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(10L)),
        trait_1 = base::c(
          0.08, 0.10, 0.11, 0.09, 0.12, 0.88, 0.90, 0.91, 0.89, 0.92
        )
      )

    dist_obj <-
      compute_dissimilarity_matrix(data = data_traits)

    hclust_obj <-
      fit_hclust(dist_mat = dist_obj)

    data_community_fix <-
      tibble::tibble(
        taxon = base::rep(
          stringr::str_c("sp_", base::seq_len(10L)),
          2L
        ),
        dataset_name = base::c(
          base::rep("d1", 10L),
          base::rep("d2", 10L)
        ),
        age = base::rep(1.0, 20L),
        pollen_prop = base::c(
          base::ifelse(base::seq_len(10L) <= 5L, 0.2, 0.0),
          base::ifelse(base::seq_len(10L) > 5L, 0.2, 0.0)
        )
      )
    res_k <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 5L,
        data_community = data_community_fix,
        minimal_proportion = 0.05,
        min_n_taxa = 1L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      )

    testthat::expect_equal(res_k, 2L)
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

    data_community_fix <-
      tibble::tibble(
        taxon = base::rep(
          stringr::str_c("sp_", base::seq_len(8L)),
          2L
        ),
        dataset_name = base::c(
          base::rep("d1", 8L),
          base::rep("d2", 8L)
        ),
        age = base::rep(1.0, 16L),
        pollen_prop = base::c(
          base::ifelse(base::seq_len(8L) <= 4L, 0.2, 0.0),
          base::ifelse(base::seq_len(8L) > 4L, 0.2, 0.0)
        )
      )
    res_k <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 4L,
        data_community = data_community_fix,
        minimal_proportion = 0.05,
        min_n_taxa = 1L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      )

    testthat::expect_true(res_k >= 2L && res_k <= 4L)
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

    data_community_fix <-
      tibble::tibble(
        taxon = base::rep(
          stringr::str_c("sp_", base::seq_len(10L)),
          2L
        ),
        dataset_name = base::c(
          base::rep("d1", 10L),
          base::rep("d2", 10L)
        ),
        age = base::rep(1.0, 20L),
        pollen_prop = base::c(
          base::ifelse(base::seq_len(10L) <= 5L, 0.2, 0.0),
          base::ifelse(base::seq_len(10L) > 5L, 0.2, 0.0)
        )
      )
    res_k <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 2L,
        data_community = data_community_fix,
        minimal_proportion = 0.05,
        min_n_taxa = 1L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      )

    testthat::expect_equal(res_k, 2L)
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() handles a 30-taxon dataset",
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

    data_community_fix <-
      tibble::tibble(
        taxon = base::rep(
          stringr::str_c("sp_", base::seq_len(30L)),
          2L
        ),
        dataset_name = base::c(
          base::rep("d1", 30L),
          base::rep("d2", 30L)
        ),
        age = base::rep(1.0, 60L),
        pollen_prop = base::c(
          base::ifelse(base::seq_len(30L) <= 15L, 0.2, 0.0),
          base::ifelse(base::seq_len(30L) > 15L, 0.2, 0.0)
        )
      )
    res_k <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 8L,
        data_community = data_community_fix,
        minimal_proportion = 0.05,
        min_n_taxa = 1L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      )

    testthat::expect_type(res_k, "integer")
    testthat::expect_length(res_k, 1L)
    testthat::expect_true(res_k >= 2L && res_k <= 8L)
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects non-data.frame data_community",
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
        ft_groups_max = 3L,
        data_community = base::c("sp_1", "sp_2"),
        minimal_proportion = 0.1,
        min_n_taxa = 2L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      ),
      regexp = "data_community"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects data_community missing pollen_prop",
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

    data_community_no_pollen <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0
      )

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 3L,
        data_community = data_community_no_pollen,
        minimal_proportion = 0.1,
        min_n_taxa = 2L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      ),
      regexp = "data_community"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects minimal_proportion >= 1",
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

    data_community_minimal <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0,
        pollen_prop = 0.5
      )

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 3L,
        data_community = data_community_minimal,
        minimal_proportion = 1.5,
        min_n_taxa = 2L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      )
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects minimal_proportion = 0",
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

    data_community_minimal <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0,
        pollen_prop = 0.5
      )

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 3L,
        data_community = data_community_minimal,
        minimal_proportion = 0,
        min_n_taxa = 2L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      )
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects min_n_taxa = 0",
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

    data_community_minimal <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0,
        pollen_prop = 0.5
      )

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 3L,
        data_community = data_community_minimal,
        minimal_proportion = 0.1,
        min_n_taxa = 0L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      )
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() skips best-silhouette k if non-viable",
  {
    # 6 taxa: sp_1..sp_4 identical at 0.01, sp_5..sp_6 identical
    # at 0.99. k=2 silhouette = 1.0; k=3 splits sp_1..sp_4 into
    # {sp_1,sp_2} vs {sp_3,sp_4} which are identical -> b=0, s=0
    # for each -> mean silhouette at k=3 = 2/6 = 0.33. k=2 wins.
    data_traits_9 <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(6L)),
        trait_1 = base::c(
          0.01, 0.01, 0.01, 0.01, 0.99, 0.99
        )
      )

    dist_obj_9 <-
      compute_dissimilarity_matrix(data = data_traits_9)

    hclust_obj_9 <-
      fit_hclust(dist_mat = dist_obj_9)

    # k=2: G1={sp_1..sp_4} sum always > 0.10 (ubiquitous),
    #       G2={sp_5,sp_6} sum always > 0.10 (ubiquitous)
    #   -> n_non_constant = 0 -> NOT viable
    # k=3 splits sp_5,sp_6 into singletons: {sp_1..sp_4},{sp_5},{sp_6}
    #   sp_5 absent in samples age=3,4 (prop=0); sp_6 absent in 1,2
    #   G2={sp_5} and G3={sp_6} non-constant: see-saw pattern
    #   -> n_non_constant = 2 -> VIABLE
    data_community_9 <-
      tibble::tibble(
        taxon = base::rep(
          stringr::str_c("sp_", base::seq_len(6L)),
          times = 4L
        ),
        dataset_name = base::rep("d1", times = 24L),
        age = base::rep(
          base::c(1.0, 2.0, 3.0, 4.0),
          each = 6L
        ),
        pollen_prop = base::c(
          0.20, 0.20, 0.20, 0.20, 0.20, 0.00,
          0.20, 0.20, 0.20, 0.20, 0.20, 0.00,
          0.20, 0.20, 0.20, 0.20, 0.00, 0.20,
          0.20, 0.20, 0.20, 0.20, 0.00, 0.20
        )
      )

    res_viability <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj_9,
        hclust_obj = hclust_obj_9,
        ft_groups_min = 2L,
        ft_groups_max = 3L,
        data_community = data_community_9,
        minimal_proportion = 0.10,
        min_n_taxa = 2L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      )

    testthat::expect_equal(res_viability, 3L)
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() errors when no k is viable",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(8L)),
        trait_1 = base::c(
          0.10, 0.10, 0.10, 0.10, 0.88, 0.88, 0.92, 0.92
        )
      )

    dist_obj <-
      compute_dissimilarity_matrix(data = data_traits)

    hclust_obj <-
      fit_hclust(dist_mat = dist_obj)

    data_community_10 <-
      tibble::tibble(
        taxon = base::rep(
          stringr::str_c("sp_", base::seq_len(8L)),
          times = 4L
        ),
        dataset_name = base::rep("d1", times = 32L),
        age = base::rep(
          base::c(1.0, 2.0, 3.0, 4.0),
          each = 8L
        ),
        pollen_prop = base::rep(0.20, times = 32L)
      )

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 3L,
        data_community = data_community_10,
        minimal_proportion = 0.10,
        min_n_taxa = 3L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      ),
      regexp = "No viable"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() returns same k when best k is viable",
  {
    # Same 6-taxon design: sp_1..sp_4 at 0.01, sp_5..sp_6 at 0.99
    # k=2 silhouette = 1.0 (max), k=3 = 0.33 -> k=2 wins.
    # Community: G2={sp_5,sp_6} absent in samples 3,4 -> non-constant
    # -> k=2 is viable with min_n_taxa=1.
    # With viability k=2 is still selected (same as without).
    data_traits_11 <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(6L)),
        trait_1 = base::c(
          0.01, 0.01, 0.01, 0.01, 0.99, 0.99
        )
      )

    dist_obj_11 <-
      compute_dissimilarity_matrix(data = data_traits_11)

    hclust_obj_11 <-
      fit_hclust(dist_mat = dist_obj_11)

    # G1={sp_1..sp_4}: always present (sum=0.80 > 0.10) -> constant
    # G2={sp_5,sp_6}: present in samples 1,2 (sum=0.40); absent 3,4
    #   -> pct_present=0.50 -> non-constant -> n_non_constant=1 >= 1
    data_community_11 <-
      tibble::tibble(
        taxon = base::rep(
          stringr::str_c("sp_", base::seq_len(6L)),
          times = 4L
        ),
        dataset_name = base::rep("d1", times = 24L),
        age = base::rep(
          base::c(1.0, 2.0, 3.0, 4.0),
          each = 6L
        ),
        pollen_prop = base::c(
          0.20, 0.20, 0.20, 0.20, 0.20, 0.20,
          0.20, 0.20, 0.20, 0.20, 0.20, 0.20,
          0.20, 0.20, 0.20, 0.20, 0.00, 0.00,
          0.20, 0.20, 0.20, 0.20, 0.00, 0.00
        )
      )

    res_viability <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj_11,
        hclust_obj = hclust_obj_11,
        ft_groups_min = 2L,
        ft_groups_max = 3L,
        data_community = data_community_11,
        minimal_proportion = 0.10,
        min_n_taxa = 1L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      )

    testthat::expect_equal(res_viability, 2L)
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects non-integer min_n_cores",
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

    data_community_minimal <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0,
        pollen_prop = 0.5
      )

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 3L,
        data_community = data_community_minimal,
        minimal_proportion = 0.1,
        min_n_taxa = 2L,
        min_n_cores = "five",
        min_n_samples = 1L,
        error_family = "gaussian"
      ),
      regexp = "min_n_cores"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects min_n_cores less than 1",
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

    data_community_minimal <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0,
        pollen_prop = 0.5
      )

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 3L,
        data_community = data_community_minimal,
        minimal_proportion = 0.1,
        min_n_taxa = 2L,
        min_n_cores = 0L,
        min_n_samples = 1L,
        error_family = "gaussian"
      ),
      regexp = "min_n_cores"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() group excluded by min_n_cores filter",
  {
    # 8 taxa in 3 trait clusters (k=3 is structurally correct):
    #   sp_1..sp_4: trait 0.01 (ubiquitous across all 3 cores -> constant)
    #   sp_5, sp_6: trait 0.60 (present in d1 AND d2 -> non-constant, n_cores=2)
    #   sp_7, sp_8: trait 0.99 (present in d1 ONLY  -> non-constant, n_cores=1)
    #
    # Trait distances (Gower, range=0.98):
    #   A-B = 0.60; B-C = 0.40; A-C = 1.00
    # -> hclust merges B+C first -> at k=2: G1={A}, G2={B,C}
    #                            -> at k=3: G1={A}, G2={B}, G3={C}
    #
    # Without min_n_cores (min_n_taxa=2):
    #   k=2: G2={sp5..sp8} non-constant, n_nc=1 < 2 -> non-viable
    #   k=3: G2={sp5,6} non-constant AND G3={sp7,8} non-constant -> n_nc=2 >= 2
    #        -> viable -> k=3 selected
    #
    # With min_n_cores=2 (min_n_taxa=2):
    #   k=2: G2 n_cores=2 (d1+d2) qualifies; n_nc=1 < 2 -> non-viable
    #   k=3: G2={sp5,6} n_cores=2 qualifies; G3={sp7,8} n_cores=1 -> filtered
    #        n_nc=1 < 2 -> non-viable
    #   Both non-viable -> cli::cli_abort() raised
    data_traits_12 <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(8L)),
        trait_1 = base::c(
          0.01, 0.01, 0.01, 0.01,
          0.60, 0.60,
          0.99, 0.99
        )
      )

    dist_obj_12 <-
      compute_dissimilarity_matrix(data = data_traits_12)

    hclust_obj_12 <-
      fit_hclust(dist_mat = dist_obj_12)

    # 3 cores (d1, d2, d3) x 8 taxa, 1 age each -> 24 rows
    # sp_1..sp_4: 0.15 in all 3 cores (ubiquitous -> constant)
    # sp_5, sp_6: 0.15 in d1 and d2; 0.00 in d3
    # sp_7, sp_8: 0.15 in d1 only; 0.00 in d2 and d3
    data_community_12 <-
      tibble::tibble(
        taxon = base::rep(
          stringr::str_c("sp_", base::seq_len(8L)),
          times = 3L
        ),
        dataset_name = base::c(
          base::rep("d1", 8L),
          base::rep("d2", 8L),
          base::rep("d3", 8L)
        ),
        age = base::rep(1.0, 24L),
        pollen_prop = base::c(
          0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15,
          0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.00, 0.00,
          0.15, 0.15, 0.15, 0.15, 0.00, 0.00, 0.00, 0.00
        )
      )

    # Without min_n_cores: k=3 is viable (n_nc=2 >= min_n_taxa=2) -> k=3
    res_no_cores <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj_12,
        hclust_obj = hclust_obj_12,
        ft_groups_min = 2L,
        ft_groups_max = 3L,
        data_community = data_community_12,
        minimal_proportion = 0.05,
        min_n_taxa = 2L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "gaussian"
      )

    # With min_n_cores=2: both k=2 and k=3 non-viable -> error
    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj_12,
        hclust_obj = hclust_obj_12,
        ft_groups_min = 2L,
        ft_groups_max = 3L,
        data_community = data_community_12,
        minimal_proportion = 0.05,
        min_n_taxa = 2L,
        min_n_cores = 2L,
        min_n_samples = 1L,
        error_family = "gaussian"
      ),
      regexp = "No viable"
    )

    testthat::expect_equal(res_no_cores, 3L)
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects non-integer min_n_samples",
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

    data_community_minimal <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0,
        pollen_prop = 0.5
      )

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 3L,
        data_community = data_community_minimal,
        minimal_proportion = 0.1,
        min_n_taxa = 1L,
        min_n_cores = 1L,
        min_n_samples = "five",
        error_family = "gaussian"
      ),
      regexp = "min_n_samples"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects min_n_samples less than 1",
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

    data_community_minimal <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0,
        pollen_prop = 0.5
      )

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 3L,
        data_community = data_community_minimal,
        minimal_proportion = 0.1,
        min_n_taxa = 1L,
        min_n_cores = 1L,
        min_n_samples = 0L,
        error_family = "gaussian"
      ),
      regexp = "min_n_samples"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() rejects non-character error_family",
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

    data_community_minimal <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0,
        pollen_prop = 0.5
      )

    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 3L,
        data_community = data_community_minimal,
        minimal_proportion = 0.1,
        min_n_taxa = 1L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = 42L
      ),
      regexp = "error_family"
    )
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() binomial binarisation groups constant",
  {
    # 4 taxa in 2 trait clusters:
    #   G1 = {sp_1, sp_2}: trait 0.01 — present in d1 only (sometimes absent)
    #   G2 = {sp_3, sp_4}: trait 0.99 — always present at varying proportions
    #                                    all above minimal_proportion
    #
    # FT-level community (k=2, ft_groups_min = ft_groups_max = 2):
    #
    #   G1 sums: (d1,1)=0.20, (d1,2)=0.20, (d2,1)=0.00, (d2,2)=0.00
    #   G2 sums: (d1,1)=0.20, (d1,2)=0.24, (d2,1)=0.16, (d2,2)=0.18
    #
    # Without error_family (no binarisation):
    #   G1 col: [0.20, 0.20, 0, 0]      -> non-constant -> counted
    #   G2 col: [0.20, 0.24, 0.16, 0.18] -> non-constant -> counted
    #   n_nc = 2 >= min_n_taxa=2 -> viable -> NO warning
    #
    # With error_family="binomial":
    #   G1 binarised: [1, 1, 0, 0]  -> non-constant -> counted
    #   G2 binarised: [1, 1, 1, 1]  -> constant     -> removed
    #   n_nc = 1 < min_n_taxa=2     -> non-viable   -> WARNING
    data_traits_14 <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(4L)),
        trait_1 = base::c(0.01, 0.01, 0.99, 0.99)
      )

    dist_obj_14 <-
      compute_dissimilarity_matrix(data = data_traits_14)

    hclust_obj_14 <-
      fit_hclust(dist_mat = dist_obj_14)

    # 2 cores x 2 ages = 4 samples; sp_1,sp_2 absent in d2; sp_3,sp_4 always
    # present at varying proportions all above minimal_proportion=0.05.
    data_community_14 <-
      tibble::tibble(
        taxon = base::rep(
          stringr::str_c("sp_", base::seq_len(4L)),
          times = 4L
        ),
        dataset_name = base::c(
          base::rep("d1", 4L),
          base::rep("d1", 4L),
          base::rep("d2", 4L),
          base::rep("d2", 4L)
        ),
        age = base::c(
          base::rep(1.0, 4L),
          base::rep(2.0, 4L),
          base::rep(1.0, 4L),
          base::rep(2.0, 4L)
        ),
        pollen_prop = base::c(
          0.10, 0.10, 0.10, 0.10,
          0.10, 0.10, 0.12, 0.12,
          0.00, 0.00, 0.08, 0.08,
          0.00, 0.00, 0.09, 0.09
        )
      )

    # Without error_family: G1 and G2 both non-constant -> viable -> no warning
    testthat::expect_no_warning(
      res_no_family <-
        select_ft_groups_by_silhouette(
          dist_mat = dist_obj_14,
          hclust_obj = hclust_obj_14,
          ft_groups_min = 2L,
          ft_groups_max = 2L,
          data_community = data_community_14,
          minimal_proportion = 0.05,
          min_n_taxa = 2L,
          min_n_cores = 1L,
          min_n_samples = 1L,
          error_family = "gaussian"
        )
    )

    # With error_family="binomial": G2 binarises to all-1 -> constant
    # -> n_nc=1 < min_n_taxa=2 -> non-viable -> error
    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj_14,
        hclust_obj = hclust_obj_14,
        ft_groups_min = 2L,
        ft_groups_max = 2L,
        data_community = data_community_14,
        minimal_proportion = 0.05,
        min_n_taxa = 2L,
        min_n_cores = 1L,
        min_n_samples = 1L,
        error_family = "binomial"
      ),
      regexp = "No viable"
    )

    testthat::expect_equal(res_no_family, 2L)
  }
)


testthat::test_that(
  "select_ft_groups_by_silhouette() group excluded by min_n_samples filter",
  {
    # 4 taxa in 2 trait clusters:
    #   G1 = {sp_1, sp_2}: trait 0.01 — present in all 4 samples at varying
    #                                    proportions (non-constant)
    #   G2 = {sp_3, sp_4}: trait 0.99 — present in only 1 sample (d1, age=1)
    #
    # Community: 2 cores x 2 ages = 4 samples.
    # G1 props vary across samples; G2 present only in (d1, 1.0).
    #
    # FT-level sums after inner_join (k=2):
    #   G1: (d1,1)=0.20, (d1,2)=0.24, (d2,1)=0.16, (d2,2)=0.18 — all > 0.05
    #   G2: (d1,1)=0.20 only — rest 0.00 -> filtered by filter_rare_taxa
    #
    # data_sample_ids (common to both branches): {(d1,1),(d1,2),(d2,1),(d2,2)}
    #
    # Without min_n_samples (min_n_taxa=2):
    #   Matrix: G1=[0.20,0.24,0.16,0.18] non-constant;
    #           G2=[0.20,0,0,0] non-constant
    #   n_nc=2 >= 2 -> viable -> NO warning
    #
    # With min_n_samples=2:
    #   G2 has only 1 distinct (dataset_name, age) -> filter_by_n_samples removes it
    #   n_nc=1 < min_n_taxa=2 -> non-viable -> WARNING
    data_traits_15 <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(4L)),
        trait_1 = base::c(0.01, 0.01, 0.99, 0.99)
      )

    dist_obj_15 <-
      compute_dissimilarity_matrix(data = data_traits_15)

    hclust_obj_15 <-
      fit_hclust(dist_mat = dist_obj_15)

    # 2 cores x 2 ages = 4 samples; G1 present at varying proportions
    # in all 4 samples; G2 present only in d1/age=1.0.
    data_community_15 <-
      tibble::tibble(
        taxon = base::rep(
          stringr::str_c("sp_", base::seq_len(4L)),
          times = 4L
        ),
        dataset_name = base::c(
          base::rep("d1", 4L),
          base::rep("d1", 4L),
          base::rep("d2", 4L),
          base::rep("d2", 4L)
        ),
        age = base::c(
          base::rep(1.0, 4L),
          base::rep(2.0, 4L),
          base::rep(1.0, 4L),
          base::rep(2.0, 4L)
        ),
        pollen_prop = base::c(
          0.10, 0.10, 0.10, 0.10,
          0.12, 0.12, 0.00, 0.00,
          0.08, 0.08, 0.00, 0.00,
          0.09, 0.09, 0.00, 0.00
        )
      )

    # Without min_n_samples: G1 and G2 both non-constant -> viable -> no warning
    testthat::expect_no_warning(
      res_no_samples <-
        select_ft_groups_by_silhouette(
          dist_mat = dist_obj_15,
          hclust_obj = hclust_obj_15,
          ft_groups_min = 2L,
          ft_groups_max = 2L,
          data_community = data_community_15,
          minimal_proportion = 0.05,
          min_n_taxa = 2L,
          min_n_cores = 1L,
          min_n_samples = 1L,
          error_family = "gaussian"
        )
    )

    # With min_n_samples=2: G2 has only 1 sample -> filtered
    # -> n_nc=1 < min_n_taxa=2 -> non-viable -> error
    testthat::expect_error(
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj_15,
        hclust_obj = hclust_obj_15,
        ft_groups_min = 2L,
        ft_groups_max = 2L,
        data_community = data_community_15,
        minimal_proportion = 0.05,
        min_n_taxa = 2L,
        min_n_cores = 1L,
        min_n_samples = 2L,
        error_family = "gaussian"
      ),
      regexp = "No viable"
    )

    testthat::expect_equal(res_no_samples, 2L)
  }
)

