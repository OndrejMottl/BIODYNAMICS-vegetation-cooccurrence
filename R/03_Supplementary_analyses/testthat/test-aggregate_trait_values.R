testthat::test_that(
  "aggregate_trait_values() validates data argument",
  {
    testthat::expect_error(
      aggregate_trait_values(data = "not a data frame")
    )

    testthat::expect_error(
      aggregate_trait_values(data = NULL)
    )

    testthat::expect_error(
      aggregate_trait_values(
        data = base::matrix(1:6, nrow = 2)
      )
    )
  }
)

testthat::test_that(
  "aggregate_trait_values() validates trait_col argument",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_A"),
        trait_domain_name = base::c("SLA", "SLA"),
        trait_value = base::c(10, 20)
      )

    testthat::expect_error(
      aggregate_trait_values(
        data = data_test,
        trait_col = 123
      )
    )

    testthat::expect_error(
      aggregate_trait_values(
        data = data_test,
        trait_col = base::c("trait_value", "extra")
      )
    )

    testthat::expect_error(
      aggregate_trait_values(
        data = data_test,
        trait_col = "nonexistent_col"
      )
    )
  }
)

testthat::test_that(
  "aggregate_trait_values() validates group_cols argument",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_A"),
        trait_domain_name = base::c("SLA", "SLA"),
        trait_value = base::c(10, 20)
      )

    testthat::expect_error(
      aggregate_trait_values(
        data = data_test,
        group_cols = 123
      )
    )

    testthat::expect_error(
      aggregate_trait_values(
        data = data_test,
        group_cols = base::c("taxon_name", "missing_col")
      )
    )
  }
)

testthat::test_that(
  "aggregate_trait_values() validates fn argument",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_A"),
        trait_domain_name = base::c("SLA", "SLA"),
        trait_value = base::c(10, 20)
      )

    testthat::expect_error(
      aggregate_trait_values(
        data = data_test,
        fn = "invalid_fn"
      )
    )

    testthat::expect_error(
      aggregate_trait_values(
        data = data_test,
        fn = "sum"
      )
    )
  }
)

testthat::test_that(
  "aggregate_trait_values() returns data frame with right cols",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::c(
          "Genus_A", "Genus_A", "Genus_A"
        ),
        trait_domain_name = base::rep("SLA", 3),
        trait_value = base::c(10, 20, 30)
      )

    res <-
      aggregate_trait_values(data = data_test)

    testthat::expect_true(base::is.data.frame(res))

    testthat::expect_true(
      "trait_value_aggregated" %in% base::colnames(res)
    )

    testthat::expect_true(
      base::all(
        base::c("taxon_name", "trait_domain_name") %in%
          base::colnames(res)
      )
    )
  }
)

testthat::test_that(
  "aggregate_trait_values() returns one row per unique group",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::c(
          "Genus_A", "Genus_A", "Genus_A",
          "Genus_B", "Genus_B"
        ),
        trait_domain_name = base::rep("SLA", 5),
        trait_value = base::c(10, 20, 30, 5, 15)
      )

    res <-
      aggregate_trait_values(data = data_test)

    testthat::expect_equal(base::nrow(res), 2L)
  }
)

testthat::test_that(
  "aggregate_trait_values() computes correct median values",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::c(
          "Genus_A", "Genus_A", "Genus_A",
          "Genus_B", "Genus_B"
        ),
        trait_domain_name = base::rep("SLA", 5),
        trait_value = base::c(10, 20, 30, 5, 15)
      )

    res <-
      aggregate_trait_values(data = data_test, fn = "median")

    res_genus_a <-
      dplyr::filter(res, taxon_name == "Genus_A")

    res_genus_b <-
      dplyr::filter(res, taxon_name == "Genus_B")

    testthat::expect_equal(
      dplyr::pull(res_genus_a, trait_value_aggregated),
      20
    )

    testthat::expect_equal(
      dplyr::pull(res_genus_b, trait_value_aggregated),
      10
    )
  }
)

testthat::test_that(
  "aggregate_trait_values() computes correct mean values",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::c(
          "Genus_A", "Genus_A", "Genus_A",
          "Genus_B", "Genus_B"
        ),
        trait_domain_name = base::rep("SLA", 5),
        trait_value = base::c(10, 20, 30, 5, 15)
      )

    res <-
      aggregate_trait_values(data = data_test, fn = "mean")

    res_genus_a <-
      dplyr::filter(res, taxon_name == "Genus_A")

    res_genus_b <-
      dplyr::filter(res, taxon_name == "Genus_B")

    testthat::expect_equal(
      dplyr::pull(res_genus_a, trait_value_aggregated),
      20
    )

    testthat::expect_equal(
      dplyr::pull(res_genus_b, trait_value_aggregated),
      10
    )
  }
)

testthat::test_that(
  "aggregate_trait_values() defaults to median",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::rep("Genus_A", 3),
        trait_domain_name = base::rep("SLA", 3),
        trait_value = base::c(10, 20, 30)
      )

    res_default <-
      aggregate_trait_values(data = data_test)

    res_median <-
      aggregate_trait_values(data = data_test, fn = "median")

    testthat::expect_equal(
      dplyr::pull(res_default, trait_value_aggregated),
      dplyr::pull(res_median, trait_value_aggregated)
    )
  }
)

testthat::test_that(
  "aggregate_trait_values() supports partial fn matching",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::rep("Genus_A", 3),
        trait_domain_name = base::rep("SLA", 3),
        trait_value = base::c(10, 20, 30)
      )

    res_partial <-
      aggregate_trait_values(data = data_test, fn = "med")

    res_median <-
      aggregate_trait_values(data = data_test, fn = "median")

    testthat::expect_equal(
      dplyr::pull(res_partial, trait_value_aggregated),
      dplyr::pull(res_median, trait_value_aggregated)
    )
  }
)

testthat::test_that(
  "aggregate_trait_values() single-row group is unchanged",
  {
    data_test <-
      tibble::tibble(
        taxon_name = "Genus_A",
        trait_domain_name = "SLA",
        trait_value = 42
      )

    res <-
      aggregate_trait_values(data = data_test)

    testthat::expect_equal(
      dplyr::pull(res, trait_value_aggregated),
      42
    )
  }
)
