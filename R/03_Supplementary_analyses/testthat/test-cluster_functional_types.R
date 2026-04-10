testthat::test_that(
  "cluster_functional_types() errors on non-data-frame",
  {
    testthat::expect_error(
      cluster_functional_types(data = "not_a_df")
    )
    testthat::expect_error(
      cluster_functional_types(
        data = base::list(a = 1, b = 2)
      )
    )
    testthat::expect_error(
      cluster_functional_types(data = 1:10)
    )
    testthat::expect_error(
      cluster_functional_types(data = NULL)
    )
  }
)

testthat::test_that(
  "cluster_functional_types() errors with < 4 rows",
  {
    data_small <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        sla = base::c(1.0, 2.0, 3.0)
      )
    testthat::expect_error(
      cluster_functional_types(data = data_small)
    )
  }
)

testthat::test_that(
  "cluster_functional_types() errors on bad taxon_col",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(5.0, 5.1, 4.9, 5.2, 4.8)
      )
    testthat::expect_error(
      cluster_functional_types(
        data = data_traits,
        taxon_col = 1L
      )
    )
    testthat::expect_error(
      cluster_functional_types(
        data = data_traits,
        taxon_col = base::c("a", "b")
      )
    )
    testthat::expect_error(
      cluster_functional_types(
        data = data_traits,
        taxon_col = "species"
      )
    )
  }
)

testthat::test_that(
  "cluster_functional_types() errors on bad k_max",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(5.0, 5.1, 4.9, 5.2, 4.8)
      )
    testthat::expect_error(
      cluster_functional_types(
        data = data_traits,
        k_max = "ten"
      )
    )
    testthat::expect_error(
      cluster_functional_types(
        data = data_traits,
        k_max = 1L
      )
    )
    testthat::expect_error(
      cluster_functional_types(
        data = data_traits,
        k_max = 5L
      )
    )
  }
)

testthat::test_that(
  "cluster_functional_types() errors on bad verbose",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(5.0, 5.1, 4.9, 5.2, 4.8)
      )
    testthat::expect_error(
      cluster_functional_types(
        data = data_traits,
        verbose = "yes"
      )
    )
    testthat::expect_error(
      cluster_functional_types(
        data = data_traits,
        verbose = 1L
      )
    )
  }
)

testthat::test_that(
  "cluster_functional_types() errors on bad metric",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(5.0, 5.1, 4.9, 5.2, 4.8)
      )
    testthat::expect_error(
      cluster_functional_types(
        data = data_traits,
        metric = 42L
      )
    )
    testthat::expect_error(
      cluster_functional_types(
        data = data_traits,
        metric = base::c("gower", "euclidean")
      )
    )
  }
)

testthat::test_that(
  "cluster_functional_types() errors on bad method",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(5.0, 5.1, 4.9, 5.2, 4.8)
      )
    testthat::expect_error(
      cluster_functional_types(
        data = data_traits,
        method = TRUE
      )
    )
    testthat::expect_error(
      cluster_functional_types(
        data = data_traits,
        method = base::c("ward.D2", "complete")
      )
    )
  }
)

testthat::test_that(
  "cluster_functional_types() returns correct structure",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c(
          "A", "B", "C", "D", "E",
          "F", "G", "H", "I", "J"
        ),
        sla = base::c(
          5, 5.1, 4.9, 5.2, 4.8,
          50, 49.8, 50.2, 50.1, 49.9
        ),
        height = base::c(
          0.5, 0.4, 0.6, 0.5, 0.4,
          5, 4.8, 5.2, 5, 4.9
        )
      )
    base::set.seed(900723)
    res <-
      cluster_functional_types(
        data = data_traits,
        k_max = 9L,
        verbose = FALSE
      )
    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(base::nrow(res), 10L)
    testthat::expect_equal(base::ncol(res), 3L)
    testthat::expect_named(
      res,
      base::c(
        "taxon_name", "functional_type", "silhouette_width"
      )
    )
    testthat::expect_type(
      dplyr::pull(res, functional_type),
      "integer"
    )
    testthat::expect_type(
      dplyr::pull(res, silhouette_width),
      "double"
    )
    testthat::expect_equal(
      dplyr::pull(res, taxon_name),
      dplyr::pull(data_traits, taxon_name)
    )
  }
)

testthat::test_that(
  "cluster_functional_types() k_chosen attribute is set",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c(
          "A", "B", "C", "D", "E",
          "F", "G", "H", "I", "J"
        ),
        sla = base::c(
          5, 5.1, 4.9, 5.2, 4.8,
          50, 49.8, 50.2, 50.1, 49.9
        ),
        height = base::c(
          0.5, 0.4, 0.6, 0.5, 0.4,
          5, 4.8, 5.2, 5, 4.9
        )
      )
    base::set.seed(900723)
    res <-
      cluster_functional_types(
        data = data_traits,
        k_max = 9L,
        verbose = FALSE
      )
    k_chosen <-
      base::attr(res, "k_chosen")
    testthat::expect_false(base::is.null(k_chosen))
    testthat::expect_type(k_chosen, "integer")
    testthat::expect_true(k_chosen >= 2L)
  }
)

testthat::test_that(
  "cluster_functional_types() finds 2 clusters",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c(
          "A", "B", "C", "D", "E",
          "F", "G", "H", "I", "J"
        ),
        sla = base::c(
          5, 5.1, 4.9, 5.2, 4.8,
          50, 49.8, 50.2, 50.1, 49.9
        ),
        height = base::c(
          0.5, 0.4, 0.6, 0.5, 0.4,
          5, 4.8, 5.2, 5, 4.9
        )
      )
    base::set.seed(900723)
    res <-
      cluster_functional_types(
        data = data_traits,
        k_max = 9L,
        verbose = FALSE
      )
    k_chosen <-
      base::attr(res, "k_chosen")
    testthat::expect_equal(k_chosen, 2L)
    vec_ft_low <-
      dplyr::pull(
        dplyr::filter(
          res,
          taxon_name %in% base::c("A", "B", "C", "D", "E")
        ),
        functional_type
      )
    vec_ft_high <-
      dplyr::pull(
        dplyr::filter(
          res,
          taxon_name %in% base::c("F", "G", "H", "I", "J")
        ),
        functional_type
      )
    testthat::expect_equal(
      base::length(base::unique(vec_ft_low)),
      1L
    )
    testthat::expect_equal(
      base::length(base::unique(vec_ft_high)),
      1L
    )
    testthat::expect_false(
      vec_ft_low[[1]] == vec_ft_high[[1]]
    )
  }
)

testthat::test_that(
  "cluster_functional_types() taxon_col renames output",
  {
    data_species <-
      tibble::tibble(
        species = base::c(
          "sp1", "sp2", "sp3", "sp4", "sp5",
          "sp6", "sp7", "sp8", "sp9", "sp10"
        ),
        sla = base::c(
          5, 5.1, 4.9, 5.2, 4.8,
          50, 49.8, 50.2, 50.1, 49.9
        )
      )
    base::set.seed(900723)
    res <-
      cluster_functional_types(
        data = data_species,
        taxon_col = "species",
        k_max = 9L,
        verbose = FALSE
      )
    testthat::expect_true(
      "taxon_name" %in% base::colnames(res)
    )
    testthat::expect_false(
      "species" %in% base::colnames(res)
    )
    testthat::expect_equal(
      dplyr::pull(res, taxon_name),
      dplyr::pull(data_species, species)
    )
  }
)

testthat::test_that(
  "cluster_functional_types() handles NA trait values",
  {
    data_na <-
      tibble::tibble(
        taxon_name = base::c(
          "A", "B", "C", "D", "E",
          "F", "G", "H", "I", "J"
        ),
        sla = base::c(
          5, NA, 4.9, 5.2, 4.8,
          50, 49.8, NA, 50.1, 49.9
        ),
        height = base::c(
          0.5, 0.4, 0.6, 0.5, 0.4,
          5, 4.8, 5.2, 5, 4.9
        )
      )
    base::set.seed(900723)
    res <-
      cluster_functional_types(
        data = data_na,
        k_max = 9L,
        verbose = FALSE
      )
    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(base::nrow(res), 10L)
  }
)

testthat::test_that(
  "cluster_functional_types() verbose=FALSE is silent",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c(
          "A", "B", "C", "D", "E",
          "F", "G", "H", "I", "J"
        ),
        sla = base::c(
          5, 5.1, 4.9, 5.2, 4.8,
          50, 49.8, 50.2, 50.1, 49.9
        ),
        height = base::c(
          0.5, 0.4, 0.6, 0.5, 0.4,
          5, 4.8, 5.2, 5, 4.9
        )
      )
    base::set.seed(900723)
    testthat::expect_silent(
      cluster_functional_types(
        data = data_traits,
        k_max = 9L,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "cluster_functional_types() handles NaN Gower distances",
  {
    # Taxa in group 1 have only trait_1; taxa in group 2 have only trait_2.
    # Gower distance for any cross-group pair = NaN (no shared valid traits).
    # Without NaN-guarding, stats::hclust() raises "NA/NaN/Inf in foreign
    # function call (arg 10)".  The function must replace NaN/non-finite
    # distances with 1.0 (fully dissimilar) before calling hclust.
    data_nonoverlap <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E", "F", "G", "H"),
        trait_1 = base::c(1.0, 1.5, 0.8, 1.2, NA, NA, NA, NA),
        trait_2 = base::c(NA, NA, NA, NA, 10.0, 12.0, 11.0, 9.0)
      )
    base::set.seed(900723)
    res <-
      cluster_functional_types(
        data = data_nonoverlap,
        k_max = 6L,
        verbose = FALSE
      )
    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(base::nrow(res), 8L)
    testthat::expect_named(
      res,
      base::c("taxon_name", "functional_type", "silhouette_width")
    )
  }
)

testthat::test_that(
  "cluster_functional_types() replaces Inf/-Inf with NA and succeeds",
  {
    data_inf <-
      tibble::tibble(
        taxon_name = base::c(
          "A", "B", "C", "D", "E",
          "F", "G", "H", "I", "J"
        ),
        sla = base::c(
          5, 5.1, Inf, 5.2, 4.8,
          50, -Inf, 50.2, 50.1, 49.9
        ),
        height = base::c(
          0.5, 0.4, 0.6, 0.5, 0.4,
          5, 4.8, 5.2, 5, 4.9
        )
      )
    base::set.seed(900723)
    res <-
      cluster_functional_types(
        data = data_inf,
        k_max = 9L,
        verbose = FALSE
      )
    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(base::nrow(res), 10L)
    testthat::expect_named(
      res,
      base::c("taxon_name", "functional_type", "silhouette_width")
    )
  }
)

testthat::test_that(
  "cluster_functional_types() accepts non-default metric and method",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c(
          "A", "B", "C", "D", "E",
          "F", "G", "H", "I", "J"
        ),
        sla = base::c(
          5, 5.1, 4.9, 5.2, 4.8,
          50, 49.8, 50.2, 50.1, 49.9
        ),
        height = base::c(
          0.5, 0.4, 0.6, 0.5, 0.4,
          5, 4.8, 5.2, 5, 4.9
        )
      )
    base::set.seed(900723)
    res <-
      cluster_functional_types(
        data = data_traits,
        k_max = 9L,
        metric = "euclidean",
        method = "complete",
        verbose = FALSE
      )
    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(base::nrow(res), 10L)
    testthat::expect_named(
      res,
      base::c("taxon_name", "functional_type", "silhouette_width")
    )
    testthat::expect_false(
      base::is.null(base::attr(res, "k_chosen"))
    )
  }
)

