testthat::test_that(
  "filter_constant_taxa() errors if input is not a matrix",
  {
    data_not_matrix <- base::as.data.frame(
      base::matrix(c(0, 1, 0, 1), nrow = 2)
    )
    testthat::expect_error(
      filter_constant_taxa(
        data_community_matrix = data_not_matrix,
        error_family = "binomial"
      )
    )
  }
)

testthat::test_that(
  "filter_constant_taxa() errors on invalid error_family value",
  {
    data_mat <- base::matrix(
      c(0.5, 0.3, 0.2, 0.8),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    testthat::expect_error(
      filter_constant_taxa(
        data_community_matrix = data_mat,
        error_family = "poisson"
      )
    )
  }
)

testthat::test_that(
  "filter_constant_taxa() gaussian returns unchanged matrix",
  {
    data_mat <- base::matrix(
      c(0.5, 0.5, 0.3, 0.3),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    res <- filter_constant_taxa(
      data_community_matrix = data_mat,
      error_family = "gaussian"
    )
    testthat::expect_equal(res, data_mat)
  }
)

testthat::test_that(
  "filter_constant_taxa() binomial keeps variable taxa",
  {
    # Pinus varies (0 and 1), Betula constant (all 1)
    data_mat <- base::matrix(
      c(0, 1, 1, 1),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    res <- filter_constant_taxa(
      data_community_matrix = data_mat,
      error_family = "binomial"
    )
    testthat::expect_true(
      "Pinus" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "filter_constant_taxa() binomial removes all-absent taxa",
  {
    # Pinus: always 0 (all absent); Betula: 0 and 0.8 (varies)
    data_mat <- base::matrix(
      c(0, 0, 0, 0.8),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    res <- filter_constant_taxa(
      data_community_matrix = data_mat,
      error_family = "binomial"
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
  "filter_constant_taxa() binomial removes all-present taxa",
  {
    # Betula is always > 0 (always present)
    data_mat <- base::matrix(
      c(0.5, 0.3, 0.8, 0.6),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    res <- filter_constant_taxa(
      data_community_matrix = data_mat,
      error_family = "binomial"
    )
    testthat::expect_false(
      "Betula" %in% base::colnames(res)
    )
    testthat::expect_false(
      "Pinus" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "filter_constant_taxa() binomial result is still a matrix",
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
      data_community_matrix = data_mat,
      error_family = "binomial"
    )
    testthat::expect_true(
      base::is.matrix(res)
    )
  }
)

testthat::test_that(
  "filter_constant_taxa() binomial preserves row structure",
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
      data_community_matrix = data_mat,
      error_family = "binomial"
    )
    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_equal(
      base::rownames(res),
      c("A__0", "B__0")
    )
  }
)

testthat::test_that(
  "filter_constant_taxa() binomial: all-variable matrix unchanged",
  {
    # Both taxa vary across samples
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
      data_community_matrix = data_mat,
      error_family = "binomial"
    )
    testthat::expect_equal(
      base::sort(base::colnames(res)),
      c("Betula", "Pinus")
    )
  }
)

testthat::test_that(
  "filter_constant_taxa() uses > 0 for presence detection",
  {
    # 0.001 should count as present (> 0)
    data_mat <- base::matrix(
      c(0, 0.001, 0.5, 0.3),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    res <- filter_constant_taxa(
      data_community_matrix = data_mat,
      error_family = "binomial"
    )
    # Pinus: sample1=0 (absent), sample2=0.001 (present) -> variable
    testthat::expect_true(
      "Pinus" %in% base::colnames(res)
    )
  }
)
