testthat::test_that("build_classification_table() returns correct class", {
  list_taxa_classifications <-
    c("Betula pendula", "Quercus robur", "Pinus sylvestris") %>%
    purrr::map(
      ~ load_taxa_classification(.x)
    )

  res_classification_table <- build_classification_table(list_taxa_classifications)

  testthat::expect_s3_class(res_classification_table, "data.frame")
})

testthat::test_that("build_classification_table() returns correct data", {
  list_taxa_classifications <-
    c("Betula pendula", "Quercus robur", "Pinus sylvestris") %>%
    purrr::map(
      ~ load_taxa_classification(.x)
    )

  res_classification_table <- build_classification_table(list_taxa_classifications)

  # All eight columns are present (sel_name + 7 taxonomic ranks)
  testthat::expect_true(
    all(
      c(
        "sel_name",
        "kingdom", "phylum", "class", "order",
        "family", "genus", "species"
      ) %in% colnames(res_classification_table)
    )
  )

  # family / genus / species values are correct
  data_expected <-
    tibble::tibble(
      sel_name = c("Betula pendula", "Quercus robur", "Pinus sylvestris"),
      family = c("Betulaceae", "Fagaceae", "Pinaceae"),
      genus = c("Betula", "Quercus", "Pinus"),
      species = c("Betula pendula", "Quercus robur", "Pinus sylvestris")
    )

  testthat::expect_equal(
    res_classification_table %>%
      dplyr::select(sel_name, family, genus, species),
    data_expected
  )
})

testthat::test_that("build_classification_table() handles invalid input", {
  testthat::expect_error(build_classification_table(NULL))
  testthat::expect_error(build_classification_table(list()))
  testthat::expect_error(build_classification_table("Invalid input"))
  testthat::expect_error(build_classification_table(123))
})
