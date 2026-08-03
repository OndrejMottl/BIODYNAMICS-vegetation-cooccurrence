testthat::test_that(
  "top-occurrence selection returns the selected taxa",
  {
    data_test <-
      base::data.frame(
        dataset_name = base::rep(
          x = stringr::str_glue("dataset_{base::seq_len(10)}"),
          each = 5
        ),
        taxon = base::rep(
          x = stringr::str_glue("taxon_{base::seq_len(5)}"),
          times = 10
        ),
        value = stats::runif(
          n = 50,
          min = 0,
          max = 1
        )
      )

    res <-
      select_top_taxa_by_group_occurrence(
        data_community = data_test,
        maximum_taxon_count = 3,
        grouping_column_name = "dataset_name"
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
  "top-occurrence selection keeps all taxa when unlimited",
  {
    data_test <-
      base::data.frame(
        dataset_name = base::rep(
          x = stringr::str_glue("dataset_{base::seq_len(10)}"),
          each = 5
        ),
        taxon = base::rep(
          x = stringr::str_glue("taxon_{base::seq_len(5)}"),
          times = 10
        ),
        value = stats::runif(
          n = 50,
          min = 0,
          max = 1
        )
      )

    res <-
      select_top_taxa_by_group_occurrence(
        data_community = data_test,
        maximum_taxon_count = Inf,
        grouping_column_name = "dataset_name"
      )

    testthat::expect_equal(
      object = dplyr::n_distinct(dplyr::pull(res, taxon)),
      expected = 5
    )
  }
)

testthat::test_that(
  "select_top_taxa_by_group_occurrence() validates input data",
  {
    testthat::expect_error(
      object = select_top_taxa_by_group_occurrence(
        data_community = NULL,
        maximum_taxon_count = 2,
        grouping_column_name = "dataset_name"
      )
    )
    testthat::expect_error(
      object = select_top_taxa_by_group_occurrence(
        data_community = base::data.frame(),
        maximum_taxon_count = 2,
        grouping_column_name = "dataset_name"
      )
    )
  }
)

testthat::test_that(
  "select_top_taxa_by_group_occurrence() validates arguments",
  {
    data_test <-
      base::data.frame(
        dataset_name = base::c("dataset_1", "dataset_2"),
        taxon = base::c("taxon_1", "taxon_2"),
        value = base::c(0.1, 0.2)
      )

    testthat::expect_error(
      object = select_top_taxa_by_group_occurrence(
        data_community = data_test,
        maximum_taxon_count = 0,
        grouping_column_name = "dataset_name"
      )
    )
    testthat::expect_error(
      object = select_top_taxa_by_group_occurrence(
        data_community = data_test,
        maximum_taxon_count = 2,
        grouping_column_name = base::c("dataset_name", "age")
      )
    )
  }
)
