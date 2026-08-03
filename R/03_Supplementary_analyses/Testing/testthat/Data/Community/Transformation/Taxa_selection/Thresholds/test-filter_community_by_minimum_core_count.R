testthat::test_that(
  "minimum-core filter rejects non-data-frame inputs",
  {
    testthat::expect_error(
      filter_community_by_minimum_core_count(
        data_community = "not a data frame"
      ),
      "must be a data frame"
    )

    testthat::expect_error(
      filter_community_by_minimum_core_count(data_community = NULL),
      "must be a data frame"
    )

    testthat::expect_error(
      filter_community_by_minimum_core_count(
        data_community = list(taxon = "Pinus", dataset_name = "A")
      ),
      "must be a data frame"
    )

    testthat::expect_error(
      filter_community_by_minimum_core_count(
        data_community = matrix(1:4, nrow = 2)
      ),
      "must be a data frame"
    )
  }
)

testthat::test_that(
  "minimum-core filter rejects missing required columns",
  {
    data_no_taxon <-
      tibble::tibble(dataset_name = c("A", "B"), value = c(1, 2))

    data_no_dataset <-
      tibble::tibble(taxon = c("Pinus", "Betula"), value = c(1, 2))

    testthat::expect_error(
      filter_community_by_minimum_core_count(data_community = data_no_taxon),
      "must contain columns"
    )

    testthat::expect_error(
      filter_community_by_minimum_core_count(data_community = data_no_dataset),
      "must contain columns"
    )
  }
)

testthat::test_that(
  "minimum-core filter rejects non-numeric thresholds",
  {
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Betula"),
        dataset_name = c("A", "B")
      )

    testthat::expect_error(
      filter_community_by_minimum_core_count(
        data_community = data_test,
        minimum_core_count = "2"
      ),
      "minimum_core_count must be a numeric scalar"
    )

    testthat::expect_error(
      filter_community_by_minimum_core_count(
        data_community = data_test,
        minimum_core_count = NULL
      ),
      "minimum_core_count must be a numeric scalar"
    )

    testthat::expect_error(
      filter_community_by_minimum_core_count(
        data_community = data_test,
        minimum_core_count = TRUE
      ),
      "minimum_core_count must be a numeric scalar"
    )

    testthat::expect_error(
      filter_community_by_minimum_core_count(
        data_community = data_test,
        minimum_core_count = c(1, 2)
      ),
      "minimum_core_count must be a numeric scalar"
    )
  }
)

testthat::test_that(
  "minimum-core filter rejects thresholds below one",
  {
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Betula"),
        dataset_name = c("A", "B")
      )

    testthat::expect_error(
      filter_community_by_minimum_core_count(
        data_community = data_test,
        minimum_core_count = 0
      ),
      "must be greater than or equal to 1"
    )

    testthat::expect_error(
      filter_community_by_minimum_core_count(
        data_community = data_test,
        minimum_core_count = -1
      ),
      "must be greater than or equal to 1"
    )
  }
)

testthat::test_that(
  "filter_community_by_minimum_core_count() errors when no taxa remain",
  {
    # All taxa appear in only 1 core
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Betula"),
        dataset_name = c("A", "B"),
        age = c(100, 200)
      )

    testthat::expect_error(
      filter_community_by_minimum_core_count(
        data_community = data_test,
        minimum_core_count = 3
      ),
      "No taxa remain"
    )
  }
)

testthat::test_that(
  "filter_community_by_minimum_core_count() keeps taxa present in enough cores",
  {
    # Pinus in 3 cores; Betula in 1 core
    data_test <-
      tibble::tibble(
        taxon = c(
          "Pinus", "Pinus", "Pinus",
          "Betula"
        ),
        dataset_name = c("A", "B", "C", "A"),
        age = c(100, 100, 100, 100)
      )

    res <-
      filter_community_by_minimum_core_count(
        data_community = data_test,
        minimum_core_count = 2
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
  "filter_community_by_minimum_core_count() default minimum_core_count is 2",
  {
    # Pinus in 2 cores; Betula in 1 core
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Pinus", "Betula"),
        dataset_name = c("A", "B", "A"),
        age = c(100, 100, 200)
      )

    res <-
      filter_community_by_minimum_core_count(data_community = data_test)

    vec_taxa <-
      dplyr::pull(res, taxon) |>
      unique()

    testthat::expect_true("Pinus" %in% vec_taxa)
    testthat::expect_false("Betula" %in% vec_taxa)
  }
)

testthat::test_that(
  "filter_community_by_minimum_core_count() returns a data frame",
  {
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Pinus", "Betula"),
        dataset_name = c("A", "B", "A"),
        age = c(100, 100, 200),
        value = c(0.1, 0.2, 0.05)
      )

    res <-
      filter_community_by_minimum_core_count(
        data_community = data_test,
        minimum_core_count = 2
      )

    testthat::expect_true(is.data.frame(res))
    testthat::expect_named(
      res,
      c("taxon", "dataset_name", "age", "value")
    )
  }
)

testthat::test_that(
  "filter_community_by_minimum_core_count() preserves all columns",
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
      filter_community_by_minimum_core_count(
        data_community = data_test,
        minimum_core_count = 2
      )

    testthat::expect_named(
      res,
      c("taxon", "dataset_name", "age", "value", "extra_col")
    )
  }
)

testthat::test_that(
  "minimum-core filter keeps all taxa at a threshold of one",
  {
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Betula", "Quercus"),
        dataset_name = c("A", "B", "C"),
        age = c(100, 200, 300)
      )

    res <-
      filter_community_by_minimum_core_count(
        data_community = data_test,
        minimum_core_count = 1
      )

    testthat::expect_equal(nrow(res), nrow(data_test))
  }
)
