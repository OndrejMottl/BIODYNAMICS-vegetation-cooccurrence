testthat::test_that("make_classification_table() returns correct class", {
  data_dummy <-
    c("Betula pendula", "Quercus robur", "Pinus sylvestris") %>%
    purrr::map(
      ~ get_taxa_classification(.x)
    )

  res <- make_classification_table(data_dummy)

  testthat::expect_s3_class(res, "data.frame")
})

testthat::test_that("make_classification_table() returns correct data", {
  data_dummy <-
    c("Betula pendula", "Quercus robur", "Pinus sylvestris") %>%
    purrr::map(
      ~ get_taxa_classification(.x)
    )

  res <- make_classification_table(data_dummy)

  expected_res <-
    tibble::tibble(
      sel_name = c("Betula pendula", "Quercus robur", "Pinus sylvestris"),
      family = c("Betulaceae", "Fagaceae", "Pinaceae"),
      genus = c("Betula", "Quercus", "Pinus"),
      species = c("Betula pendula", "Quercus robur", "Pinus sylvestris")
    )

  testthat::expect_equal(res, expected_res)
})

testthat::test_that("make_classification_table() handles invalid input", {
  testthat::expect_error(make_classification_table(NULL))
  testthat::expect_error(make_classification_table(list()))
  testthat::expect_error(make_classification_table("Invalid input"))
  testthat::expect_error(make_classification_table(123))
})
