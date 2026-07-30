testthat::test_that(
  "compute_trait_dissimilarity() errors when data is not a data frame",
  {
    testthat::expect_error(
      compute_trait_dissimilarity(data_trait_table = "not_a_df")
    )
  }
)

testthat::test_that(
  "compute_trait_dissimilarity() errors when taxon_column is not character",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    testthat::expect_error(
      compute_trait_dissimilarity(
        data_trait_table = data_traits,
        taxon_column = 1L
      )
    )
  }
)

testthat::test_that(
  "compute_trait_dissimilarity() errors when taxon_column has length > 1",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    testthat::expect_error(
      compute_trait_dissimilarity(
        data_trait_table = data_traits,
        taxon_column = base::c("taxon_name", "sla")
      )
    )
  }
)

testthat::test_that(
  "compute_trait_dissimilarity() errors when taxon_column not in data",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    testthat::expect_error(
      compute_trait_dissimilarity(
        data_trait_table = data_traits,
        taxon_column = "species"
      )
    )
  }
)

testthat::test_that(
  "compute_trait_dissimilarity() errors when distance_metric is not character",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    testthat::expect_error(
      compute_trait_dissimilarity(
        data_trait_table = data_traits,
        distance_metric = 1L
      )
    )
  }
)

testthat::test_that(
  "compute_trait_dissimilarity() errors when distance_metric has length > 1",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    testthat::expect_error(
      compute_trait_dissimilarity(
        data_trait_table = data_traits,
        distance_metric = base::c("gower", "euclidean")
      )
    )
  }
)

testthat::test_that(
  "compute_trait_dissimilarity() errors when no trait columns present",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B")
      )

    testthat::expect_error(
      compute_trait_dissimilarity(data_trait_table = data_traits),
      regexp = "No trait columns found"
    )
  }
)

testthat::test_that(
  "compute_trait_dissimilarity() returns an object of class dist",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        sla = base::c(1.0, 2.0, 10.0)
      )

    res <-
      compute_trait_dissimilarity(data_trait_table = data_traits)

    testthat::expect_s3_class(res, "dist")
  }
)

testthat::test_that(
  "compute_trait_dissimilarity() dist length equals n*(n-1)/2",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(1.0, 2.0, 10.0, 11.0, 5.0),
        height = base::c(0.5, 0.6, 5.0, 5.1, 2.5)
      )

    res <-
      compute_trait_dissimilarity(data_trait_table = data_traits)

    n <- 5L

    testthat::expect_equal(
      base::length(res),
      n * (n - 1L) / 2L
    )
  }
)

testthat::test_that(
  "compute_trait_dissimilarity() all output values are finite",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(1.0, 2.0, 10.0, 11.0, 5.0),
        height = base::c(0.5, 0.6, 5.0, 5.1, 2.5)
      )

    res <-
      compute_trait_dissimilarity(data_trait_table = data_traits)

    testthat::expect_true(
      base::all(base::is.finite(base::as.numeric(res)))
    )
  }
)

testthat::test_that(
  "compute_trait_dissimilarity() values are all in [0, 1] for gower distance_metric",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(1.0, 2.0, 10.0, 11.0, 5.0),
        height = base::c(0.5, 0.6, 5.0, 5.1, 2.5)
      )

    res <-
      compute_trait_dissimilarity(data_trait_table = data_traits)

    vec_dist <-
      base::as.numeric(res)

    testthat::expect_true(base::all(vec_dist >= 0))
    testthat::expect_true(base::all(vec_dist <= 1))
  }
)

testthat::test_that(
  "compute_trait_dissimilarity() identical taxa have distance 0",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        sla = base::c(1.0, 1.0, 5.0),
        height = base::c(0.5, 0.5, 2.5)
      )

    res <-
      compute_trait_dissimilarity(data_trait_table = data_traits)

    vec_dist <-
      base::as.numeric(res)

    testthat::expect_equal(
      vec_dist[1L],
      0.0,
      tolerance = 1e-10
    )
  }
)

testthat::test_that(
  "compute_trait_dissimilarity() maximally different taxa get dist near 1",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(0.0, 100.0),
        height = base::c(0.0, 100.0)
      )

    res <-
      compute_trait_dissimilarity(data_trait_table = data_traits)

    testthat::expect_equal(
      base::as.numeric(res),
      1.0,
      tolerance = 1e-10
    )
  }
)

testthat::test_that(
  "compute_trait_dissimilarity() handles Inf in trait data without error",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        sla = base::c(1.0, Inf, 3.0),
        height = base::c(0.5, 0.6, -Inf)
      )

    res <-
      compute_trait_dissimilarity(data_trait_table = data_traits)

    testthat::expect_s3_class(res, "dist")
    testthat::expect_true(
      base::all(base::is.finite(base::as.numeric(res)))
    )
  }
)

testthat::test_that(
  "compute_trait_dissimilarity() works with a single trait column",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        sla = base::c(1.0, 5.0, 10.0)
      )

    res <-
      compute_trait_dissimilarity(data_trait_table = data_traits)

    testthat::expect_s3_class(res, "dist")
    testthat::expect_equal(base::length(res), 3L)
  }
)

testthat::test_that(
  "compute_trait_dissimilarity() works with multiple trait columns",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        sla = base::c(1.0, 5.0, 10.0),
        height = base::c(0.5, 2.5, 5.0),
        ldmc = base::c(0.1, 0.3, 0.5)
      )

    res <-
      compute_trait_dissimilarity(data_trait_table = data_traits)

    testthat::expect_s3_class(res, "dist")
    testthat::expect_equal(base::length(res), 3L)
  }
)
