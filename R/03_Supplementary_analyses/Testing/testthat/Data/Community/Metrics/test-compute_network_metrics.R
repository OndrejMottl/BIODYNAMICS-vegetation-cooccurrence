# Helper: minimal valid data_to_fit list
make_data_to_fit <- function(mat) {
  base::list(
    data_community_to_fit = mat,
    data_abiotic_to_fit = base::data.frame(dummy = 1),
    scale_attributes = base::list()
  )
}

# Helper: small binary-ish community matrix (2 samples x 3 taxa)
make_mat <- function() {
  base::matrix(
    c(
      0.5, 0.0, 0.3,
      0.0, 0.8, 0.1
    ),
    nrow = 2,
    ncol = 3,
    byrow = TRUE,
    dimnames = base::list(
      c("sample_a", "sample_b"),
      c("taxon_1", "taxon_2", "taxon_3")
    )
  )
}


# ── Input validation ──────────────────────────────────────────────────────────

testthat::test_that(
  "compute_network_metrics() errors when data_to_fit is not a list",
  {
    testthat::expect_error(
      compute_network_metrics(data_to_fit = "not_a_list")
    )
    testthat::expect_error(
      compute_network_metrics(data_to_fit = 42L)
    )
    testthat::expect_error(
      compute_network_metrics(data_to_fit = NULL)
    )
  }
)

testthat::test_that(
  "compute_network_metrics() errors if community element missing",
  {
    list_bad <-
      base::list(wrong_name = base::matrix(1, nrow = 1))
    testthat::expect_error(
      compute_network_metrics(data_to_fit = list_bad)
    )
  }
)

testthat::test_that(
  "compute_network_metrics() errors if community is not a matrix",
  {
    list_bad <-
      base::list(
        data_community_to_fit = base::data.frame(a = 1)
      )
    testthat::expect_error(
      compute_network_metrics(data_to_fit = list_bad)
    )
  }
)

testthat::test_that(
  "compute_network_metrics() errors if community is not numeric",
  {
    mat_char <-
      base::matrix(c("a", "b", "c", "d"), nrow = 2)
    list_bad <-
      base::list(data_community_to_fit = mat_char)
    testthat::expect_error(
      compute_network_metrics(data_to_fit = list_bad)
    )
  }
)

testthat::test_that(
  "compute_network_metrics() errors when vec_indices is not character",
  {
    data_fit <-
      make_data_to_fit(make_mat())
    testthat::expect_error(
      compute_network_metrics(
        data_to_fit = data_fit,
        vec_indices = 1L
      )
    )
  }
)

testthat::test_that(
  "compute_network_metrics() errors when vec_indices is empty",
  {
    data_fit <-
      make_data_to_fit(make_mat())
    testthat::expect_error(
      compute_network_metrics(
        data_to_fit = data_fit,
        vec_indices = base::character(0)
      )
    )
  }
)

testthat::test_that(
  "compute_network_metrics() errors when matrix has no presences",
  {
    mat_zero <-
      base::matrix(
        c(0, 0, 0, 0),
        nrow = 2,
        ncol = 2
      )
    list_zero <-
      base::list(data_community_to_fit = mat_zero)
    testthat::expect_error(
      compute_network_metrics(data_to_fit = list_zero)
    )
  }
)


# ── Output structure ──────────────────────────────────────────────────────────

testthat::test_that(
  "compute_network_metrics() returns a tibble",
  {
    data_fit <-
      make_data_to_fit(make_mat())
    res <-
      compute_network_metrics(data_to_fit = data_fit)
    testthat::expect_s3_class(res, "tbl_df")
  }
)

testthat::test_that(
  "compute_network_metrics() tibble has columns metric and value",
  {
    data_fit <-
      make_data_to_fit(make_mat())
    res <-
      compute_network_metrics(data_to_fit = data_fit)
    testthat::expect_true("metric" %in% names(res))
    testthat::expect_true("value" %in% names(res))
  }
)

testthat::test_that(
  "compute_network_metrics() metric column is character",
  {
    data_fit <-
      make_data_to_fit(make_mat())
    res <-
      compute_network_metrics(data_to_fit = data_fit)
    testthat::expect_type(
      dplyr::pull(res, metric),
      "character"
    )
  }
)

testthat::test_that(
  "compute_network_metrics() value column is numeric",
  {
    data_fit <-
      make_data_to_fit(make_mat())
    res <-
      compute_network_metrics(data_to_fit = data_fit)
    testthat::expect_type(
      dplyr::pull(res, value),
      "double"
    )
  }
)

testthat::test_that(
  "compute_network_metrics() returns one row per index",
  {
    data_fit <-
      make_data_to_fit(make_mat())
    res <-
      compute_network_metrics(
        data_to_fit = data_fit,
        vec_indices = c("connectance", "nestedness")
      )
    testthat::expect_equal(nrow(res), 2L)
  }
)

testthat::test_that(
  "compute_network_metrics() returns requested metric names",
  {
    data_fit <-
      make_data_to_fit(make_mat())
    res <-
      compute_network_metrics(
        data_to_fit = data_fit,
        vec_indices = c("connectance", "nestedness")
      )
    vec_metrics <-
      dplyr::pull(res, metric)
    testthat::expect_true("connectance" %in% vec_metrics)
    testthat::expect_true("nestedness" %in% vec_metrics)
  }
)


# ── Correctness ───────────────────────────────────────────────────────────────

testthat::test_that(
  "compute_network_metrics() connectance is between 0 and 1",
  {
    data_fit <-
      make_data_to_fit(make_mat())
    res <-
      compute_network_metrics(
        data_to_fit = data_fit,
        vec_indices = "connectance"
      )
    val <-
      dplyr::filter(res, metric == "connectance") |>
      dplyr::pull(value)
    testthat::expect_gte(val, 0)
    testthat::expect_lte(val, 1)
  }
)

testthat::test_that(
  "compute_network_metrics() connectance = 1 for full matrix",
  {
    mat_full <-
      base::matrix(
        c(1, 1, 1, 1),
        nrow = 2,
        ncol = 2,
        dimnames = base::list(
          c("s1", "s2"),
          c("t1", "t2")
        )
      )
    data_fit_full <-
      make_data_to_fit(mat_full)
    res <-
      compute_network_metrics(
        data_to_fit = data_fit_full,
        vec_indices = "connectance"
      )
    val <-
      dplyr::filter(res, metric == "connectance") |>
      dplyr::pull(value)
    testthat::expect_equal(val, 1)
  }
)

testthat::test_that(
  "compute_network_metrics() result is reproducible",
  {
    set.seed(900723)
    data_fit <-
      make_data_to_fit(make_mat())
    res_1 <-
      compute_network_metrics(data_to_fit = data_fit)
    set.seed(900723)
    res_2 <-
      compute_network_metrics(data_to_fit = data_fit)
    testthat::expect_identical(res_1, res_2)
  }
)

testthat::test_that(
  "compute_network_metrics() works with a single index",
  {
    data_fit <-
      make_data_to_fit(make_mat())
    res <-
      compute_network_metrics(
        data_to_fit = data_fit,
        vec_indices = "connectance"
      )
    testthat::expect_equal(nrow(res), 1L)
    testthat::expect_equal(
      dplyr::pull(res, metric),
      "connectance"
    )
  }
)
