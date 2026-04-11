testthat::test_that(
  "compute_gower_distance() errors when data is not a data frame",
  {
    testthat::expect_error(
      compute_gower_distance(data = "not_a_df")
    )
  }
)

testthat::test_that(
  "compute_gower_distance() errors when taxon_col is not character",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    testthat::expect_error(
      compute_gower_distance(
        data = data_traits,
        taxon_col = 1L
      )
    )
  }
)

testthat::test_that(
  "compute_gower_distance() errors when taxon_col has length > 1",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    testthat::expect_error(
      compute_gower_distance(
        data = data_traits,
        taxon_col = base::c("taxon_name", "sla")
      )
    )
  }
)

testthat::test_that(
  "compute_gower_distance() errors when taxon_col not in data",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    testthat::expect_error(
      compute_gower_distance(
        data = data_traits,
        taxon_col = "species"
      )
    )
  }
)

testthat::test_that(
  "compute_gower_distance() errors when metric is not character",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    testthat::expect_error(
      compute_gower_distance(
        data = data_traits,
        metric = 1L
      )
    )
  }
)

testthat::test_that(
  "compute_gower_distance() errors when metric has length > 1",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    testthat::expect_error(
      compute_gower_distance(
        data = data_traits,
        metric = base::c("gower", "euclidean")
      )
    )
  }
)

testthat::test_that(
  "compute_gower_distance() errors when no trait columns present",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B")
      )

    testthat::expect_error(
      compute_gower_distance(data = data_traits),
      regexp = "No trait columns found"
    )
  }
)

testthat::test_that(
  "compute_gower_distance() returns an object of class dist",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        sla = base::c(1.0, 2.0, 10.0)
      )

    res <-
      compute_gower_distance(data = data_traits)

    testthat::expect_s3_class(res, "dist")
  }
)

testthat::test_that(
  "compute_gower_distance() dist length equals n*(n-1)/2",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(1.0, 2.0, 10.0, 11.0, 5.0),
        height = base::c(0.5, 0.6, 5.0, 5.1, 2.5)
      )

    res <-
      compute_gower_distance(data = data_traits)

    n <- 5L

    testthat::expect_equal(
      base::length(res),
      n * (n - 1L) / 2L
    )
  }
)

testthat::test_that(
  "compute_gower_distance() all output values are finite",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(1.0, 2.0, 10.0, 11.0, 5.0),
        height = base::c(0.5, 0.6, 5.0, 5.1, 2.5)
      )

    res <-
      compute_gower_distance(data = data_traits)

    testthat::expect_true(
      base::all(base::is.finite(base::as.numeric(res)))
    )
  }
)

testthat::test_that(
  "compute_gower_distance() Gower values are all in [0, 1]",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E"),
        sla = base::c(1.0, 2.0, 10.0, 11.0, 5.0),
        height = base::c(0.5, 0.6, 5.0, 5.1, 2.5)
      )

    res <-
      compute_gower_distance(data = data_traits)

    vec_dist <-
      base::as.numeric(res)

    testthat::expect_true(base::all(vec_dist >= 0))
    testthat::expect_true(base::all(vec_dist <= 1))
  }
)

testthat::test_that(
  "compute_gower_distance() identical taxa have distance 0",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        sla = base::c(1.0, 1.0, 5.0),
        height = base::c(0.5, 0.5, 2.5)
      )

    res <-
      compute_gower_distance(data = data_traits)

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
  "compute_gower_distance() maximally different taxa get dist near 1",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(0.0, 100.0),
        height = base::c(0.0, 100.0)
      )

    res <-
      compute_gower_distance(data = data_traits)

    testthat::expect_equal(
      base::as.numeric(res),
      1.0,
      tolerance = 1e-10
    )
  }
)

testthat::test_that(
  "compute_gower_distance() handles Inf in trait data without error",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        sla = base::c(1.0, Inf, 3.0),
        height = base::c(0.5, 0.6, -Inf)
      )

    res <-
      compute_gower_distance(data = data_traits)

    testthat::expect_s3_class(res, "dist")
    testthat::expect_true(
      base::all(base::is.finite(base::as.numeric(res)))
    )
  }
)

testthat::test_that(
  "compute_gower_distance() works with a single trait column",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        sla = base::c(1.0, 5.0, 10.0)
      )

    res <-
      compute_gower_distance(data = data_traits)

    testthat::expect_s3_class(res, "dist")
    testthat::expect_equal(base::length(res), 3L)
  }
)

testthat::test_that(
  "compute_gower_distance() works with multiple trait columns",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        sla = base::c(1.0, 5.0, 10.0),
        height = base::c(0.5, 2.5, 5.0),
        ldmc = base::c(0.1, 0.3, 0.5)
      )

    res <-
      compute_gower_distance(data = data_traits)

    testthat::expect_s3_class(res, "dist")
    testthat::expect_equal(base::length(res), 3L)
  }
)
