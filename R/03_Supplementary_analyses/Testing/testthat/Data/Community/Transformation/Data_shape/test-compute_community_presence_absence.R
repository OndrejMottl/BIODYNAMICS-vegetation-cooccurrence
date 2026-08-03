testthat::test_that(
  "compute_community_presence_absence() rejects non-matrix inputs",
  {
    testthat::expect_error(
      compute_community_presence_absence(
        mat_community = base::data.frame(a = 1)
      )
    )
    testthat::expect_error(
      compute_community_presence_absence(
        mat_community = base::list(a = 1)
      )
    )
    testthat::expect_error(
      compute_community_presence_absence(
        mat_community = "string"
      )
    )
  }
)

testthat::test_that(
  "compute_community_presence_absence() rejects nonnumeric matrices",
  {
    mat_community_character <-
      base::matrix(
        base::c("a", "b", "c", "d"),
        nrow = 2
    )
    testthat::expect_error(
      compute_community_presence_absence(
        mat_community = mat_community_character
      )
    )
  }
)

testthat::test_that(
  "compute_community_presence_absence() rejects matrices without rows",
  {
    mat_community_without_rows <-
      base::matrix(
        base::numeric(0),
        nrow = 0,
        ncol = 3
    )
    testthat::expect_error(
      compute_community_presence_absence(
        mat_community = mat_community_without_rows
      )
    )
  }
)

testthat::test_that(
  "compute_community_presence_absence() rejects matrices without columns",
  {
    mat_community_without_columns <-
      base::matrix(
        base::numeric(0),
        nrow = 3,
        ncol = 0
    )
    testthat::expect_error(
      compute_community_presence_absence(
        mat_community = mat_community_without_columns
      )
    )
  }
)

testthat::test_that(
  "compute_community_presence_absence() rejects negative values",
  {
    mat_community_negative <-
      base::matrix(
        base::c(-1, 0.5, 0, 0.2),
        nrow = 2
      )
    testthat::expect_error(
      compute_community_presence_absence(mat_community = mat_community_negative)
    )
  }
)

testthat::test_that(
  "compute_community_presence_absence() returns an integer matrix",
  {
    mat_community <-
      base::matrix(
        base::c(0, 0.5, 0.1, 0),
        nrow = 2,
        dimnames = base::list(
          base::c("s1", "s2"),
          base::c("taxon_a", "taxon_b")
        )
      )
    res_community_presence_absence <-
      compute_community_presence_absence(mat_community = mat_community)
    testthat::expect_true(base::is.matrix(res_community_presence_absence))
    testthat::expect_true(base::is.integer(res_community_presence_absence))
  }
)

testthat::test_that(
  "compute_community_presence_absence() maps >0 to 1 and 0 to 0",
  {
    mat_community <-
      base::matrix(
        base::c(0, 0.5, 0.1, 0),
        nrow = 2,
        dimnames = base::list(
          base::c("s1", "s2"),
          base::c("taxon_a", "taxon_b")
        )
      )
    res_community_presence_absence <-
      compute_community_presence_absence(mat_community = mat_community)
    mat_presence_absence_expected <-
      base::matrix(
        base::c(0L, 1L, 1L, 0L),
        nrow = 2,
        dimnames = base::list(
          base::c("s1", "s2"),
          base::c("taxon_a", "taxon_b")
        )
      )
    testthat::expect_identical(
      res_community_presence_absence,
      mat_presence_absence_expected
    )
  }
)

testthat::test_that(
  "compute_community_presence_absence() maps NA to 0",
  {
    mat_community <-
      base::matrix(
        base::c(NA_real_, 0.5, 0, NA_real_),
        nrow = 2,
        dimnames = base::list(
          base::c("s1", "s2"),
          base::c("taxon_a", "taxon_b")
        )
      )
    res_community_presence_absence <-
      compute_community_presence_absence(mat_community = mat_community)
    mat_presence_absence_expected <-
      base::matrix(
        base::c(0L, 1L, 0L, 0L),
        nrow = 2,
        dimnames = base::list(
          base::c("s1", "s2"),
          base::c("taxon_a", "taxon_b")
        )
      )

    testthat::expect_identical(
      res_community_presence_absence,
      mat_presence_absence_expected
    )
  }
)

testthat::test_that(
  "compute_community_presence_absence() only contains 0 and 1",
  {
    mat_community <-
      base::matrix(
        base::c(0, 0.01, 0.99, 0.5, 0, 1.5),
        nrow = 3,
        ncol = 2
      )
    res_community_presence_absence <-
      compute_community_presence_absence(mat_community = mat_community)
    testthat::expect_true(
      base::all(res_community_presence_absence %in% base::c(0L, 1L))
    )
  }
)

testthat::test_that(
  "compute_community_presence_absence() preserves row names",
  {
    mat_community <-
      base::matrix(
        base::c(0, 0.5, 0.1, 0),
        nrow = 2,
        dimnames = base::list(
          base::c("sample_a__0", "sample_b__500"),
          base::c("Pinus", "Betula")
        )
      )
    res_community_presence_absence <-
      compute_community_presence_absence(mat_community = mat_community)
    testthat::expect_equal(
      base::rownames(res_community_presence_absence),
      base::c("sample_a__0", "sample_b__500")
    )
  }
)

testthat::test_that(
  "compute_community_presence_absence() preserves column names",
  {
    mat_community <-
      base::matrix(
        base::c(0, 0.5, 0.1, 0),
        nrow = 2,
        dimnames = base::list(
          base::c("sample_a__0", "sample_b__500"),
          base::c("Pinus", "Betula")
        )
      )
    res_community_presence_absence <-
      compute_community_presence_absence(mat_community = mat_community)
    testthat::expect_equal(
      base::colnames(res_community_presence_absence),
      base::c("Pinus", "Betula")
    )
  }
)

testthat::test_that(
  "compute_community_presence_absence() preserves matrix dimensions",
  {
    mat_community <-
      base::matrix(
        base::seq(0, 0.9, by = 0.1),
        nrow = 5,
        ncol = 2
      )
    res_community_presence_absence <-
      compute_community_presence_absence(mat_community = mat_community)
    testthat::expect_equal(base::nrow(res_community_presence_absence), 5L)
    testthat::expect_equal(base::ncol(res_community_presence_absence), 2L)
  }
)

testthat::test_that(
  "compute_community_presence_absence() preserves binary values",
  {
    mat_community <-
      base::matrix(
        base::c(0L, 1L, 1L, 0L),
        nrow = 2
      )
    res_community_presence_absence <-
      compute_community_presence_absence(mat_community = mat_community)
    testthat::expect_equal(
      base::as.integer(res_community_presence_absence),
      base::c(0L, 1L, 1L, 0L)
    )
  }
)

testthat::test_that(
  "compute_community_presence_absence() handles all-zero matrix",
  {
    mat_community <-
      base::matrix(
        0,
        nrow = 3,
        ncol = 4
      )
    res_community_presence_absence <-
      compute_community_presence_absence(mat_community = mat_community)
    testthat::expect_true(base::all(res_community_presence_absence == 0L))
  }
)

testthat::test_that(
  "compute_community_presence_absence() handles all-positive matrix",
  {
    mat_community <-
      base::matrix(
        base::c(0.1, 0.5, 0.9, 0.2),
        nrow = 2
      )
    res_community_presence_absence <-
      compute_community_presence_absence(mat_community = mat_community)
    testthat::expect_true(base::all(res_community_presence_absence == 1L))
  }
)

testthat::test_that(
  "compute_community_presence_absence() converts pollen data",
  {
    mat_community_pollen <-
      base::matrix(
        base::c(
          0.25, 0.10, 0.00,
          0.00, 0.30, 0.05,
          0.40, 0.00, 0.00
        ),
        nrow = 3,
        ncol = 3,
        byrow = TRUE,
        dimnames = base::list(
          base::c("site_a__0", "site_b__0", "site_c__0"),
          base::c("Pinus", "Betula", "Quercus")
        )
      )
    res_community_presence_absence <-
      compute_community_presence_absence(mat_community = mat_community_pollen)
    mat_presence_absence_expected <-
      base::matrix(
        base::c(
          1L, 1L, 0L,
          0L, 1L, 1L,
          1L, 0L, 0L
        ),
        nrow = 3,
        ncol = 3,
        byrow = TRUE,
        dimnames = base::list(
          base::c("site_a__0", "site_b__0", "site_c__0"),
          base::c("Pinus", "Betula", "Quercus")
        )
      )
    testthat::expect_identical(
      res_community_presence_absence,
      mat_presence_absence_expected
    )
  }
)

testthat::test_that(
  "compute_community_presence_absence() makes present taxa constant",
  {
    # This is the key correctness test: a taxon with varying
    # proportions but always > 0 must become constant after
    # presence-absence conversion so filter_constant_taxa() can remove it.
    mat_community_pollen <-
      base::matrix(
        base::c(0.25, 0.5, 0.10, 0.40),
        nrow = 2,
        dimnames = base::list(
          base::c("site_a__0", "site_b__0"),
          base::c("Pinus", "Betula")
        )
      )
    res_community_presence_absence <-
      compute_community_presence_absence(mat_community = mat_community_pollen)
    sd_pinus <-
      stats::sd(res_community_presence_absence[, "Pinus"])
    testthat::expect_equal(sd_pinus, 0)
  }
)
