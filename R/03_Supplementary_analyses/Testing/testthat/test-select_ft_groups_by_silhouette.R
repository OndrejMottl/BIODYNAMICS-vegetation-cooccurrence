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
          0.08, 0.10, 0.11, 0.09, 0.12, 0.88, 0.90, 0.91, 0.89, 0.92
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


testthat::test_that(
  "NULL optional args give same result as omitting them",
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

    res_default <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 5L
      )

    res_explicit_null <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj,
        hclust_obj = hclust_obj,
        ft_groups_min = 2L,
        ft_groups_max = 5L,
        data_community = NULL,
        minimal_proportion = NULL,
        min_n_taxa = NULL
      )

    testthat::expect_equal(res_explicit_null, res_default)
    testthat::expect_type(res_explicit_null, "integer")
  }
)


testthat::test_that(
  "data_community without minimal_proportion errors",
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

    data_comm <-
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
        data_community = data_comm,
        minimal_proportion = NULL,
        min_n_taxa = 2L
      ),
      regexp = "minimal_proportion"
    )
  }
)


testthat::test_that(
  "data_community without min_n_taxa errors",
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

    data_comm <-
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
        data_community = data_comm,
        minimal_proportion = 0.1,
        min_n_taxa = NULL
      ),
      regexp = "min_n_taxa"
    )
  }
)


testthat::test_that(
  "non-data.frame data_community gives an error",
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
        min_n_taxa = 2L
      ),
      regexp = "data_community"
    )
  }
)


testthat::test_that(
  "data_community missing pollen_prop column gives an error",
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

    data_comm_no_pollen <-
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
        data_community = data_comm_no_pollen,
        minimal_proportion = 0.1,
        min_n_taxa = 2L
      ),
      regexp = "data_community"
    )
  }
)


testthat::test_that(
  "minimal_proportion >= 1 gives an error",
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

    data_comm <-
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
        data_community = data_comm,
        minimal_proportion = 1.5,
        min_n_taxa = 2L
      )
    )
  }
)


testthat::test_that(
  "minimal_proportion = 0 gives an error",
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

    data_comm <-
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
        data_community = data_comm,
        minimal_proportion = 0,
        min_n_taxa = 2L
      )
    )
  }
)


testthat::test_that(
  "min_n_taxa = 0 gives an error",
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

    data_comm <-
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
        data_community = data_comm,
        minimal_proportion = 0.1,
        min_n_taxa = 0L
      )
    )
  }
)


testthat::test_that(
  "viability skips best-silhouette k if non-viable",
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

    res_no_viability <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj_9,
        hclust_obj = hclust_obj_9,
        ft_groups_min = 2L,
        ft_groups_max = 3L
      )

    testthat::expect_equal(res_no_viability, 2L)

    res_viability <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj_9,
        hclust_obj = hclust_obj_9,
        ft_groups_min = 2L,
        ft_groups_max = 3L,
        data_community = data_community_9,
        minimal_proportion = 0.10,
        min_n_taxa = 2L
      )

    testthat::expect_equal(res_viability, 3L)
  }
)


testthat::test_that(
  "viability warns when no k is viable",
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

    res_warn <-
      testthat::expect_warning(
        select_ft_groups_by_silhouette(
          dist_mat = dist_obj,
          hclust_obj = hclust_obj,
          ft_groups_min = 2L,
          ft_groups_max = 3L,
          data_community = data_community_10,
          minimal_proportion = 0.10,
          min_n_taxa = 3L
        )
      )

    testthat::expect_type(res_warn, "integer")
    testthat::expect_length(res_warn, 1L)
  }
)


testthat::test_that(
  "viability returns same k when best-silhouette k is viable",
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

    res_no_viability <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj_11,
        hclust_obj = hclust_obj_11,
        ft_groups_min = 2L,
        ft_groups_max = 3L
      )

    res_viability <-
      select_ft_groups_by_silhouette(
        dist_mat = dist_obj_11,
        hclust_obj = hclust_obj_11,
        ft_groups_min = 2L,
        ft_groups_max = 3L,
        data_community = data_community_11,
        minimal_proportion = 0.10,
        min_n_taxa = 1L
      )

    testthat::expect_equal(res_no_viability, 2L)
    testthat::expect_equal(res_viability, res_no_viability)
  }
)
