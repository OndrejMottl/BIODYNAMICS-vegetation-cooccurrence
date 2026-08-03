testthat::test_that(
  "minimum-sample filter rejects non-data-frame inputs",
  {
    testthat::expect_error(
      filter_community_by_minimum_sample_count(
        data_community = "not a data frame"
      ),
      "must be a data frame"
    )

    testthat::expect_error(
      filter_community_by_minimum_sample_count(data_community = NULL),
      "must be a data frame"
    )

    testthat::expect_error(
      filter_community_by_minimum_sample_count(
        data_community = list(taxon = "Pinus", dataset_name = "A", age = 100)
      ),
      "must be a data frame"
    )

    testthat::expect_error(
      filter_community_by_minimum_sample_count(
        data_community = matrix(1:4, nrow = 2)
      ),
      "must be a data frame"
    )
  }
)

testthat::test_that(
  "minimum-sample filter rejects missing required columns",
  {
    data_no_taxon <-
      tibble::tibble(dataset_name = c("A", "B"), age = c(100, 200))

    data_no_dataset <-
      tibble::tibble(taxon = c("Pinus", "Betula"), age = c(100, 200))

    data_no_age <-
      tibble::tibble(
        taxon = c("Pinus", "Betula"),
        dataset_name = c("A", "B")
      )

    testthat::expect_error(
      filter_community_by_minimum_sample_count(data_community = data_no_taxon),
      "must contain columns"
    )

    testthat::expect_error(
      filter_community_by_minimum_sample_count(
        data_community = data_no_dataset
      ),
      "must contain columns"
    )

    testthat::expect_error(
      filter_community_by_minimum_sample_count(data_community = data_no_age),
      "must contain columns"
    )
  }
)

testthat::test_that(
  "minimum-sample filter rejects non-numeric thresholds",
  {
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Betula"),
        dataset_name = c("A", "B"),
        age = c(100, 200)
      )

    testthat::expect_error(
      filter_community_by_minimum_sample_count(
        data_community = data_test,
        minimum_sample_count = "5"
      ),
      "minimum_sample_count must be a numeric scalar"
    )

    testthat::expect_error(
      filter_community_by_minimum_sample_count(
        data_community = data_test,
        minimum_sample_count = NULL
      ),
      "minimum_sample_count must be a numeric scalar"
    )

    testthat::expect_error(
      filter_community_by_minimum_sample_count(
        data_community = data_test,
        minimum_sample_count = TRUE
      ),
      "minimum_sample_count must be a numeric scalar"
    )

    testthat::expect_error(
      filter_community_by_minimum_sample_count(
        data_community = data_test,
        minimum_sample_count = c(1, 5)
      ),
      "minimum_sample_count must be a numeric scalar"
    )
  }
)

testthat::test_that(
  "minimum-sample filter rejects thresholds below one",
  {
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Betula"),
        dataset_name = c("A", "B"),
        age = c(100, 200)
      )

    testthat::expect_error(
      filter_community_by_minimum_sample_count(
        data_community = data_test,
        minimum_sample_count = 0
      ),
      "must be greater than or equal to 1"
    )

    testthat::expect_error(
      filter_community_by_minimum_sample_count(
        data_community = data_test,
        minimum_sample_count = -5
      ),
      "must be greater than or equal to 1"
    )
  }
)

testthat::test_that(
  "filter_community_by_minimum_sample_count() errors when no taxa remain",
  {
    # Each taxon appears in only 1 sample
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Betula"),
        dataset_name = c("A", "B"),
        age = c(100, 200)
      )

    testthat::expect_error(
      filter_community_by_minimum_sample_count(
        data_community = data_test,
        minimum_sample_count = 5
      ),
      "No taxa remain"
    )
  }
)

testthat::test_that(
  "minimum-sample filter keeps taxa with enough samples",
  {
    # Pinus appears in 4 samples (2 cores x 2 ages)
    # Betula appears in 1 sample
    data_test <-
      tibble::tibble(
        taxon = c(
          "Pinus", "Pinus", "Pinus", "Pinus",
          "Betula"
        ),
        dataset_name = c("A", "A", "B", "B", "A"),
        age = c(100, 200, 100, 200, 100)
      )

    res <-
      filter_community_by_minimum_sample_count(
        data_community = data_test,
        minimum_sample_count = 3
      )

    testthat::expect_true(is.data.frame(res))
    testthat::expect_true(
      all(dplyr::pull(res, taxon) == "Pinus")
    )
    testthat::expect_false(
      "Betula" %in% dplyr::pull(res, taxon)
    )
  }
)

testthat::test_that(
  "minimum-sample filter defaults to one sample",
  {
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Betula", "Quercus"),
        dataset_name = c("A", "B", "C"),
        age = c(100, 200, 300)
      )

    res <-
      filter_community_by_minimum_sample_count(data_community = data_test)

    testthat::expect_equal(nrow(res), nrow(data_test))
  }
)

testthat::test_that(
  "minimum-sample filter counts unique dataset-age pairs",
  {
    # Pinus has 2 rows in same dataset+age -> counts as 1 sample
    # Pinus also appears in a second sample
    # Betula appears in only 1 sample
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Pinus", "Pinus", "Betula"),
        dataset_name = c("A", "A", "A", "A"),
        age = c(100, 100, 200, 100),
        value = c(0.1, 0.2, 0.1, 0.05)
      )

    # Pinus: 2 unique (dataset_name, age) = (A,100) and (A,200) -> kept
    # Betula: 1 unique sample -> also kept since minimum_sample_count=2 only
    # keeps Pinus
    res <-
      filter_community_by_minimum_sample_count(
        data_community = data_test,
        minimum_sample_count = 2
      )

    vec_taxa <-
      dplyr::pull(res, taxon) |>
      unique()

    testthat::expect_true("Pinus" %in% vec_taxa)
    testthat::expect_false("Betula" %in% vec_taxa)
  }
)

testthat::test_that(
  "minimum-sample filter preserves columns and structure",
  {
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Pinus"),
        dataset_name = c("A", "B"),
        age = c(100, 200),
        value = c(0.1, 0.2),
        extra_col = c("x", "y")
      )

    res <-
      filter_community_by_minimum_sample_count(
        data_community = data_test,
        minimum_sample_count = 2
      )

    testthat::expect_true(is.data.frame(res))
    testthat::expect_named(
      res,
      c("taxon", "dataset_name", "age", "value", "extra_col")
    )
  }
)
