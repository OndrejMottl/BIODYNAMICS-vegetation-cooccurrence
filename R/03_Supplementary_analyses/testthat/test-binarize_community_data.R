testthat::test_that(
  "binarize_community_data() errors if not a matrix",
  {
    testthat::expect_error(
      binarize_community_data(
        data_community_matrix = base::data.frame(a = 1)
      )
    )
    testthat::expect_error(
      binarize_community_data(
        data_community_matrix = base::list(a = 1)
      )
    )
    testthat::expect_error(
      binarize_community_data(
        data_community_matrix = "string"
      )
    )
  }
)

testthat::test_that(
  "binarize_community_data() errors if matrix is not numeric",
  {
    mat_char <-
      base::matrix(
        c("a", "b", "c", "d"),
        nrow = 2
      )
    testthat::expect_error(
      binarize_community_data(data_community_matrix = mat_char)
    )
  }
)

testthat::test_that(
  "binarize_community_data() errors on zero-row matrix",
  {
    mat_empty <-
      base::matrix(
        base::numeric(0),
        nrow = 0,
        ncol = 3
      )
    testthat::expect_error(
      binarize_community_data(data_community_matrix = mat_empty)
    )
  }
)

testthat::test_that(
  "binarize_community_data() errors on zero-col matrix",
  {
    mat_no_col <-
      base::matrix(
        base::numeric(0),
        nrow = 3,
        ncol = 0
      )
    testthat::expect_error(
      binarize_community_data(data_community_matrix = mat_no_col)
    )
  }
)

testthat::test_that(
  "binarize_community_data() errors on negative values",
  {
    mat_neg <-
      base::matrix(
        c(-1, 0.5, 0, 0.2),
        nrow = 2
      )
    testthat::expect_error(
      binarize_community_data(data_community_matrix = mat_neg)
    )
  }
)

testthat::test_that(
  "binarize_community_data() returns an integer matrix",
  {
    mat_in <-
      base::matrix(
        c(0, 0.5, 0.1, 0),
        nrow = 2,
        dimnames = base::list(
          c("s1", "s2"),
          c("taxon_a", "taxon_b")
        )
      )
    res <-
      binarize_community_data(data_community_matrix = mat_in)
    testthat::expect_true(base::is.matrix(res))
    testthat::expect_true(base::is.integer(res))
  }
)

testthat::test_that(
  "binarize_community_data() maps >0 to 1 and 0 to 0",
  {
    mat_in <-
      base::matrix(
        c(0, 0.5, 0.1, 0),
        nrow = 2,
        dimnames = base::list(
          c("s1", "s2"),
          c("taxon_a", "taxon_b")
        )
      )
    res <-
      binarize_community_data(data_community_matrix = mat_in)
    mat_expected <-
      base::matrix(
        c(0L, 1L, 1L, 0L),
        nrow = 2,
        dimnames = base::list(
          c("s1", "s2"),
          c("taxon_a", "taxon_b")
        )
      )
    testthat::expect_identical(res, mat_expected)
  }
)

testthat::test_that(
  "binarize_community_data() only contains 0 and 1",
  {
    mat_in <-
      base::matrix(
        c(0, 0.01, 0.99, 0.5, 0, 1.5),
        nrow = 3,
        ncol = 2
      )
    res <-
      binarize_community_data(data_community_matrix = mat_in)
    testthat::expect_true(
      base::all(res %in% c(0L, 1L))
    )
  }
)

testthat::test_that(
  "binarize_community_data() preserves row names",
  {
    mat_in <-
      base::matrix(
        c(0, 0.5, 0.1, 0),
        nrow = 2,
        dimnames = base::list(
          c("sample_a__0", "sample_b__500"),
          c("Pinus", "Betula")
        )
      )
    res <-
      binarize_community_data(data_community_matrix = mat_in)
    testthat::expect_equal(
      base::rownames(res),
      c("sample_a__0", "sample_b__500")
    )
  }
)

testthat::test_that(
  "binarize_community_data() preserves column names",
  {
    mat_in <-
      base::matrix(
        c(0, 0.5, 0.1, 0),
        nrow = 2,
        dimnames = base::list(
          c("sample_a__0", "sample_b__500"),
          c("Pinus", "Betula")
        )
      )
    res <-
      binarize_community_data(data_community_matrix = mat_in)
    testthat::expect_equal(
      base::colnames(res),
      c("Pinus", "Betula")
    )
  }
)

testthat::test_that(
  "binarize_community_data() preserves matrix dimensions",
  {
    mat_in <-
      base::matrix(
        seq(0, 0.9, by = 0.1),
        nrow = 5,
        ncol = 2
      )
    res <-
      binarize_community_data(data_community_matrix = mat_in)
    testthat::expect_equal(base::nrow(res), 5L)
    testthat::expect_equal(base::ncol(res), 2L)
  }
)

testthat::test_that(
  "binarize_community_data() treats already-binary matrix correctly",
  {
    mat_in <-
      base::matrix(
        c(0L, 1L, 1L, 0L),
        nrow = 2
      )
    res <-
      binarize_community_data(data_community_matrix = mat_in)
    testthat::expect_equal(
      base::as.integer(res),
      c(0L, 1L, 1L, 0L)
    )
  }
)

testthat::test_that(
  "binarize_community_data() handles all-zero matrix",
  {
    mat_in <-
      base::matrix(
        0,
        nrow = 3,
        ncol = 4
      )
    res <-
      binarize_community_data(data_community_matrix = mat_in)
    testthat::expect_true(base::all(res == 0L))
  }
)

testthat::test_that(
  "binarize_community_data() handles all-positive matrix",
  {
    mat_in <-
      base::matrix(
        c(0.1, 0.5, 0.9, 0.2),
        nrow = 2
      )
    res <-
      binarize_community_data(data_community_matrix = mat_in)
    testthat::expect_true(base::all(res == 1L))
  }
)

testthat::test_that(
  "binarize_community_data() correctly binarizes real pollen data",
  {
    mat_pollen <-
      base::matrix(
        c(
          0.25, 0.10, 0.00,
          0.00, 0.30, 0.05,
          0.40, 0.00, 0.00
        ),
        nrow = 3,
        ncol = 3,
        byrow = TRUE,
        dimnames = base::list(
          c("site_a__0", "site_b__0", "site_c__0"),
          c("Pinus", "Betula", "Quercus")
        )
      )
    res <-
      binarize_community_data(data_community_matrix = mat_pollen)
    mat_expected <-
      base::matrix(
        c(
          1L, 1L, 0L,
          0L, 1L, 1L,
          1L, 0L, 0L
        ),
        nrow = 3,
        ncol = 3,
        byrow = TRUE,
        dimnames = base::list(
          c("site_a__0", "site_b__0", "site_c__0"),
          c("Pinus", "Betula", "Quercus")
        )
      )
    testthat::expect_identical(res, mat_expected)
  }
)

testthat::test_that(
  "binarize_community_data() makes always-present taxon constant",
  {
    # This is the key correctness test: a taxon with varying
    # proportions but always > 0 must become constant after
    # binarization so filter_constant_taxa() can remove it.
    mat_pollen <-
      base::matrix(
        c(0.25, 0.5, 0.10, 0.40),
        nrow = 2,
        dimnames = base::list(
          c("site_a__0", "site_b__0"),
          c("Pinus", "Betula")
        )
      )
    res <-
      binarize_community_data(data_community_matrix = mat_pollen)
    sd_pinus <-
      stats::sd(res[, "Pinus"])
    testthat::expect_equal(sd_pinus, 0)
  }
)
