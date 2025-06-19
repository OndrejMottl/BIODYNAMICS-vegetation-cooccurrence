testthat::test_that("get_taxa_classification() returns correct class", {
  res <- get_taxa_classification("Betula pendula")

  testthat::expect_s3_class(res, "data.frame")
})

testthat::test_that("get_taxa_classification() returns correct data", {
  res <- get_taxa_classification("Betula pendula")

  testthat::expect_true(
    nrow(res) == 7
  )

  testthat::expect_equal(
    unique(res$sel_name),
    "Betula pendula"
  )


  testthat::expect_true(
    all(
      c(
        "kingdom", "phylum", "class", "order", "family", "genus", "species"
      ) %in% res$rank
    )
  )

  testthat::expect_equal(
    res$name[7],
    "Betula pendula"
  )
})

testthat::test_that("get_taxa_classification() handles invalid input", {
  testthat::expect_error(get_taxa_classification(NULL))
  testthat::expect_error(get_taxa_classification("NonExistentTaxon"))
  testthat::expect_error(get_taxa_classification(123))
  testthat::expect_error(get_taxa_classification(""))
})
