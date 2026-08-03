testthat::test_that(
  "validate_community_taxon_count() validates matrix input",
  {
    testthat::expect_error(
      validate_community_taxon_count(
        data_community_matrix = "not a matrix",
        minimum_taxon_count = 5
      ),
      regexp = "matrix"
    )

    testthat::expect_error(
      validate_community_taxon_count(
        data_community_matrix = data.frame(a = 1, b = 2),
        minimum_taxon_count = 5
      ),
      regexp = "matrix"
    )

    testthat::expect_error(
      validate_community_taxon_count(
        data_community_matrix = NULL,
        minimum_taxon_count = 5
      ),
      regexp = "matrix"
    )
  }
)


testthat::test_that(
  "validate_community_taxon_count() validates minimum_taxon_count argument",
  {
    mat_valid <-
      base::matrix(
        c(1, 0, 0, 1, 1, 0, 0, 1, 1, 1),
        nrow = 2,
        ncol = 5
      )

    testthat::expect_error(
      validate_community_taxon_count(
        data_community_matrix = mat_valid,
        minimum_taxon_count = 0
      ),
      regexp = "minimum_taxon_count"
    )

    testthat::expect_error(
      validate_community_taxon_count(
        data_community_matrix = mat_valid,
        minimum_taxon_count = -1
      ),
      regexp = "minimum_taxon_count"
    )

    testthat::expect_error(
      validate_community_taxon_count(
        data_community_matrix = mat_valid,
        minimum_taxon_count = "five"
      ),
      regexp = "minimum_taxon_count"
    )

    testthat::expect_error(
      validate_community_taxon_count(
        data_community_matrix = mat_valid,
        minimum_taxon_count = c(3, 5)
      ),
      regexp = "minimum_taxon_count"
    )
  }
)


testthat::test_that(
  "validate_community_taxon_count() passes matrix at exact threshold",
  {
    mat_exact <-
      base::matrix(
        c(1, 0, 0, 1, 1, 0, 0, 1, 1, 1),
        nrow = 2,
        ncol = 5
      )

    res <-
      validate_community_taxon_count(
        data_community_matrix = mat_exact,
        minimum_taxon_count = 5
      )

    testthat::expect_true(
      base::is.matrix(res)
    )

    testthat::expect_equal(
      base::ncol(res),
      5L
    )

    testthat::expect_equal(
      res,
      mat_exact
    )
  }
)


testthat::test_that(
  "validate_community_taxon_count() passes matrix above threshold",
  {
    mat_above <-
      base::matrix(
        base::seq_len(14),
        nrow = 2,
        ncol = 7
      )

    res <-
      validate_community_taxon_count(
        data_community_matrix = mat_above,
        minimum_taxon_count = 5
      )

    testthat::expect_true(
      base::is.matrix(res)
    )

    testthat::expect_equal(
      base::ncol(res),
      7L
    )

    testthat::expect_equal(
      res,
      mat_above
    )
  }
)


testthat::test_that(
  "validate_community_taxon_count() errors below threshold",
  {
    mat_few <-
      base::matrix(
        c(1, 0, 0, 1, 1, 0, 0, 1),
        nrow = 2,
        ncol = 4
      )

    testthat::expect_error(
      validate_community_taxon_count(
        data_community_matrix = mat_few,
        minimum_taxon_count = 5
      ),
      regexp = "taxa"
    )
  }
)


testthat::test_that(
  "validate_community_taxon_count() errors with zero-column matrix",
  {
    mat_empty <-
      base::matrix(
        base::numeric(0),
        nrow = 2,
        ncol = 0
      )

    testthat::expect_error(
      validate_community_taxon_count(
        data_community_matrix = mat_empty,
        minimum_taxon_count = 5
      ),
      regexp = "taxa"
    )
  }
)


testthat::test_that(
  "validate_community_taxon_count() preserves row and col names",
  {
    mat_named <-
      base::matrix(
        c(1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0),
        nrow = 2,
        ncol = 6
      )

    base::rownames(mat_named) <- c("site_a__100", "site_b__200")
    base::colnames(mat_named) <- c(
      "sp1", "sp2", "sp3", "sp4", "sp5", "sp6"
    )

    res <-
      validate_community_taxon_count(
        data_community_matrix = mat_named,
        minimum_taxon_count = 5
      )

    testthat::expect_equal(
      base::rownames(res),
      c("site_a__100", "site_b__200")
    )

    testthat::expect_equal(
      base::colnames(res),
      c("sp1", "sp2", "sp3", "sp4", "sp5", "sp6")
    )
  }
)


testthat::test_that(
  "validate_community_taxon_count() respects custom minimum_taxon_count",
  {
    mat_three <-
      base::matrix(
        c(1, 0, 0, 1, 0, 1),
        nrow = 2,
        ncol = 3
      )

    res <-
      validate_community_taxon_count(
        data_community_matrix = mat_three,
        minimum_taxon_count = 3
      )

    testthat::expect_equal(
      base::ncol(res),
      3L
    )

    testthat::expect_error(
      validate_community_taxon_count(
        data_community_matrix = mat_three,
        minimum_taxon_count = 4
      ),
      regexp = "taxa"
    )
  }
)
