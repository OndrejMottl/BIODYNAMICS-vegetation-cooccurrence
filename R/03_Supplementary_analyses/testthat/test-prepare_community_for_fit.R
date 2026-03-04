testthat::test_that(
  "prepare_community_for_fit() errors if community not a df",
  {
    data_sample_ids <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    testthat::expect_error(
      prepare_community_for_fit(
        data_community_long = "not_a_df",
        data_sample_ids = data_sample_ids
      )
    )
  }
)

testthat::test_that(
  "prepare_community_for_fit() errors if sample_ids not a df",
  {
    data_community <- tibble::tibble(
      dataset_name = "A",
      age = 0,
      taxon = "Pinus",
      pollen_prop = 0.5
    )
    testthat::expect_error(
      prepare_community_for_fit(
        data_community_long = data_community,
        data_sample_ids = base::list()
      )
    )
  }
)

testthat::test_that(
  "prepare_community_for_fit() errors on missing community cols",
  {
    data_community <- tibble::tibble(
      dataset_name = "A",
      age = 0,
      taxon = "Pinus"
    )
    data_sample_ids <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    testthat::expect_error(
      prepare_community_for_fit(
        data_community_long = data_community,
        data_sample_ids = data_sample_ids
      )
    )
  }
)

testthat::test_that(
  "prepare_community_for_fit() errors on missing sample_ids cols",
  {
    data_community <- tibble::tibble(
      dataset_name = "A",
      age = 0,
      taxon = "Pinus",
      pollen_prop = 0.5
    )
    data_sample_ids <- tibble::tibble(
      dataset_name = "A"
    )
    testthat::expect_error(
      prepare_community_for_fit(
        data_community_long = data_community,
        data_sample_ids = data_sample_ids
      )
    )
  }
)

testthat::test_that(
  "prepare_community_for_fit() returns a numeric matrix",
  {
    data_community <- tibble::tibble(
      dataset_name = c("A", "A", "B", "B"),
      age = c(0, 0, 0, 0),
      taxon = c("Pinus", "Betula", "Pinus", "Quercus"),
      pollen_prop = c(0.5, 0.3, 0.2, 0.8)
    )
    data_sample_ids <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 0)
    )
    res <- prepare_community_for_fit(
      data_community_long = data_community,
      data_sample_ids = data_sample_ids
    )
    testthat::expect_true(
      base::is.matrix(res)
    )
    testthat::expect_true(
      base::is.numeric(res)
    )
  }
)

testthat::test_that(
  "prepare_community_for_fit() row names use dataset__age format",
  {
    data_community <- tibble::tibble(
      dataset_name = c("SiteA", "SiteB"),
      age = c(100, 200),
      taxon = c("Pinus", "Betula"),
      pollen_prop = c(0.5, 0.4)
    )
    data_sample_ids <- tibble::tibble(
      dataset_name = c("SiteA", "SiteB"),
      age = c(100, 200)
    )
    res <- prepare_community_for_fit(
      data_community_long = data_community,
      data_sample_ids = data_sample_ids
    )
    testthat::expect_equal(
      base::sort(base::rownames(res)),
      base::sort(c("SiteA__100", "SiteB__200"))
    )
  }
)

testthat::test_that(
  "prepare_community_for_fit() column names are taxon names",
  {
    data_community <- tibble::tibble(
      dataset_name = c("A", "A"),
      age = c(0, 0),
      taxon = c("Pinus", "Betula"),
      pollen_prop = c(0.5, 0.3)
    )
    data_sample_ids <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    res <- prepare_community_for_fit(
      data_community_long = data_community,
      data_sample_ids = data_sample_ids
    )
    testthat::expect_true(
      base::all(
        c("Pinus", "Betula") %in% base::colnames(res)
      )
    )
  }
)

testthat::test_that(
  "prepare_community_for_fit() fills missing combos with 0",
  {
    data_community <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 0),
      taxon = c("Pinus", "Betula"),
      pollen_prop = c(0.5, 0.4)
    )
    data_sample_ids <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 0)
    )
    res <- prepare_community_for_fit(
      data_community_long = data_community,
      data_sample_ids = data_sample_ids
    )
    # A has no Betula, B has no Pinus -> should be 0
    testthat::expect_equal(res["A__0", "Betula"], 0)
    testthat::expect_equal(res["B__0", "Pinus"], 0)
  }
)

testthat::test_that(
  "prepare_community_for_fit() drops NA pollen_prop rows",
  {
    data_community <- tibble::tibble(
      dataset_name = c("A", "A"),
      age = c(0, 0),
      taxon = c("Pinus", "Betula"),
      pollen_prop = c(0.5, NA_real_)
    )
    data_sample_ids <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    res <- prepare_community_for_fit(
      data_community_long = data_community,
      data_sample_ids = data_sample_ids
    )
    # Betula was NA and should be absent from result
    testthat::expect_false(
      "Betula" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "prepare_community_for_fit() drops zero pollen_prop rows",
  {
    data_community <- tibble::tibble(
      dataset_name = c("A", "A"),
      age = c(0, 0),
      taxon = c("Pinus", "Betula"),
      pollen_prop = c(0.5, 0)
    )
    data_sample_ids <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    res <- prepare_community_for_fit(
      data_community_long = data_community,
      data_sample_ids = data_sample_ids
    )
    # Betula was zero and should be absent from result
    testthat::expect_false(
      "Betula" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "prepare_community_for_fit() filters to sample_ids only",
  {
    data_community <- tibble::tibble(
      dataset_name = c("A", "B"),
      age = c(0, 0),
      taxon = c("Pinus", "Betula"),
      pollen_prop = c(0.5, 0.4)
    )
    # Only site A is in sample_ids
    data_sample_ids <- tibble::tibble(
      dataset_name = "A",
      age = 0
    )
    res <- prepare_community_for_fit(
      data_community_long = data_community,
      data_sample_ids = data_sample_ids
    )
    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_equal(
      base::rownames(res),
      "A__0"
    )
  }
)
