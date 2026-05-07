testthat::test_that(
  "select_n_taxa() returns a data frame with selected taxa",
  {
    data_test <-
      base::data.frame(
        dataset_name = base::rep(
          x = base::paste0("dataset_", 1:10),
          each = 5
        ),
        taxon = base::rep(
          x = base::paste0("taxon_", 1:5),
          times = 10
        ),
        value = stats::runif(
          n = 50,
          min = 0,
          max = 1
        )
      )

    res <-
      select_n_taxa(
        data = data_test,
        n_taxa = 3,
        per = "dataset_name"
      )

    testthat::expect_s3_class(
      object = res,
      class = "data.frame"
    )
    testthat::expect_lte(
      object = dplyr::n_distinct(dplyr::pull(res, taxon)),
      expected = 3
    )
  }
)

testthat::test_that(
  "select_n_taxa() keeps all taxa when n_taxa is Inf",
  {
    data_test <-
      base::data.frame(
        dataset_name = base::rep(
          x = base::paste0("dataset_", 1:10),
          each = 5
        ),
        taxon = base::rep(
          x = base::paste0("taxon_", 1:5),
          times = 10
        ),
        value = stats::runif(
          n = 50,
          min = 0,
          max = 1
        )
      )

    res <-
      select_n_taxa(
        data = data_test,
        n_taxa = Inf,
        per = "dataset_name"
      )

    testthat::expect_equal(
      object = dplyr::n_distinct(dplyr::pull(res, taxon)),
      expected = 5
    )
  }
)

testthat::test_that(
  "select_n_taxa() validates input data",
  {
    testthat::expect_error(
      object = select_n_taxa(
        data = NULL,
        n_taxa = 2,
        per = "dataset_name"
      )
    )
    testthat::expect_error(
      object = select_n_taxa(
        data = base::data.frame(),
        n_taxa = 2,
        per = "dataset_name"
      )
    )
  }
)

testthat::test_that(
  "select_n_taxa() validates arguments",
  {
    data_test <-
      base::data.frame(
        dataset_name = base::c("dataset_1", "dataset_2"),
        taxon = base::c("taxon_1", "taxon_2"),
        value = base::c(0.1, 0.2)
      )

    testthat::expect_error(
      object = select_n_taxa(
        data = data_test,
        n_taxa = 0,
        per = "dataset_name"
      )
    )
    testthat::expect_error(
      object = select_n_taxa(
        data = data_test,
        n_taxa = 2,
        per = base::c("dataset_name", "age")
      )
    )
  }
)
