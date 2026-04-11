testthat::test_that(
  "cluster_functional_types() errors when data is not a data frame",
  {
    mat_dummy <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_dummy <-
      stats::dist(mat_dummy)

    hclust_dummy <-
      stats::hclust(dist_dummy, method = "ward.D2")

    testthat::expect_error(
      cluster_functional_types(
        data = "not_a_data_frame",
        dist_gower = dist_dummy,
        hclust_obj = hclust_dummy,
        k = 2L
      )
    )
  }
)


testthat::test_that(
  "cluster_functional_types() errors when data has fewer than 4 rows",
  {
    data_small <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        sla = base::c(1.0, 2.0, 3.0)
      )

    mat_dummy <-
      base::matrix(
        base::c(1.0, 2.0, 3.0),
        nrow = 3L,
        ncol = 1L
      )

    dist_dummy <-
      stats::dist(mat_dummy)

    hclust_dummy <-
      stats::hclust(dist_dummy, method = "ward.D2")

    testthat::expect_error(
      cluster_functional_types(
        data = data_small,
        dist_gower = dist_dummy,
        hclust_obj = hclust_dummy,
        k = 2L
      )
    )
  }
)


testthat::test_that(
  "cluster_functional_types() errors when taxon_col is not character",
  {
    data_min <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(1.0, 2.0, 3.0, 4.0, 5.0)
      )

    dist_min <-
      compute_gower_distance(data_min)

    hclust_min <-
      fit_hclust(dist_min)

    testthat::expect_error(
      cluster_functional_types(
        data = data_min,
        dist_gower = dist_min,
        hclust_obj = hclust_min,
        k = 2L,
        taxon_col = 1L
      )
    )
  }
)


testthat::test_that(
  "cluster_functional_types() errors when taxon_col has length > 1",
  {
    data_min <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(1.0, 2.0, 3.0, 4.0, 5.0)
      )

    dist_min <-
      compute_gower_distance(data_min)

    hclust_min <-
      fit_hclust(dist_min)

    testthat::expect_error(
      cluster_functional_types(
        data = data_min,
        dist_gower = dist_min,
        hclust_obj = hclust_min,
        k = 2L,
        taxon_col = base::c("taxon_name", "sla")
      )
    )
  }
)


testthat::test_that(
  "cluster_functional_types() errors when taxon_col not in data",
  {
    data_species <-
      tibble::tibble(
        species = base::c("A", "B", "C", "D", "E"),
        sla = base::c(1.0, 2.0, 3.0, 4.0, 5.0)
      )

    mat_dummy <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_dummy <-
      stats::dist(mat_dummy)

    hclust_dummy <-
      stats::hclust(dist_dummy, method = "ward.D2")

    testthat::expect_error(
      cluster_functional_types(
        data = data_species,
        dist_gower = dist_dummy,
        hclust_obj = hclust_dummy,
        k = 2L,
        taxon_col = "taxon_name"
      )
    )
  }
)


testthat::test_that(
  "cluster_functional_types() errors when dist_gower not a dist obj",
  {
    data_min <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(1.0, 2.0, 3.0, 4.0, 5.0)
      )

    mat_dummy <-
      base::matrix(
        base::c(1.0, 2.0, 3.0, 4.0, 5.0),
        nrow = 5L,
        ncol = 1L
      )

    dist_dummy <-
      stats::dist(mat_dummy)

    hclust_dummy <-
      stats::hclust(dist_dummy, method = "ward.D2")

    testthat::expect_error(
      cluster_functional_types(
        data = data_min,
        dist_gower = mat_dummy,
        hclust_obj = hclust_dummy,
        k = 2L
      )
    )
  }
)


testthat::test_that(
  "cluster_functional_types() errors when hclust_obj not hclust",
  {
    data_min <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(1.0, 2.0, 3.0, 4.0, 5.0)
      )

    dist_min <-
      compute_gower_distance(data_min)

    testthat::expect_error(
      cluster_functional_types(
        data = data_min,
        dist_gower = dist_min,
        hclust_obj = base::list(a = 1),
        k = 2L
      )
    )
  }
)


testthat::test_that(
  "cluster_functional_types() errors when k not numeric",
  {
    data_min <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(1.0, 2.0, 3.0, 4.0, 5.0)
      )

    dist_min <-
      compute_gower_distance(data_min)

    hclust_min <-
      fit_hclust(dist_min)

    testthat::expect_error(
      cluster_functional_types(
        data = data_min,
        dist_gower = dist_min,
        hclust_obj = hclust_min,
        k = "10"
      )
    )
  }
)


testthat::test_that(
  "cluster_functional_types() errors when k < 2",
  {
    data_min <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(1.0, 2.0, 3.0, 4.0, 5.0)
      )

    dist_min <-
      compute_gower_distance(data_min)

    hclust_min <-
      fit_hclust(dist_min)

    testthat::expect_error(
      cluster_functional_types(
        data = data_min,
        dist_gower = dist_min,
        hclust_obj = hclust_min,
        k = 1L
      )
    )
  }
)


testthat::test_that(
  "cluster_functional_types() errors when k >= nrow(data)",
  {
    data_min <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(1.0, 2.0, 3.0, 4.0, 5.0)
      )

    dist_min <-
      compute_gower_distance(data_min)

    hclust_min <-
      fit_hclust(dist_min)

    testthat::expect_error(
      cluster_functional_types(
        data = data_min,
        dist_gower = dist_min,
        hclust_obj = hclust_min,
        k = 5L
      )
    )
  }
)


testthat::test_that(
  "cluster_functional_types() errors when verbose not logical",
  {
    data_min <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(1.0, 2.0, 3.0, 4.0, 5.0)
      )

    dist_min <-
      compute_gower_distance(data_min)

    hclust_min <-
      fit_hclust(dist_min)

    testthat::expect_error(
      cluster_functional_types(
        data = data_min,
        dist_gower = dist_min,
        hclust_obj = hclust_min,
        k = 2L,
        verbose = "yes"
      )
    )
  }
)


testthat::test_that(
  "cluster_functional_types() errors when verbose has length > 1",
  {
    data_min <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(1.0, 2.0, 3.0, 4.0, 5.0)
      )

    dist_min <-
      compute_gower_distance(data_min)

    hclust_min <-
      fit_hclust(dist_min)

    testthat::expect_error(
      cluster_functional_types(
        data = data_min,
        dist_gower = dist_min,
        hclust_obj = hclust_min,
        k = 2L,
        verbose = base::c(TRUE, FALSE)
      )
    )
  }
)


testthat::test_that(
  "cluster_functional_types() returns a tibble directly",
  {
    base::set.seed(900723)

    data_two_groups <-
      tibble::tibble(
        taxon_name = base::c(
          "sp_a1", "sp_a2", "sp_a3", "sp_a4", "sp_a5",
          "sp_b1", "sp_b2", "sp_b3", "sp_b4", "sp_b5"
        ),
        sla = base::c(
          1.0, 1.1, 0.9, 1.2, 1.0,
          50.0, 51.0, 49.0, 50.5, 50.2
        )
      )

    dist_two_groups <-
      compute_gower_distance(data_two_groups)

    hclust_two_groups <-
      fit_hclust(dist_two_groups)

    res <-
      cluster_functional_types(
        data = data_two_groups,
        dist_gower = dist_two_groups,
        hclust_obj = hclust_two_groups,
        k = 2L,
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "tbl_df")
  }
)


testthat::test_that(
  "cluster_functional_types() classification element is a tibble with 3 cols",
  {
    base::set.seed(900723)

    data_two_groups <-
      tibble::tibble(
        taxon_name = base::c(
          "sp_a1", "sp_a2", "sp_a3", "sp_a4", "sp_a5",
          "sp_b1", "sp_b2", "sp_b3", "sp_b4", "sp_b5"
        ),
        sla = base::c(
          1.0, 1.1, 0.9, 1.2, 1.0,
          50.0, 51.0, 49.0, 50.5, 50.2
        )
      )

    dist_two_groups <-
      compute_gower_distance(data_two_groups)

    hclust_two_groups <-
      fit_hclust(dist_two_groups)

    res <-
      cluster_functional_types(
        data = data_two_groups,
        dist_gower = dist_two_groups,
        hclust_obj = hclust_two_groups,
        k = 2L,
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(base::ncol(res), 3L)
  }
)


testthat::test_that(
  "cluster_functional_types() classification has expected column names",
  {
    base::set.seed(900723)

    data_two_groups <-
      tibble::tibble(
        taxon_name = base::c(
          "sp_a1", "sp_a2", "sp_a3", "sp_a4", "sp_a5",
          "sp_b1", "sp_b2", "sp_b3", "sp_b4", "sp_b5"
        ),
        sla = base::c(
          1.0, 1.1, 0.9, 1.2, 1.0,
          50.0, 51.0, 49.0, 50.5, 50.2
        )
      )

    dist_two_groups <-
      compute_gower_distance(data_two_groups)

    hclust_two_groups <-
      fit_hclust(dist_two_groups)

    res <-
      cluster_functional_types(
        data = data_two_groups,
        dist_gower = dist_two_groups,
        hclust_obj = hclust_two_groups,
        k = 2L,
        verbose = FALSE
      )

    vec_expected_columns <-
      base::c(
        "taxon_name", "functional_type", "silhouette_width"
      )

    testthat::expect_named(
      res,
      vec_expected_columns
    )
  }
)


testthat::test_that(
  "cluster_functional_types() functional_type is integer type",
  {
    base::set.seed(900723)

    data_two_groups <-
      tibble::tibble(
        taxon_name = base::c(
          "sp_a1", "sp_a2", "sp_a3", "sp_a4", "sp_a5",
          "sp_b1", "sp_b2", "sp_b3", "sp_b4", "sp_b5"
        ),
        sla = base::c(
          1.0, 1.1, 0.9, 1.2, 1.0,
          50.0, 51.0, 49.0, 50.5, 50.2
        )
      )

    dist_two_groups <-
      compute_gower_distance(data_two_groups)

    hclust_two_groups <-
      fit_hclust(dist_two_groups)

    res <-
      cluster_functional_types(
        data = data_two_groups,
        dist_gower = dist_two_groups,
        hclust_obj = hclust_two_groups,
        k = 2L,
        verbose = FALSE
      )

    vec_functional_type <-
      dplyr::pull(
        res,
        functional_type
      )

    testthat::expect_type(vec_functional_type, "integer")
  }
)


testthat::test_that(
  "cluster_functional_types() silhouette_width is double type",
  {
    base::set.seed(900723)

    data_two_groups <-
      tibble::tibble(
        taxon_name = base::c(
          "sp_a1", "sp_a2", "sp_a3", "sp_a4", "sp_a5",
          "sp_b1", "sp_b2", "sp_b3", "sp_b4", "sp_b5"
        ),
        sla = base::c(
          1.0, 1.1, 0.9, 1.2, 1.0,
          50.0, 51.0, 49.0, 50.5, 50.2
        )
      )

    dist_two_groups <-
      compute_gower_distance(data_two_groups)

    hclust_two_groups <-
      fit_hclust(dist_two_groups)

    res <-
      cluster_functional_types(
        data = data_two_groups,
        dist_gower = dist_two_groups,
        hclust_obj = hclust_two_groups,
        k = 2L,
        verbose = FALSE
      )

    vec_silhouette_width <-
      dplyr::pull(
        res,
        silhouette_width
      )

    testthat::expect_type(vec_silhouette_width, "double")
  }
)


testthat::test_that(
  "cluster_functional_types() taxon_name matches input taxon names",
  {
    base::set.seed(900723)

    data_two_groups <-
      tibble::tibble(
        taxon_name = base::c(
          "sp_a1", "sp_a2", "sp_a3", "sp_a4", "sp_a5",
          "sp_b1", "sp_b2", "sp_b3", "sp_b4", "sp_b5"
        ),
        sla = base::c(
          1.0, 1.1, 0.9, 1.2, 1.0,
          50.0, 51.0, 49.0, 50.5, 50.2
        )
      )

    dist_two_groups <-
      compute_gower_distance(data_two_groups)

    hclust_two_groups <-
      fit_hclust(dist_two_groups)

    res <-
      cluster_functional_types(
        data = data_two_groups,
        dist_gower = dist_two_groups,
        hclust_obj = hclust_two_groups,
        k = 2L,
        verbose = FALSE
      )

    vec_taxon_names <-
      dplyr::pull(
        res,
        taxon_name
      )

    vec_expected_names <-
      dplyr::pull(data_two_groups, taxon_name)

    testthat::expect_equal(vec_taxon_names, vec_expected_names)
  }
)


testthat::test_that(
  "cluster_functional_types() taxon_col arg yields taxon_name col",
  {
    base::set.seed(900723)

    data_species <-
      tibble::tibble(
        species = base::c(
          "sp_a1", "sp_a2", "sp_a3", "sp_a4", "sp_a5",
          "sp_b1", "sp_b2", "sp_b3", "sp_b4", "sp_b5"
        ),
        sla = base::c(
          1.0, 1.1, 0.9, 1.2, 1.0,
          50.0, 51.0, 49.0, 50.5, 50.2
        )
      )

    dist_species <-
      compute_gower_distance(
        data = data_species,
        taxon_col = "species"
      )

    hclust_species <-
      fit_hclust(dist_species)

    res <-
      cluster_functional_types(
        data = data_species,
        dist_gower = dist_species,
        hclust_obj = hclust_species,
        k = 2L,
        taxon_col = "species",
        verbose = FALSE
      )

    testthat::expect_true(
      "taxon_name" %in%
        base::colnames(res)
    )

    testthat::expect_false(
      "species" %in%
        base::colnames(res)
    )
  }
)


testthat::test_that(
  "cluster_functional_types() verbose=FALSE suppresses messages",
  {
    base::set.seed(900723)

    data_two_groups <-
      tibble::tibble(
        taxon_name = base::c(
          "sp_a1", "sp_a2", "sp_a3", "sp_a4", "sp_a5",
          "sp_b1", "sp_b2", "sp_b3", "sp_b4", "sp_b5"
        ),
        sla = base::c(
          1.0, 1.1, 0.9, 1.2, 1.0,
          50.0, 51.0, 49.0, 50.5, 50.2
        )
      )

    dist_two_groups <-
      compute_gower_distance(data_two_groups)

    hclust_two_groups <-
      fit_hclust(dist_two_groups)

    testthat::expect_no_message(
      cluster_functional_types(
        data = data_two_groups,
        dist_gower = dist_two_groups,
        hclust_obj = hclust_two_groups,
        k = 2L,
        verbose = FALSE
      )
    )
  }
)


testthat::test_that(
  "cluster_functional_types() verbose=TRUE produces a message",
  {
    base::set.seed(900723)

    data_two_groups <-
      tibble::tibble(
        taxon_name = base::c(
          "sp_a1", "sp_a2", "sp_a3", "sp_a4", "sp_a5",
          "sp_b1", "sp_b2", "sp_b3", "sp_b4", "sp_b5"
        ),
        sla = base::c(
          1.0, 1.1, 0.9, 1.2, 1.0,
          50.0, 51.0, 49.0, 50.5, 50.2
        )
      )

    dist_two_groups <-
      compute_gower_distance(data_two_groups)

    hclust_two_groups <-
      fit_hclust(dist_two_groups)

    testthat::expect_message(
      cluster_functional_types(
        data = data_two_groups,
        dist_gower = dist_two_groups,
        hclust_obj = hclust_two_groups,
        k = 2L,
        verbose = TRUE
      )
    )
  }
)