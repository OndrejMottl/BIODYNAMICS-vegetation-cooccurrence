testthat::test_that(
  "scale_abiotic_for_fit() errors if input is not a data frame",
  {
    testthat::expect_error(
      scale_abiotic_for_fit(
        data_abiotic_wide = "not_a_df"
      )
    )
  }
)

testthat::test_that(
  "scale_abiotic_for_fit() errors on missing required columns",
  {
    data_no_age <- tibble::tibble(
      dataset_name = "A",
      temp = 10.0
    )
    testthat::expect_error(
      scale_abiotic_for_fit(
        data_abiotic_wide = data_no_age
      )
    )
  }
)

testthat::test_that(
  "scale_abiotic_for_fit() returns a list with two elements",
  {
    data_abiotic_wide <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 100),
      temp = c(10.0, 20.0)
    )
    res <- scale_abiotic_for_fit(
      data_abiotic_wide = data_abiotic_wide
    )
    testthat::expect_true(
      base::is.list(res)
    )
    testthat::expect_true(
      base::all(
        c("data_abiotic_scaled", "scale_attributes") %in%
          base::names(res)
      )
    )
  }
)

testthat::test_that(
  "scale_abiotic_for_fit() scaled output is a data frame",
  {
    data_abiotic_wide <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 100),
      temp = c(10.0, 20.0)
    )
    res <- scale_abiotic_for_fit(
      data_abiotic_wide = data_abiotic_wide
    )
    data_scaled <- purrr::pluck(res, "data_abiotic_scaled")
    testthat::expect_true(
      base::is.data.frame(data_scaled)
    )
  }
)

testthat::test_that(
  "scale_abiotic_for_fit() row names use dataset__age format",
  {
    data_abiotic_wide <- tibble::tibble(
      dataset_name = c("SiteA", "SiteB"),
      age = c(0, 100),
      temp = c(10.0, 20.0)
    )
    res <- scale_abiotic_for_fit(
      data_abiotic_wide = data_abiotic_wide
    )
    data_scaled <- purrr::pluck(res, "data_abiotic_scaled")
    vec_rn <- base::rownames(data_scaled)
    testthat::expect_true(
      base::all(
        c("SiteA__0", "SiteB__100") %in% vec_rn
      )
    )
  }
)

testthat::test_that(
  "scale_abiotic_for_fit() age is centr-only: mean near zero",
  {
    data_abiotic_wide <- tibble::tibble(
      dataset_name = c("A", "B", "C"),
      age = c(0, 100, 200),
      temp = c(10.0, 15.0, 20.0)
    )
    res <- scale_abiotic_for_fit(
      data_abiotic_wide = data_abiotic_wide
    )
    data_scaled <- purrr::pluck(res, "data_abiotic_scaled")
    vec_age_scaled <- dplyr::pull(data_scaled, age)
    testthat::expect_equal(
      base::mean(vec_age_scaled),
      0,
      tolerance = 1e-10
    )
  }
)

testthat::test_that(
  "scale_abiotic_for_fit() other vars are centered and scaled",
  {
    data_abiotic_wide <- tibble::tibble(
      dataset_name = c("A", "B", "C"),
      age = c(0, 100, 200),
      temp = c(10.0, 15.0, 20.0)
    )
    res <- scale_abiotic_for_fit(
      data_abiotic_wide = data_abiotic_wide
    )
    data_scaled <- purrr::pluck(res, "data_abiotic_scaled")
    vec_temp_scaled <- dplyr::pull(data_scaled, temp)
    testthat::expect_equal(
      base::mean(vec_temp_scaled),
      0,
      tolerance = 1e-10
    )
    testthat::expect_equal(
      stats::sd(vec_temp_scaled),
      1,
      tolerance = 1e-10
    )
  }
)

testthat::test_that(
  "scale_abiotic_for_fit() scale_attributes has age element",
  {
    data_abiotic_wide <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 100),
      temp = c(10.0, 20.0)
    )
    res <- scale_abiotic_for_fit(
      data_abiotic_wide = data_abiotic_wide
    )
    scale_attrs <- purrr::pluck(res, "scale_attributes")
    testthat::expect_true(
      "age" %in% base::names(scale_attrs)
    )
  }
)

testthat::test_that(
  "scale_abiotic_for_fit() scale_attributes has variable entries",
  {
    data_abiotic_wide <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 100),
      temp = c(10.0, 20.0),
      precip = c(500, 600)
    )
    res <- scale_abiotic_for_fit(
      data_abiotic_wide = data_abiotic_wide
    )
    scale_attrs <- purrr::pluck(res, "scale_attributes")
    testthat::expect_true(
      "temp" %in% base::names(scale_attrs)
    )
    testthat::expect_true(
      "precip" %in% base::names(scale_attrs)
    )
  }
)

testthat::test_that(
  "scale_abiotic_for_fit() drops rows with any NA silently",
  {
    data_abiotic_wide <- tibble::tibble(
      dataset_name = c("A", "B", "C"),
      age = c(0, 100, 200),
      temp = c(10.0, NA_real_, 20.0)
    )
    res <- scale_abiotic_for_fit(
      data_abiotic_wide = data_abiotic_wide
    )
    data_scaled <- purrr::pluck(res, "data_abiotic_scaled")
    # Row with NA should be dropped
    testthat::expect_equal(base::nrow(data_scaled), 2L)
    testthat::expect_false(
      "B__100" %in% base::rownames(data_scaled)
    )
  }
)

testthat::test_that(
  "scale_abiotic_for_fit() dataset_name not in scaled output",
  {
    data_abiotic_wide <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 100),
      temp = c(10.0, 20.0)
    )
    res <- scale_abiotic_for_fit(
      data_abiotic_wide = data_abiotic_wide
    )
    data_scaled <- purrr::pluck(res, "data_abiotic_scaled")
    # dataset_name should be in rownames, not a column
    testthat::expect_false(
      "dataset_name" %in% base::colnames(data_scaled)
    )
  }
)
