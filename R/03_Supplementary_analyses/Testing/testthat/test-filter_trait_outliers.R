testthat::test_that(
  "filter_trait_outliers() validates data argument",
  {
    testthat::expect_error(
      filter_trait_outliers(data = "not a data frame")
    )

    testthat::expect_error(
      filter_trait_outliers(data = NULL)
    )

    testthat::expect_error(
      filter_trait_outliers(
        data = base::list(trait_value = 1:5)
      )
    )

    testthat::expect_error(
      filter_trait_outliers(
        data = base::matrix(1:6, nrow = 2)
      )
    )
  }
)

testthat::test_that(
  "filter_trait_outliers() validates trait_col argument",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_A"),
        trait_domain_name = base::c("SLA", "SLA"),
        trait_value = base::c(10, 12)
      )

    testthat::expect_error(
      filter_trait_outliers(
        data = data_test,
        trait_col = 123
      )
    )

    testthat::expect_error(
      filter_trait_outliers(
        data = data_test,
        trait_col = base::c("trait_value", "extra")
      )
    )

    testthat::expect_error(
      filter_trait_outliers(
        data = data_test,
        trait_col = "nonexistent_col"
      )
    )
  }
)

testthat::test_that(
  "filter_trait_outliers() validates group_cols argument",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_A"),
        trait_domain_name = base::c("SLA", "SLA"),
        trait_value = base::c(10, 12)
      )

    testthat::expect_error(
      filter_trait_outliers(
        data = data_test,
        group_cols = 123
      )
    )

    testthat::expect_error(
      filter_trait_outliers(
        data = data_test,
        group_cols = base::c("taxon_name", "nonexistent")
      )
    )
  }
)

testthat::test_that(
  "filter_trait_outliers() validates iqr_multiplier argument",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_A"),
        trait_domain_name = base::c("SLA", "SLA"),
        trait_value = base::c(10, 12)
      )

    testthat::expect_error(
      filter_trait_outliers(
        data = data_test,
        iqr_multiplier = "1.5"
      )
    )

    testthat::expect_error(
      filter_trait_outliers(
        data = data_test,
        iqr_multiplier = 0
      )
    )

    testthat::expect_error(
      filter_trait_outliers(
        data = data_test,
        iqr_multiplier = -1
      )
    )
  }
)

testthat::test_that(
  "filter_trait_outliers() returns data frame with same cols",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::c("Genus_A", "Genus_A", "Genus_A"),
        trait_domain_name = base::c("SLA", "SLA", "SLA"),
        trait_value = base::c(10, 11, 12)
      )

    res <-
      filter_trait_outliers(data = data_test)

    testthat::expect_true(
      base::is.data.frame(res)
    )

    testthat::expect_equal(
      base::colnames(res),
      base::colnames(data_test)
    )
  }
)

testthat::test_that(
  "filter_trait_outliers() removes IQR outlier from group",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::rep("Genus_A", 4),
        trait_domain_name = base::rep("SLA", 4),
        trait_value = base::c(10, 12, 11, 100)
      )

    res <-
      filter_trait_outliers(
        data = data_test,
        iqr_multiplier = 1.5
      )

    testthat::expect_equal(base::nrow(res), 3L)

    testthat::expect_false(
      base::any(dplyr::pull(res, trait_value) == 100)
    )
  }
)

testthat::test_that(
  "filter_trait_outliers() keeps constant groups intact",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::rep("Genus_C", 3),
        trait_domain_name = base::rep("Height", 3),
        trait_value = base::rep(5.0, 3)
      )

    res <-
      filter_trait_outliers(data = data_test)

    testthat::expect_equal(base::nrow(res), 3L)
  }
)

testthat::test_that(
  "filter_trait_outliers() outlier in group A keeps group B",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::c(
          base::rep("Genus_A", 4),
          base::rep("Genus_B", 3)
        ),
        trait_domain_name = base::rep("SLA", 7),
        trait_value = base::c(10, 12, 11, 100, 5, 6, 7)
      )

    res <-
      filter_trait_outliers(
        data = data_test,
        iqr_multiplier = 1.5
      )

    res_genus_b <-
      dplyr::filter(res, taxon_name == "Genus_B")

    testthat::expect_equal(base::nrow(res_genus_b), 3L)
  }
)

testthat::test_that(
  "filter_trait_outliers() emits message for removed rows",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::rep("Genus_A", 4),
        trait_domain_name = base::rep("SLA", 4),
        trait_value = base::c(10, 12, 11, 100)
      )

    testthat::expect_message(
      filter_trait_outliers(
        data = data_test,
        iqr_multiplier = 1.5
      )
    )
  }
)

testthat::test_that(
  "filter_trait_outliers() handles zero-row data frame",
  {
    data_test <-
      tibble::tibble(
        taxon_name = base::character(0),
        trait_domain_name = base::character(0),
        trait_value = base::numeric(0)
      )

    res <-
      filter_trait_outliers(data = data_test)

    testthat::expect_true(base::is.data.frame(res))
    testthat::expect_equal(base::nrow(res), 0L)
  }
)

testthat::test_that(
  "filter_trait_outliers() keeps single-row group unchanged",
  {
    data_test <-
      tibble::tibble(
        taxon_name = "Genus_A",
        trait_domain_name = "SLA",
        trait_value = 10
      )

    res <-
      filter_trait_outliers(data = data_test)

    testthat::expect_equal(base::nrow(res), 1L)
  }
)
