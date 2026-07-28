testthat::test_that(
  "filter_community_by_n_taxa() validates matrix input",
  {
    testthat::expect_error(
      filter_community_by_n_taxa(
        data_community_matrix = "not a matrix",
        min_n_taxa = 5
      ),
      regexp = "matrix"
    )

    testthat::expect_error(
      filter_community_by_n_taxa(
        data_community_matrix = data.frame(a = 1, b = 2),
        min_n_taxa = 5
      ),
      regexp = "matrix"
    )

    testthat::expect_error(
      filter_community_by_n_taxa(
        data_community_matrix = NULL,
        min_n_taxa = 5
      ),
      regexp = "matrix"
    )
  }
)


testthat::test_that(
  "filter_community_by_n_taxa() validates min_n_taxa argument",
  {
    mat_valid <-
      base::matrix(
        c(1, 0, 0, 1, 1, 0, 0, 1, 1, 1),
        nrow = 2,
        ncol = 5
      )

    testthat::expect_error(
      filter_community_by_n_taxa(
        data_community_matrix = mat_valid,
        min_n_taxa = 0
      ),
      regexp = "min_n_taxa"
    )

    testthat::expect_error(
      filter_community_by_n_taxa(
        data_community_matrix = mat_valid,
        min_n_taxa = -1
      ),
      regexp = "min_n_taxa"
    )

    testthat::expect_error(
      filter_community_by_n_taxa(
        data_community_matrix = mat_valid,
        min_n_taxa = "five"
      ),
      regexp = "min_n_taxa"
    )

    testthat::expect_error(
      filter_community_by_n_taxa(
        data_community_matrix = mat_valid,
        min_n_taxa = c(3, 5)
      ),
      regexp = "min_n_taxa"
    )
  }
)


testthat::test_that(
  "filter_community_by_n_taxa() passes matrix at exact threshold",
  {
    mat_exact <-
      base::matrix(
        c(1, 0, 0, 1, 1, 0, 0, 1, 1, 1),
        nrow = 2,
        ncol = 5
      )

    res <-
      filter_community_by_n_taxa(
        data_community_matrix = mat_exact,
        min_n_taxa = 5
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
  "filter_community_by_n_taxa() passes matrix above threshold",
  {
    mat_above <-
      base::matrix(
        base::seq_len(14),
        nrow = 2,
        ncol = 7
      )

    res <-
      filter_community_by_n_taxa(
        data_community_matrix = mat_above,
        min_n_taxa = 5
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
  "filter_community_by_n_taxa() errors below threshold",
  {
    mat_few <-
      base::matrix(
        c(1, 0, 0, 1, 1, 0, 0, 1),
        nrow = 2,
        ncol = 4
      )

    testthat::expect_error(
      filter_community_by_n_taxa(
        data_community_matrix = mat_few,
        min_n_taxa = 5
      ),
      regexp = "taxa"
    )
  }
)


testthat::test_that(
  "filter_community_by_n_taxa() errors with zero-column matrix",
  {
    mat_empty <-
      base::matrix(
        base::numeric(0),
        nrow = 2,
        ncol = 0
      )

    testthat::expect_error(
      filter_community_by_n_taxa(
        data_community_matrix = mat_empty,
        min_n_taxa = 5
      ),
      regexp = "taxa"
    )
  }
)


testthat::test_that(
  "filter_community_by_n_taxa() preserves row and col names",
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
      filter_community_by_n_taxa(
        data_community_matrix = mat_named,
        min_n_taxa = 5
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
  "filter_community_by_n_taxa() respects custom min_n_taxa",
  {
    mat_three <-
      base::matrix(
        c(1, 0, 0, 1, 0, 1),
        nrow = 2,
        ncol = 3
      )

    res <-
      filter_community_by_n_taxa(
        data_community_matrix = mat_three,
        min_n_taxa = 3
      )

    testthat::expect_equal(
      base::ncol(res),
      3L
    )

    testthat::expect_error(
      filter_community_by_n_taxa(
        data_community_matrix = mat_three,
        min_n_taxa = 4
      ),
      regexp = "taxa"
    )
  }
)
