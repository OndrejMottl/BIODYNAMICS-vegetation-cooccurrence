testthat::test_that("load_taxa_classification() returns correct class", {
  dir_taxa_classification_cache <-
    base::tempfile(pattern = "taxospace_test_")

  res_taxa_classification <-
    load_taxa_classification(
      vec_taxa = "Betula pendula",
      dir_taxa_classification_cache = dir_taxa_classification_cache
    )

  testthat::expect_s3_class(res_taxa_classification, "data.frame")
})

testthat::test_that("load_taxa_classification() returns correct vec_taxa", {
  dir_taxa_classification_cache <-
    base::tempfile(pattern = "taxospace_test_")

  res_taxa_classification <-
    load_taxa_classification(
      vec_taxa = "Betula pendula",
      dir_taxa_classification_cache = dir_taxa_classification_cache
    )

  testthat::expect_true(
    base::nrow(res_taxa_classification) == 7
  )

  testthat::expect_equal(
    base::unique(dplyr::pull(res_taxa_classification, sel_name)),
    "Betula pendula"
  )

  testthat::expect_true(
    base::all(
      base::c(
        "kingdom", "phylum", "class", "order", "family", "genus", "species"
      ) %in% dplyr::pull(res_taxa_classification, rank)
    )
  )

  testthat::expect_equal(
    dplyr::pull(res_taxa_classification, name)[[7]],
    "Betula pendula"
  )
})

testthat::test_that("load_taxa_classification() handles invalid input", {
  dir_taxa_classification_cache <-
    base::tempfile(pattern = "taxospace_test_")

  testthat::expect_error(
    load_taxa_classification(
      vec_taxa = NULL,
      dir_taxa_classification_cache = dir_taxa_classification_cache
    )
  )

  testthat::expect_error(
    load_taxa_classification(
      vec_taxa = 123,
      dir_taxa_classification_cache = dir_taxa_classification_cache
    )
  )

  res_taxa_classification_nonexistent <-
    load_taxa_classification(
      vec_taxa = "NonExistentTaxon",
      dir_taxa_classification_cache = dir_taxa_classification_cache
    )

  testthat::expect_true(
    base::nrow(res_taxa_classification_nonexistent) == 0
  )

  res_taxa_classification_empty <-
    load_taxa_classification(
      vec_taxa = "",
      dir_taxa_classification_cache = dir_taxa_classification_cache
    )

  testthat::expect_true(
    base::nrow(res_taxa_classification_empty) == 0
  )
})

testthat::test_that("load_taxa_classification() validates dir_taxa_classification_cache type", {
  testthat::expect_error(
    load_taxa_classification(
      vec_taxa = "Betula pendula",
      dir_taxa_classification_cache = 123
    )
  )
})

testthat::test_that("load_taxa_classification() creates dir_taxa_classification_cache if absent", {
  dir_taxa_classification_cache <-
    base::file.path(
      base::tempdir(),
      base::paste0("taxospace_new_", base::format(base::Sys.time(), "%s"))
    )

  testthat::expect_false(base::dir.exists(dir_taxa_classification_cache))

  load_taxa_classification(
    vec_taxa = "Betula pendula",
    dir_taxa_classification_cache = dir_taxa_classification_cache
  )

  testthat::expect_true(base::dir.exists(dir_taxa_classification_cache))
})

testthat::test_that("load_taxa_classification() saves .qs on success", {
  dir_taxa_classification_cache <-
    base::tempfile(pattern = "taxospace_test_")

  load_taxa_classification(
    vec_taxa = "Betula pendula",
    dir_taxa_classification_cache = dir_taxa_classification_cache
  )

  vec_taxa_classification_cache_files <-
    base::list.files(
      path = dir_taxa_classification_cache,
      pattern = "\\.qs$"
    )

  testthat::expect_true(
    base::length(vec_taxa_classification_cache_files) == 1L
  )
})

testthat::test_that("load_taxa_classification() no .qs saved on failure", {
  dir_taxa_classification_cache <-
    base::tempfile(pattern = "taxospace_test_")

  load_taxa_classification(
    vec_taxa = "NonExistentTaxon123XYZ",
    dir_taxa_classification_cache = dir_taxa_classification_cache
  )

  vec_taxa_classification_cache_files <-
    base::list.files(
      path = dir_taxa_classification_cache,
      pattern = "\\.qs$"
    )

  testthat::expect_true(
    base::length(vec_taxa_classification_cache_files) == 0L
  )
})

testthat::test_that("load_taxa_classification() loads from cache on hit", {
  dir_taxa_classification_cache <-
    base::tempfile(pattern = "taxospace_test_")
  base::dir.create(dir_taxa_classification_cache, recursive = TRUE)

  data_taxa_classification_fake <-
    tibble::tibble(
      sel_name = "Betula pendula",
      name = "fake_cached_value",
      rank = "species",
      id = 999L
    )

  vec_cache_file_name <-
    stringr::str_replace_all("Betula pendula", "[^[:alnum:]_]", "_")

  file_taxa_classification_cache <-
    base::file.path(
      dir_taxa_classification_cache,
      base::paste0(vec_cache_file_name, ".qs")
    )

  qs2::qs_save(data_taxa_classification_fake, file_taxa_classification_cache)

  res_taxa_classification <-
    load_taxa_classification(
      vec_taxa = "Betula pendula",
      dir_taxa_classification_cache = dir_taxa_classification_cache
    )

  testthat::expect_equal(
    dplyr::pull(res_taxa_classification, name)[[1]],
    "fake_cached_value"
  )
})
