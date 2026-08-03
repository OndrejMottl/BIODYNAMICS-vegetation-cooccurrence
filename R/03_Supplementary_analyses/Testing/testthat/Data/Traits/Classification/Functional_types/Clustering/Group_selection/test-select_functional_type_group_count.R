testthat::test_that(
  "select_functional_type_group_count() rejects non-dist trait_dissimilarity",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_local <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_local, method = "ward.D2")

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = mat_data,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L
      ),
      regexp = "trait_dissimilarity"
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects NULL trait_dissimilarity",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_local <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_local, method = "ward.D2")

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = NULL,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L
      ),
      regexp = "trait_dissimilarity"
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects non-hclust hierarchical_clustering",
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
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = base::list(merge = base::integer(0)),
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L
      ),
      regexp = "hierarchical_clustering"
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects NULL hierarchical_clustering",
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
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = NULL,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L
      ),
      regexp = "hierarchical_clustering"
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects non-integer functional_type_group_count_max",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = "five"
      ),
      regexp = "functional_type_group_count_max"
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects functional_type_group_count_max below 2",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 1L
      ),
      regexp = "functional_type_group_count_max"
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects functional_type_group_count_max of 0L",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 0L
      ),
      regexp = "functional_type_group_count_max"
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects non-integer functional_type_group_count_min",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = "two",
        functional_type_group_count_max = 3L
      ),
      regexp = "functional_type_group_count_min"
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects functional_type_group_count_min below 2",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 1L,
        functional_type_group_count_max = 3L
      ),
      regexp = "functional_type_group_count_min"
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects functional_type_group_count_min > functional_type_group_count_max",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 5L,
        functional_type_group_count_max = 3L
      ),
      regexp = "functional_type_group_count_min"
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() clamps functional_type_group_count_max to n_obs - 1",
  {
    # 6 observations; functional_type_group_count_max = 6L equals n_obs — should be clamped to 5
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0, 6.0),
        nrow = 6L,
        ncol = 1L,
        dimnames = base::list(base::as.character(base::seq_len(6L)), NULL)
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    data_community_fix <-
      tibble::tibble(
        taxon = base::rep(base::as.character(base::seq_len(6L)), 2L),
        dataset_name = base::c(
          base::rep("d1", 6L),
          base::rep("d2", 6L)
        ),
        age = base::rep(1.0, 12L),
        value = base::c(
          base::ifelse(base::seq_len(6L) <= 3L, 0.2, 0.0),
          base::ifelse(base::seq_len(6L) > 3L, 0.2, 0.0)
        )
      )
    res_k <-
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 6L,
        data_community = data_community_fix,
        minimum_proportion = 0.05,
        minimum_taxon_count = 1L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      )

    testthat::expect_type(res_k, "integer")
    testthat::expect_length(res_k, 1L)
    testthat::expect_true(res_k >= 2L && res_k <= 5L)
  }
)


testthat::test_that(
  "select_functional_type_group_count() clamps functional_type_group_count_min for small n_obs",
  {
    # 4 observations; functional_type_group_count_min = 4L would mean functional_type_group_count_min >= n_obs
    # after clamping functional_type_group_count_max to 3L, functional_type_group_count_min should be clamped to 3L
    mat_data <-
      base::matrix(
        base::c(1.0, 10.0, 50.0, 100.0),
        nrow = 4L,
        ncol = 1L,
        dimnames = base::list(base::as.character(base::seq_len(4L)), NULL)
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    data_community_fix <-
      tibble::tibble(
        taxon = base::rep(base::as.character(base::seq_len(4L)), 2L),
        dataset_name = base::c(
          base::rep("d1", 4L),
          base::rep("d2", 4L)
        ),
        age = base::rep(1.0, 8L),
        value = base::c(
          base::ifelse(base::seq_len(4L) <= 2L, 0.2, 0.0),
          base::ifelse(base::seq_len(4L) > 2L, 0.2, 0.0)
        )
      )
    res_k <-
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 4L,
        functional_type_group_count_max = 6L,
        data_community = data_community_fix,
        minimum_proportion = 0.05,
        minimum_taxon_count = 1L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      )

    testthat::expect_type(res_k, "integer")
    testthat::expect_length(res_k, 1L)
    testthat::expect_true(res_k >= 2L && res_k <= 3L)
  }
)


testthat::test_that(
  "select_functional_type_group_count() returns an integer type",
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
      compute_trait_dissimilarity(data_trait_table = data_traits)

    hierarchical_clustering <-
      fit_hierarchical_clustering(trait_dissimilarity = dist_obj)

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
        value = base::c(
          base::ifelse(base::seq_len(10L) <= 5L, 0.2, 0.0),
          base::ifelse(base::seq_len(10L) > 5L, 0.2, 0.0)
        )
      )
    res_k <-
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 5L,
        data_community = data_community_fix,
        minimum_proportion = 0.05,
        minimum_taxon_count = 1L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      )

    testthat::expect_type(res_k, "integer")
  }
)


testthat::test_that(
  "select_functional_type_group_count() returns a length-1 scalar",
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
      compute_trait_dissimilarity(data_trait_table = data_traits)

    hierarchical_clustering <-
      fit_hierarchical_clustering(trait_dissimilarity = dist_obj)

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
        value = base::c(
          base::ifelse(base::seq_len(10L) <= 5L, 0.2, 0.0),
          base::ifelse(base::seq_len(10L) > 5L, 0.2, 0.0)
        )
      )
    res_k <-
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 5L,
        data_community = data_community_fix,
        minimum_proportion = 0.05,
        minimum_taxon_count = 1L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      )

    testthat::expect_length(res_k, 1L)
  }
)


testthat::test_that(
  "select_functional_type_group_count() picks 2 groups for clear two groups",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(10L)),
        trait_1 = base::c(
          0.08, 0.10, 0.11, 0.09, 0.12, 0.88, 0.90, 0.91, 0.89, 0.92
        )
      )

    dist_obj <-
      compute_trait_dissimilarity(data_trait_table = data_traits)

    hierarchical_clustering <-
      fit_hierarchical_clustering(trait_dissimilarity = dist_obj)

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
        value = base::c(
          base::ifelse(base::seq_len(10L) <= 5L, 0.2, 0.0),
          base::ifelse(base::seq_len(10L) > 5L, 0.2, 0.0)
        )
      )
    res_k <-
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 5L,
        data_community = data_community_fix,
        minimum_proportion = 0.05,
        minimum_taxon_count = 1L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      )

    testthat::expect_equal(res_k, 2L)
  }
)


testthat::test_that(
  "select_functional_type_group_count() returns value within ft_groups range",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(8L)),
        trait_1 = base::c(
          0.1, 0.2, 0.3, 0.4, 0.6, 0.7, 0.8, 0.9
        )
      )

    dist_obj <-
      compute_trait_dissimilarity(data_trait_table = data_traits)

    hierarchical_clustering <-
      fit_hierarchical_clustering(trait_dissimilarity = dist_obj)

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
        value = base::c(
          base::ifelse(base::seq_len(8L) <= 4L, 0.2, 0.0),
          base::ifelse(base::seq_len(8L) > 4L, 0.2, 0.0)
        )
      )
    res_k <-
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 4L,
        data_community = data_community_fix,
        minimum_proportion = 0.05,
        minimum_taxon_count = 1L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      )

    testthat::expect_true(res_k >= 2L && res_k <= 4L)
  }
)


testthat::test_that(
  "select_functional_type_group_count() returns min for single-value sweep",
  {
    # functional_type_group_count_min = functional_type_group_count_max = 2L: only one value to compare, must return 2
    data_traits <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(10L)),
        trait_1 = base::c(
          0.01, 0.02, 0.01, 0.02, 0.01,
          0.99, 0.98, 0.99, 0.98, 0.99
        )
      )

    dist_obj <-
      compute_trait_dissimilarity(data_trait_table = data_traits)

    hierarchical_clustering <-
      fit_hierarchical_clustering(trait_dissimilarity = dist_obj)

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
        value = base::c(
          base::ifelse(base::seq_len(10L) <= 5L, 0.2, 0.0),
          base::ifelse(base::seq_len(10L) > 5L, 0.2, 0.0)
        )
      )
    res_k <-
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 2L,
        data_community = data_community_fix,
        minimum_proportion = 0.05,
        minimum_taxon_count = 1L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      )

    testthat::expect_equal(res_k, 2L)
  }
)


testthat::test_that(
  "select_functional_type_group_count() handles a 30-taxon dataset",
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
      compute_trait_dissimilarity(data_trait_table = data_traits)

    hierarchical_clustering <-
      fit_hierarchical_clustering(trait_dissimilarity = dist_obj)

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
        value = base::c(
          base::ifelse(base::seq_len(30L) <= 15L, 0.2, 0.0),
          base::ifelse(base::seq_len(30L) > 15L, 0.2, 0.0)
        )
      )
    res_k <-
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 8L,
        data_community = data_community_fix,
        minimum_proportion = 0.05,
        minimum_taxon_count = 1L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      )

    testthat::expect_type(res_k, "integer")
    testthat::expect_length(res_k, 1L)
    testthat::expect_true(res_k >= 2L && res_k <= 8L)
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects non-data.frame data_community",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L,
        data_community = base::c("sp_1", "sp_2"),
        minimum_proportion = 0.1,
        minimum_taxon_count = 2L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      ),
      regexp = "data_community"
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects data_community missing value",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    data_community_no_pollen <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0
      )

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L,
        data_community = data_community_no_pollen,
        minimum_proportion = 0.1,
        minimum_taxon_count = 2L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      ),
      regexp = "data_community"
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects minimum_proportion >= 1",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    data_community_minimal <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0,
        value = 0.5
      )

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L,
        data_community = data_community_minimal,
        minimum_proportion = 1.5,
        minimum_taxon_count = 2L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      )
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects minimum_proportion = 0",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    data_community_minimal <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0,
        value = 0.5
      )

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L,
        data_community = data_community_minimal,
        minimum_proportion = 0,
        minimum_taxon_count = 2L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      )
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects minimum_taxon_count = 0",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    data_community_minimal <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0,
        value = 0.5
      )

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L,
        data_community = data_community_minimal,
        minimum_proportion = 0.1,
        minimum_taxon_count = 0L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      )
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() skips best-silhouette k if non-viable",
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
      compute_trait_dissimilarity(data_trait_table = data_traits_9)

    hclust_obj_9 <-
      fit_hierarchical_clustering(trait_dissimilarity = dist_obj_9)

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
        value = base::c(
          0.20, 0.20, 0.20, 0.20, 0.20, 0.00,
          0.20, 0.20, 0.20, 0.20, 0.20, 0.00,
          0.20, 0.20, 0.20, 0.20, 0.00, 0.20,
          0.20, 0.20, 0.20, 0.20, 0.00, 0.20
        )
      )

    res_viability <-
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj_9,
        hierarchical_clustering = hclust_obj_9,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L,
        data_community = data_community_9,
        minimum_proportion = 0.10,
        minimum_taxon_count = 2L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      )

    testthat::expect_equal(res_viability, 3L)
  }
)


testthat::test_that(
  "select_functional_type_group_count() errors when no k is viable",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(8L)),
        trait_1 = base::c(
          0.10, 0.10, 0.10, 0.10, 0.88, 0.88, 0.92, 0.92
        )
      )

    dist_obj <-
      compute_trait_dissimilarity(data_trait_table = data_traits)

    hierarchical_clustering <-
      fit_hierarchical_clustering(trait_dissimilarity = dist_obj)

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
        value = base::rep(0.20, times = 32L)
      )

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L,
        data_community = data_community_10,
        minimum_proportion = 0.10,
        minimum_taxon_count = 3L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      ),
      regexp = "No viable"
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() returns same k when best k is viable",
  {
    # Same 6-taxon design: sp_1..sp_4 at 0.01, sp_5..sp_6 at 0.99
    # k=2 silhouette = 1.0 (max), k=3 = 0.33 -> k=2 wins.
    # Community: G2={sp_5,sp_6} absent in samples 3,4 -> non-constant
    # -> k=2 is viable with minimum_taxon_count=1.
    # With viability k=2 is still selected (same as without).
    data_traits_11 <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(6L)),
        trait_1 = base::c(
          0.01, 0.01, 0.01, 0.01, 0.99, 0.99
        )
      )

    dist_obj_11 <-
      compute_trait_dissimilarity(data_trait_table = data_traits_11)

    hclust_obj_11 <-
      fit_hierarchical_clustering(trait_dissimilarity = dist_obj_11)

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
        value = base::c(
          0.20, 0.20, 0.20, 0.20, 0.20, 0.20,
          0.20, 0.20, 0.20, 0.20, 0.20, 0.20,
          0.20, 0.20, 0.20, 0.20, 0.00, 0.00,
          0.20, 0.20, 0.20, 0.20, 0.00, 0.00
        )
      )

    res_viability <-
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj_11,
        hierarchical_clustering = hclust_obj_11,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L,
        data_community = data_community_11,
        minimum_proportion = 0.10,
        minimum_taxon_count = 1L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      )

    testthat::expect_equal(res_viability, 2L)
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects non-integer minimum_core_count",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    data_community_minimal <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0,
        value = 0.5
      )

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L,
        data_community = data_community_minimal,
        minimum_proportion = 0.1,
        minimum_taxon_count = 2L,
        minimum_core_count = "five",
        minimum_sample_count = 1L,
        error_family = "gaussian"
      ),
      regexp = "minimum_core_count"
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects minimum_core_count less than 1",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    data_community_minimal <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0,
        value = 0.5
      )

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L,
        data_community = data_community_minimal,
        minimum_proportion = 0.1,
        minimum_taxon_count = 2L,
        minimum_core_count = 0L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      ),
      regexp = "minimum_core_count"
    )
  }
)


testthat::test_that(
  "group-count selection applies the minimum core count",
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
    # Without minimum_core_count (minimum_taxon_count=2):
    #   k=2: G2={sp5..sp8} non-constant, n_nc=1 < 2 -> non-viable
    #   k=3: G2={sp5,6} non-constant AND G3={sp7,8} non-constant -> n_nc=2 >= 2
    #        -> viable -> k=3 selected
    #
    # With minimum_core_count=2 (minimum_taxon_count=2):
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
      compute_trait_dissimilarity(data_trait_table = data_traits_12)

    hclust_obj_12 <-
      fit_hierarchical_clustering(trait_dissimilarity = dist_obj_12)

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
        value = base::c(
          0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.15,
          0.15, 0.15, 0.15, 0.15, 0.15, 0.15, 0.00, 0.00,
          0.15, 0.15, 0.15, 0.15, 0.00, 0.00, 0.00, 0.00
        )
      )

    # With one required core, k = 3 remains viable.
    res_no_cores <-
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj_12,
        hierarchical_clustering = hclust_obj_12,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L,
        data_community = data_community_12,
        minimum_proportion = 0.05,
        minimum_taxon_count = 2L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      )

    # With minimum_core_count=2: both k=2 and k=3 non-viable -> error
    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj_12,
        hierarchical_clustering = hclust_obj_12,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L,
        data_community = data_community_12,
        minimum_proportion = 0.05,
        minimum_taxon_count = 2L,
        minimum_core_count = 2L,
        minimum_sample_count = 1L,
        error_family = "gaussian"
      ),
      regexp = "No viable"
    )

    testthat::expect_equal(res_no_cores, 3L)
  }
)


testthat::test_that(
  "group-count selection rejects non-integer sample counts",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    data_community_minimal <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0,
        value = 0.5
      )

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L,
        data_community = data_community_minimal,
        minimum_proportion = 0.1,
        minimum_taxon_count = 1L,
        minimum_core_count = 1L,
        minimum_sample_count = "five",
        error_family = "gaussian"
      ),
      regexp = "minimum_sample_count"
    )
  }
)


testthat::test_that(
  "group-count selection rejects sample counts below one",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    data_community_minimal <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0,
        value = 0.5
      )

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L,
        data_community = data_community_minimal,
        minimum_proportion = 0.1,
        minimum_taxon_count = 1L,
        minimum_core_count = 1L,
        minimum_sample_count = 0L,
        error_family = "gaussian"
      ),
      regexp = "minimum_sample_count"
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() rejects non-character error_family",
  {
    mat_data <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_obj <-
      stats::dist(mat_data)

    hierarchical_clustering <-
      stats::hclust(dist_obj, method = "ward.D2")

    data_community_minimal <-
      tibble::tibble(
        taxon = "sp_1",
        dataset_name = "d1",
        age = 1.0,
        value = 0.5
      )

    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj,
        hierarchical_clustering = hierarchical_clustering,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 3L,
        data_community = data_community_minimal,
        minimum_proportion = 0.1,
        minimum_taxon_count = 1L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = 42L
      ),
      regexp = "error_family"
    )
  }
)


testthat::test_that(
  "select_functional_type_group_count() binomial binarisation groups constant",
  {
    # 4 taxa in 2 trait clusters:
    #   G1 = {sp_1, sp_2}: trait 0.01 — present in d1 only (sometimes absent)
    #   G2 = {sp_3, sp_4}: trait 0.99 — always present at varying proportions
    #                                    all above minimum_proportion
    #
    # FT-level community (k=2, functional_type_group_count_min = functional_type_group_count_max = 2):
    #
    #   G1 sums: (d1,1)=0.20, (d1,2)=0.20, (d2,1)=0.00, (d2,2)=0.00
    #   G2 sums: (d1,1)=0.20, (d1,2)=0.24, (d2,1)=0.16, (d2,2)=0.18
    #
    # Without error_family (no binarisation):
    #   G1 col: [0.20, 0.20, 0, 0]      -> non-constant -> counted
    #   G2 col: [0.20, 0.24, 0.16, 0.18] -> non-constant -> counted
    #   n_nc = 2 >= minimum_taxon_count=2 -> viable -> NO warning
    #
    # With error_family="binomial":
    #   G1 binarised: [1, 1, 0, 0]  -> non-constant -> counted
    #   G2 binarised: [1, 1, 1, 1]  -> constant     -> removed
    #   n_nc = 1 < minimum_taxon_count=2     -> non-viable   -> WARNING
    data_traits_14 <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(4L)),
        trait_1 = base::c(0.01, 0.01, 0.99, 0.99)
      )

    dist_obj_14 <-
      compute_trait_dissimilarity(data_trait_table = data_traits_14)

    hclust_obj_14 <-
      fit_hierarchical_clustering(trait_dissimilarity = dist_obj_14)

    # 2 cores x 2 ages = 4 samples; sp_1,sp_2 absent in d2; sp_3,sp_4 always
    # present at varying proportions all above minimum_proportion=0.05.
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
        value = base::c(
          0.10, 0.10, 0.10, 0.10,
          0.10, 0.10, 0.12, 0.12,
          0.00, 0.00, 0.08, 0.08,
          0.00, 0.00, 0.09, 0.09
        )
      )

    # Without error_family: G1 and G2 both non-constant -> viable -> no warning
    testthat::expect_no_warning(
      res_no_family <-
        select_functional_type_group_count(
          trait_dissimilarity = dist_obj_14,
          hierarchical_clustering = hclust_obj_14,
          functional_type_group_count_min = 2L,
          functional_type_group_count_max = 2L,
          data_community = data_community_14,
          minimum_proportion = 0.05,
          minimum_taxon_count = 2L,
          minimum_core_count = 1L,
          minimum_sample_count = 1L,
          error_family = "gaussian"
        )
    )

    # With error_family="binomial": G2 binarises to all-1 -> constant
    # -> n_nc=1 < minimum_taxon_count=2 -> non-viable -> error
    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj_14,
        hierarchical_clustering = hclust_obj_14,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 2L,
        data_community = data_community_14,
        minimum_proportion = 0.05,
        minimum_taxon_count = 2L,
        minimum_core_count = 1L,
        minimum_sample_count = 1L,
        error_family = "binomial"
      ),
      regexp = "No viable"
    )

    testthat::expect_equal(res_no_family, 2L)
  }
)


testthat::test_that(
  "group-count selection applies the minimum sample count",
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
    #   G2: (d1,1)=0.20 only — rest 0.00 -> removed by proportion filter
    #
    # data_sample_ids (common to both branches): {(d1,1),(d1,2),(d2,1),(d2,2)}
    #
    # Without minimum_sample_count (minimum_taxon_count=2):
    #   Matrix: G1=[0.20,0.24,0.16,0.18] non-constant;
    #           G2=[0.20,0,0,0] non-constant
    #   n_nc=2 >= 2 -> viable -> NO warning
    #
    # With minimum_sample_count=2:
    #   G2 has only 1 distinct sample -> minimum sample filter removes it
    #   n_nc=1 < minimum_taxon_count=2 -> non-viable -> WARNING
    data_traits_15 <-
      tibble::tibble(
        taxon_name = stringr::str_c("sp_", base::seq_len(4L)),
        trait_1 = base::c(0.01, 0.01, 0.99, 0.99)
      )

    dist_obj_15 <-
      compute_trait_dissimilarity(data_trait_table = data_traits_15)

    hclust_obj_15 <-
      fit_hierarchical_clustering(trait_dissimilarity = dist_obj_15)

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
        value = base::c(
          0.10, 0.10, 0.10, 0.10,
          0.12, 0.12, 0.00, 0.00,
          0.08, 0.08, 0.00, 0.00,
          0.09, 0.09, 0.00, 0.00
        )
      )

    # With one required sample, G1 and G2 remain viable.
    testthat::expect_no_warning(
      res_no_samples <-
        select_functional_type_group_count(
          trait_dissimilarity = dist_obj_15,
          hierarchical_clustering = hclust_obj_15,
          functional_type_group_count_min = 2L,
          functional_type_group_count_max = 2L,
          data_community = data_community_15,
          minimum_proportion = 0.05,
          minimum_taxon_count = 2L,
          minimum_core_count = 1L,
          minimum_sample_count = 1L,
          error_family = "gaussian"
        )
    )

    # With minimum_sample_count=2: G2 has only 1 sample -> filtered
    # -> n_nc=1 < minimum_taxon_count=2 -> non-viable -> error
    testthat::expect_error(
      select_functional_type_group_count(
        trait_dissimilarity = dist_obj_15,
        hierarchical_clustering = hclust_obj_15,
        functional_type_group_count_min = 2L,
        functional_type_group_count_max = 2L,
        data_community = data_community_15,
        minimum_proportion = 0.05,
        minimum_taxon_count = 2L,
        minimum_core_count = 1L,
        minimum_sample_count = 2L,
        error_family = "gaussian"
      ),
      regexp = "No viable"
    )

    testthat::expect_equal(res_no_samples, 2L)
  }
)
