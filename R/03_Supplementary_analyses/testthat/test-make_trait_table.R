testthat::test_that(
  "make_trait_table() validates data argument",
  {
    testthat::expect_error(
      make_trait_table(data = "not a data frame")
    )

    testthat::expect_error(
      make_trait_table(data = NULL)
    )

    testthat::expect_error(
      make_trait_table(data = base::list(a = 1))
    )
  }
)

testthat::test_that(
  "make_trait_table() validates taxon_col argument",
  {
    data_test <-
      tibble::tibble(
        taxon_name = "Genus_A",
        trait_domain_name = "SLA",
        trait_value_aggregated = 20
      )

    testthat::expect_error(
      make_trait_table(
        data = data_test,
        taxon_col = 123
      )
    )

    testthat::expect_error(
      make_trait_table(
        data = data_test,
        taxon_col = base::c("taxon_name", "extra")
      )
    )

    testthat::expect_error(
      make_trait_table(
        data = data_test,
        taxon_col = "nonexistent_col"
      )
    )
  }
)

testthat::test_that(
  "make_trait_table() validates trait_col argument",
  {
    data_test <-
      tibble::tibble(
        taxon_name = "Genus_A",
        trait_domain_name = "SLA",
        trait_value_aggregated = 20
      )

    testthat::expect_error(
      make_trait_table(
        data = data_test,
        trait_col = 123
      )
    )

    testthat::expect_error(
      make_trait_table(
        data = data_test,
        trait_col = base::c("trait_domain_name", "extra")
      )
    )

    testthat::expect_error(
      make_trait_table(
        data = data_test,
        trait_col = "nonexistent_col"
      )
    )
  }
)

testthat::test_that(
  "make_trait_table() validates value_col argument",
  {
    data_test <-
      tibble::tibble(
        taxon_name = "Genus_A",
        trait_domain_name = "SLA",
        trait_value_aggregated = 20
      )

    testthat::expect_error(
      make_trait_table(
        data = data_test,
        value_col = 123
      )
    )

    testthat::expect_error(
      make_trait_table(
        data = data_test,
        value_col = base::c(
          "trait_value_aggregated", "extra"
        )
      )
    )

    testthat::expect_error(
      make_trait_table(
        data = data_test,
        value_col = "nonexistent_col"
      )
    )
  }
)

testthat::test_that(
  "make_trait_table() produces correct wide table dimensions",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::c(
          "Genus_A", "Genus_A", "Genus_B", "Genus_B"
        ),
        trait_domain_name = base::c(
          "SLA", "Height", "SLA", "Height"
        ),
        trait_value_aggregated = base::c(20, 1.5, 10, 0.8)
      )

    res <-
      make_trait_table(data = data_test)

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_equal(base::ncol(res), 3L)

    testthat::expect_true(
      base::all(
        base::c("taxon_name", "SLA", "Height") %in%
          base::colnames(res)
      )
    )
  }
)

testthat::test_that(
  "make_trait_table() produces correct cell values",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::c(
          "Genus_A", "Genus_A", "Genus_B", "Genus_B"
        ),
        trait_domain_name = base::c(
          "SLA", "Height", "SLA", "Height"
        ),
        trait_value_aggregated = base::c(20, 1.5, 10, 0.8)
      )

    res <-
      make_trait_table(data = data_test)

    res_genus_a <-
      dplyr::filter(res, taxon_name == "Genus_A")

    res_genus_b <-
      dplyr::filter(res, taxon_name == "Genus_B")

    testthat::expect_equal(
      dplyr::pull(res_genus_a, SLA),
      20
    )

    testthat::expect_equal(
      dplyr::pull(res_genus_a, Height),
      1.5
    )

    testthat::expect_equal(
      dplyr::pull(res_genus_b, SLA),
      10
    )

    testthat::expect_equal(
      dplyr::pull(res_genus_b, Height),
      0.8
    )
  }
)

testthat::test_that(
  "make_trait_table() returns a tibble",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_A"),
        trait_domain_name = base::c("SLA", "Height"),
        trait_value_aggregated = base::c(20, 1.5)
      )

    res <-
      make_trait_table(data = data_test)

    testthat::expect_s3_class(res, "tbl_df")
  }
)

testthat::test_that(
  "make_trait_table() single trait gives 2-column result",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_B"),
        trait_domain_name = base::c("SLA", "SLA"),
        trait_value_aggregated = base::c(20, 10)
      )

    res <-
      make_trait_table(data = data_test)

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_equal(base::ncol(res), 2L)

    testthat::expect_true(
      "taxon_name" %in% base::colnames(res)
    )

    testthat::expect_true(
      "SLA" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "make_trait_table() supports custom column name arguments",
  {
    data_test <-
      tibble::tibble(
        genus = base::c("Genus_A", "Genus_B"),
        trait_type = base::c("SLA", "SLA"),
        agg_value = base::c(20, 10)
      )

    res <-
      make_trait_table(
        data = data_test,
        taxon_col = "genus",
        trait_col = "trait_type",
        value_col = "agg_value"
      )

    testthat::expect_equal(base::nrow(res), 2L)

    testthat::expect_true(
      "genus" %in% base::colnames(res)
    )
  }
)
