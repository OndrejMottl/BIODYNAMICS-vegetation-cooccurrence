testthat::test_that(
  "filter_by_n_samples() errors when data is not a data frame",
  {
    testthat::expect_error(
      filter_by_n_samples(data = "not a data frame"),
      "must be a data frame"
    )

    testthat::expect_error(
      filter_by_n_samples(data = NULL),
      "must be a data frame"
    )

    testthat::expect_error(
      filter_by_n_samples(
        data = list(taxon = "Pinus", dataset_name = "A", age = 100)
      ),
      "must be a data frame"
    )

    testthat::expect_error(
      filter_by_n_samples(data = matrix(1:4, nrow = 2)),
      "must be a data frame"
    )
  }
)

testthat::test_that(
  "filter_by_n_samples() errors when required columns are missing",
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
      filter_by_n_samples(data = data_no_taxon),
      "must contain columns"
    )

    testthat::expect_error(
      filter_by_n_samples(data = data_no_dataset),
      "must contain columns"
    )

    testthat::expect_error(
      filter_by_n_samples(data = data_no_age),
      "must contain columns"
    )
  }
)

testthat::test_that(
  "filter_by_n_samples() errors when min_n_samples is not numeric",
  {
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Betula"),
        dataset_name = c("A", "B"),
        age = c(100, 200)
      )

    testthat::expect_error(
      filter_by_n_samples(data = data_test, min_n_samples = "5"),
      "must be a single numeric value"
    )

    testthat::expect_error(
      filter_by_n_samples(data = data_test, min_n_samples = NULL),
      "must be a single numeric value"
    )

    testthat::expect_error(
      filter_by_n_samples(data = data_test, min_n_samples = TRUE),
      "must be a single numeric value"
    )

    testthat::expect_error(
      filter_by_n_samples(data = data_test, min_n_samples = c(1, 5)),
      "must be a single numeric value"
    )
  }
)

testthat::test_that(
  "filter_by_n_samples() errors when min_n_samples is less than 1",
  {
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Betula"),
        dataset_name = c("A", "B"),
        age = c(100, 200)
      )

    testthat::expect_error(
      filter_by_n_samples(data = data_test, min_n_samples = 0),
      "must be greater than or equal to 1"
    )

    testthat::expect_error(
      filter_by_n_samples(data = data_test, min_n_samples = -5),
      "must be greater than or equal to 1"
    )
  }
)

testthat::test_that(
  "filter_by_n_samples() errors when no taxa remain",
  {
    # Each taxon appears in only 1 sample
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Betula"),
        dataset_name = c("A", "B"),
        age = c(100, 200)
      )

    testthat::expect_error(
      filter_by_n_samples(data = data_test, min_n_samples = 5),
      "No taxa remain"
    )
  }
)

testthat::test_that(
  "filter_by_n_samples() keeps taxa in enough spatio-temporal samples",
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
      filter_by_n_samples(data = data_test, min_n_samples = 3)

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
  "filter_by_n_samples() default min_n_samples is 1 (keeps all)",
  {
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Betula", "Quercus"),
        dataset_name = c("A", "B", "C"),
        age = c(100, 200, 300)
      )

    res <-
      filter_by_n_samples(data = data_test)

    testthat::expect_equal(nrow(res), nrow(data_test))
  }
)

testthat::test_that(
  "filter_by_n_samples() counts unique dataset-age combinations",
  {
    # Pinus has 2 rows in same dataset+age -> counts as 1 sample
    # Pinus also appears in a second sample
    # Betula appears in only 1 sample
    data_test <-
      tibble::tibble(
        taxon = c("Pinus", "Pinus", "Pinus", "Betula"),
        dataset_name = c("A", "A", "A", "A"),
        age = c(100, 100, 200, 100),
        pollen_prop = c(0.1, 0.2, 0.1, 0.05)
      )

    # Pinus: 2 unique (dataset_name, age) = (A,100) and (A,200) -> kept
    # Betula: 1 unique sample -> also kept since min_n_samples=2 only
    # keeps Pinus
    res <-
      filter_by_n_samples(data = data_test, min_n_samples = 2)

    vec_taxa <-
      dplyr::pull(res, taxon) |>
      unique()

    testthat::expect_true("Pinus" %in% vec_taxa)
    testthat::expect_false("Betula" %in% vec_taxa)
  }
)

testthat::test_that(
  "filter_by_n_samples() returns a data frame and preserves cols",
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
      filter_by_n_samples(data = data_test, min_n_samples = 2)

    testthat::expect_true(is.data.frame(res))
    testthat::expect_named(
      res,
      c("taxon", "dataset_name", "age", "pollen_prop", "extra_col")
    )
  }
)
