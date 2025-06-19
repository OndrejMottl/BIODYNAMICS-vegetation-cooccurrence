testthat::test_that("get_community_taxa() returns correct class", {
  data_dummy <-
    data.frame(
      taxon = c("Taxon1", "Taxon2", "Taxon3")
    )

  res <- get_community_taxa(data_dummy)

  testthat::expect_type(res, "character")
})

testthat::test_that("get_community_taxa() returns correct data", {
  data_dummy <-
    data.frame(
      taxon = c("Taxon1", "Taxon2", "Taxon3")
    )

  res <- get_community_taxa(data_dummy)

  testthat::expect_equal(res, c("Taxon1", "Taxon2", "Taxon3"))
})

testthat::test_that("get_community_taxa() handles invalid input", {
  testthat::expect_error(get_community_taxa(NULL))
  testthat::expect_error(get_community_taxa(data.frame()))
})
