testthat::test_that(
  "filter_constant_taxa() errors if input is not a matrix",
  {
    data_not_matrix <- base::as.data.frame(
      base::matrix(c(0, 1, 0, 1), nrow = 2)
    )
    testthat::expect_error(
      filter_constant_taxa(
        data_community_matrix = data_not_matrix
      )
    )
  }
)

testthat::test_that(
  "filter_constant_taxa() removes all-zero column (sd = 0)",
  {
    # Pinus: all zeros (constant); Betula: varies
    data_mat <- base::matrix(
      c(0, 0, 0.3, 0.8),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    res <- filter_constant_taxa(
      data_community_matrix = data_mat
    )
    testthat::expect_false(
      "Pinus" %in% base::colnames(res)
    )
    testthat::expect_true(
      "Betula" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "filter_constant_taxa() removes non-zero constant column",
  {
    # Betula: all 5 (constant, non-zero, sd = 0); Pinus: varies
    data_mat <- base::matrix(
      c(0, 3, 5, 5),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    res <- filter_constant_taxa(
      data_community_matrix = data_mat
    )
    testthat::expect_false(
      "Betula" %in% base::colnames(res)
    )
    testthat::expect_true(
      "Pinus" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "filter_constant_taxa() keeps all varying columns",
  {
    # Both columns vary -> both retained
    data_mat <- base::matrix(
      c(0, 0.5, 0.4, 0),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    res <- filter_constant_taxa(
      data_community_matrix = data_mat
    )
    testthat::expect_equal(
      base::sort(base::colnames(res)),
      c("Betula", "Pinus")
    )
  }
)

testthat::test_that(
  "filter_constant_taxa() result is still a matrix",
  {
    data_mat <- base::matrix(
      c(0, 0.5, 0.3, 0),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    res <- filter_constant_taxa(
      data_community_matrix = data_mat
    )
    testthat::expect_true(
      base::is.matrix(res)
    )
  }
)

testthat::test_that(
  "filter_constant_taxa() preserves row structure",
  {
    data_mat <- base::matrix(
      c(0, 0.5, 0.3, 0),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    res <- filter_constant_taxa(
      data_community_matrix = data_mat
    )
    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_equal(
      base::rownames(res),
      c("A__0", "B__0")
    )
  }
)

testthat::test_that(
  "filter_constant_taxa() all constant cols -> 0-col matrix",
  {
    # All columns constant -> result has zero columns
    data_mat <- base::matrix(
      c(1, 1, 2, 2),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    res <- filter_constant_taxa(
      data_community_matrix = data_mat
    )
    testthat::expect_true(
      base::is.matrix(res)
    )
    testthat::expect_equal(base::ncol(res), 0L)
    testthat::expect_equal(base::nrow(res), 2L)
  }
)

testthat::test_that(
  "filter_constant_taxa() all-variable matrix unchanged",
  {
    data_mat <- base::matrix(
      c(0, 1, 1, 0),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    res <- filter_constant_taxa(
      data_community_matrix = data_mat
    )
    testthat::expect_equal(res, data_mat)
  }
)

testthat::test_that(
  "filter_constant_taxa() works with continuous data",
  {
    # Gaussian-style continuous data: Pinus constant, Betula varies
    data_mat <- base::matrix(
      c(2.5, 2.5, 0.3, 1.8),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    res <- filter_constant_taxa(
      data_community_matrix = data_mat
    )
    testthat::expect_false(
      "Pinus" %in% base::colnames(res)
    )
    testthat::expect_true(
      "Betula" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "filter_constant_taxa() works with count data",
  {
    # Poisson-style count data: Pinus constant (all 3)
    data_mat <- base::matrix(
      c(3L, 3L, 1L, 5L),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    res <- filter_constant_taxa(
      data_community_matrix = data_mat
    )
    testthat::expect_false(
      "Pinus" %in% base::colnames(res)
    )
    testthat::expect_true(
      "Betula" %in% base::colnames(res)
    )
  }
)
