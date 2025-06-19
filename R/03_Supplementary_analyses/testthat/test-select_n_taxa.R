testthat::test_that("select_n_taxa() return correct class", {
  set.seed(1234)
  data_dummy <-
    data.frame(
      dataset_name = rep(c(paste0("dataset", 1:10)), each = 5),
      taxon = sample(letters, 50, replace = TRUE),
      pollen_prop = runif(50, 0, 1)
    )

  res <- select_n_taxa(data_dummy, n_taxa = 2, per = "dataset_name")

  testthat::expect_s3_class(res, "data.frame")
})

testthat::test_that("select_n_taxa() return correct data", {
  set.seed(1234)
  data_dummy <-
    data.frame(
      dataset_name = rep(c(paste0("dataset", 1:10)), each = 5),
      taxon = sample(letters, 50, replace = TRUE),
      pollen_prop = runif(50, 0, 1)
    )

  res <-
    select_n_taxa(
      data = data_dummy, n_taxa = 2, per = "dataset_name"
    ) %>%
    tibble::as_tibble() %>%
    dplyr::arrange(dataset_name, taxon)

  expected_res <-
    data_dummy %>%
    dplyr::group_by(taxon) %>%
    dplyr::summarise(
      n_datasets = dplyr::n(),
      .groups = "drop"
    ) %>%
    dplyr::slice_max(n = 2, order_by = n_datasets) %>%
    dplyr::inner_join(data_dummy, by = "taxon") %>%
    dplyr::select(dataset_name, taxon, pollen_prop) %>%
    dplyr::arrange(dataset_name, taxon)

  testthat::expect_equal(res, expected_res)
})


testthat::test_that("select_n_taxa() return correct data - all taxa", {
  set.seed(1234)
  data_dummy <-
    data.frame(
      dataset_name = rep(c(paste0("dataset", 1:10)), each = 5),
      taxon = sample(letters, 50, replace = TRUE),
      pollen_prop = runif(50, 0, 1)
    )

  res <-
    select_n_taxa(
      data = data_dummy, n_taxa = Inf, per = "dataset_name"
    )

  testthat::expect_equal(res, data_dummy)
})

testthat::test_that("select_n_taxa() handles incorrect input", {
  set.seed(1234)
  data_dummy <-
    data.frame(
      dataset_name = rep(c(paste0("dataset", 1:10)), each = 5),
      taxon = sample(letters, 50, replace = TRUE),
      pollen_prop = runif(50, 0, 1)
    )

  testthat::expect_error(
    select_n_taxa(NULL, n_taxa = 2, per = "dataset_name")
  )

  testthat::expect_error(
    select_n_taxa("invalid", n_taxa = 2, per = "dataset_name")
  )

  testthat::expect_error(
    select_n_taxa(data.frame(), n_taxa = 2, per = "dataset_name")
  )


  testthat::expect_error(
    select_n_taxa(data_dummy, n_taxa = -1, per = "dataset_name")
  )

  testthat::expect_error(
    select_n_taxa(data_dummy, n_taxa = "two", per = "dataset_name")
  )

  testthat::expect_error(
    select_n_taxa(data_dummy, n_taxa = NULL, per = "dataset_name")
  )

  testthat::expect_error(
    select_n_taxa(data_dummy, n_taxa = 2, per = NULL)
  )

  testthat::expect_error(
    select_n_taxa(data_dummy, n_taxa = Inf, per = "nonexistent_column"),
  )
})
