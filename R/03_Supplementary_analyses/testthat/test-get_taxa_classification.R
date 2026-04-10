testthat::test_that("get_taxa_classification() returns correct class", {
  vec_cache_dir <-
    base::tempfile(pattern = "taxospace_test_")

  res <-
    get_taxa_classification(
      data = "Betula pendula",
      cache_dir = vec_cache_dir
    )

  testthat::expect_s3_class(res, "data.frame")
})

testthat::test_that("get_taxa_classification() returns correct data", {
  vec_cache_dir <-
    base::tempfile(pattern = "taxospace_test_")

  res <-
    get_taxa_classification(
      data = "Betula pendula",
      cache_dir = vec_cache_dir
    )

  testthat::expect_true(
    base::nrow(res) == 7
  )

  testthat::expect_equal(
    base::unique(dplyr::pull(res, sel_name)),
    "Betula pendula"
  )

  testthat::expect_true(
    base::all(
      base::c(
        "kingdom", "phylum", "class", "order", "family", "genus", "species"
      ) %in% dplyr::pull(res, rank)
    )
  )

  testthat::expect_equal(
    dplyr::pull(res, name)[[7]],
    "Betula pendula"
  )
})

testthat::test_that("get_taxa_classification() handles invalid input", {
  vec_cache_dir <-
    base::tempfile(pattern = "taxospace_test_")

  testthat::expect_error(
    get_taxa_classification(
      data = NULL,
      cache_dir = vec_cache_dir
    )
  )

  testthat::expect_error(
    get_taxa_classification(
      data = 123,
      cache_dir = vec_cache_dir
    )
  )

  res_nonexistent <-
    get_taxa_classification(
      data = "NonExistentTaxon",
      cache_dir = vec_cache_dir
    )

  testthat::expect_true(
    base::nrow(res_nonexistent) == 0
  )

  res_empty <-
    get_taxa_classification(
      data = "",
      cache_dir = vec_cache_dir
    )

  testthat::expect_true(
    base::nrow(res_empty) == 0
  )
})

testthat::test_that("get_taxa_classification() validates cache_dir type", {
  testthat::expect_error(
    get_taxa_classification(
      data = "Betula pendula",
      cache_dir = 123
    )
  )
})

testthat::test_that("get_taxa_classification() creates cache_dir if absent", {
  vec_cache_dir <-
    base::file.path(
      base::tempdir(),
      base::paste0("taxospace_new_", base::format(base::Sys.time(), "%s"))
    )

  testthat::expect_false(base::dir.exists(vec_cache_dir))

  get_taxa_classification(
    data = "Betula pendula",
    cache_dir = vec_cache_dir
  )

  testthat::expect_true(base::dir.exists(vec_cache_dir))
})

testthat::test_that("get_taxa_classification() saves .qs on success", {
  vec_cache_dir <-
    base::tempfile(pattern = "taxospace_test_")

  get_taxa_classification(
    data = "Betula pendula",
    cache_dir = vec_cache_dir
  )

  vec_cache_files <-
    base::list.files(
      path = vec_cache_dir,
      pattern = "\\.qs$"
    )

  testthat::expect_true(
    base::length(vec_cache_files) == 1L
  )
})

testthat::test_that("get_taxa_classification() no .qs saved on failure", {
  vec_cache_dir <-
    base::tempfile(pattern = "taxospace_test_")

  get_taxa_classification(
    data = "NonExistentTaxon123XYZ",
    cache_dir = vec_cache_dir
  )

  vec_cache_files <-
    base::list.files(
      path = vec_cache_dir,
      pattern = "\\.qs$"
    )

  testthat::expect_true(
    base::length(vec_cache_files) == 0L
  )
})

testthat::test_that("get_taxa_classification() loads from cache on hit", {
  vec_cache_dir <-
    base::tempfile(pattern = "taxospace_test_")
  base::dir.create(vec_cache_dir, recursive = TRUE)

  data_fake <-
    tibble::tibble(
      sel_name = "Betula pendula",
      name = "fake_cached_value",
      rank = "species",
      id = 999L
    )

  vec_cache_name <-
    stringr::str_replace_all("Betula pendula", "[^[:alnum:]_]", "_")

  vec_cache_file <-
    base::file.path(
      vec_cache_dir,
      base::paste0(vec_cache_name, ".qs")
    )

  qs2::qs_save(data_fake, vec_cache_file)

  res <-
    get_taxa_classification(
      data = "Betula pendula",
      cache_dir = vec_cache_dir
    )

  testthat::expect_equal(
    dplyr::pull(res, name)[[1]],
    "fake_cached_value"
  )
})
