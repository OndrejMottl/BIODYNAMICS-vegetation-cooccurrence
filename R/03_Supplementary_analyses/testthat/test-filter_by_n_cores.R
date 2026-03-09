testthat::test_that(
  "filter_by_n_cores() errors when data is not a data frame",
  {
    testthat::expect_error(
      filter_by_n_cores(data = "not a data frame"),
      "must be a data frame"
    )

    testthat::expect_error(
      filter_by_n_cores(data = NULL),
      "must be a data frame"
    )

    testthat::expect_error(
      filter_by_n_cores(data = list(taxon = "Pinus", dataset_name = "A")),
      "must be a data frame"
    )

    testthat::expect_error(
      filter_by_n_cores(data = matrix(1:4, nrow = 2)),
      "must be a data frame"
    )
  }
)

testthat::test_that(
  "filter_by_n_cores() errors when required columns are missing",
  {
    data_no_taxon <-
      tibble::tibble(dataset_name = c("A", "B"), value = c(1, 2))

    data_no_dataset <-
      tibble::tibble(taxon = c("Pinus", "Betula"), value = c(1, 2))

    testthat::expect_error(
      filter_by_n_cores(data = data_no_taxon),
      "must contain columns"
    )

    testthat::expect_error(
      filter_by_n_cores(data = data_no_dataset),
      "must contain columns"
    )
  }
)

testthat::test_that(
  "filter_by_n_cores() errors when min_n_cores is not numeric",
  {
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Betula"),
        dataset_name = c("A", "B")
      )

    testthat::expect_error(
      filter_by_n_cores(data = data_test, min_n_cores = "2"),
      "must be a single numeric value"
    )

    testthat::expect_error(
      filter_by_n_cores(data = data_test, min_n_cores = NULL),
      "must be a single numeric value"
    )

    testthat::expect_error(
      filter_by_n_cores(data = data_test, min_n_cores = TRUE),
      "must be a single numeric value"
    )

    testthat::expect_error(
      filter_by_n_cores(data = data_test, min_n_cores = c(1, 2)),
      "must be a single numeric value"
    )
  }
)

testthat::test_that(
  "filter_by_n_cores() errors when min_n_cores is less than 1",
  {
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Betula"),
        dataset_name = c("A", "B")
      )

    testthat::expect_error(
      filter_by_n_cores(data = data_test, min_n_cores = 0),
      "must be greater than or equal to 1"
    )

    testthat::expect_error(
      filter_by_n_cores(data = data_test, min_n_cores = -1),
      "must be greater than or equal to 1"
    )
  }
)

testthat::test_that(
  "filter_by_n_cores() errors when no taxa remain",
  {
    # All taxa appear in only 1 core
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Betula"),
        dataset_name = c("A", "B"),
        age = c(100, 200)
      )

    testthat::expect_error(
      filter_by_n_cores(data = data_test, min_n_cores = 3),
      "No taxa remain"
    )
  }
)

testthat::test_that(
  "filter_by_n_cores() keeps taxa present in enough cores",
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
      filter_by_n_cores(data = data_test, min_n_cores = 2)

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
  "filter_by_n_cores() default min_n_cores is 2",
  {
    # Pinus in 2 cores; Betula in 1 core
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Pinus", "Betula"),
        dataset_name = c("A", "B", "A"),
        age = c(100, 100, 200)
      )

    res <-
      filter_by_n_cores(data = data_test)

    vec_taxa <-
      dplyr::pull(res, taxon) |>
      unique()

    testthat::expect_true("Pinus" %in% vec_taxa)
    testthat::expect_false("Betula" %in% vec_taxa)
  }
)

testthat::test_that(
  "filter_by_n_cores() returns a data frame",
  {
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Pinus", "Betula"),
        dataset_name = c("A", "B", "A"),
        age = c(100, 100, 200),
        pollen_prop = c(0.1, 0.2, 0.05)
      )

    res <-
      filter_by_n_cores(data = data_test, min_n_cores = 2)

    testthat::expect_true(is.data.frame(res))
    testthat::expect_named(
      res,
      c("taxon", "dataset_name", "age", "pollen_prop")
    )
  }
)

testthat::test_that(
  "filter_by_n_cores() preserves all columns",
  {
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Pinus"),
        dataset_name = c("A", "B"),
        age = c(100, 200),
        pollen_prop = c(0.1, 0.2),
        extra_col = c("x", "y")
      )

    res <-
      filter_by_n_cores(data = data_test, min_n_cores = 2)

    testthat::expect_named(
      res,
      c("taxon", "dataset_name", "age", "pollen_prop", "extra_col")
    )
  }
)

testthat::test_that(
  "filter_by_n_cores() handles min_n_cores = 1 (keeps all taxa)",
  {
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Betula", "Quercus"),
        dataset_name = c("A", "B", "C"),
        age = c(100, 200, 300)
      )

    res <-
      filter_by_n_cores(data = data_test, min_n_cores = 1)

    testthat::expect_equal(nrow(res), nrow(data_test))
  }
)
