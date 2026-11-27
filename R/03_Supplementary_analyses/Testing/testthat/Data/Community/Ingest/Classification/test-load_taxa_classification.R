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

testthat::test_that("load_taxa_classification() validates cache path", {
  testthat::expect_error(
    load_taxa_classification(
      vec_taxa = "Betula pendula",
      dir_taxa_classification_cache = 123
    )
  )
})

testthat::test_that("load_taxa_classification() creates missing cache", {
  dir_taxa_classification_cache <-
    base::file.path(
      base::tempdir(),
      stringr::str_glue(
        "taxospace_new_{base::format(base::Sys.time(), '%s')}"
      )
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
      stringr::str_glue("{vec_cache_file_name}.qs")
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

testthat::test_that("load_taxa_classification() renames a shared cache hit", {
  dir_taxa_classification_cache <-
    base::tempfile(pattern = "taxospace_test_")
  base::dir.create(dir_taxa_classification_cache, recursive = TRUE)

  data_taxa_classification_fake <-
    tibble::tibble(
      sel_name = "Quercus petraea",
      name = base::c("Quercus", "Quercus petraea"),
      rank = base::c("genus", "species"),
      id = base::c(1L, 2L)
    )

  qs2::qs_save(
    data_taxa_classification_fake,
    base::file.path(dir_taxa_classification_cache, "Quercus_petraea.qs")
  )

  # "Quercus-petraea" maps to the file of "Quercus petraea" on every system
  res_taxa_classification <-
    load_taxa_classification(
      vec_taxa = "Quercus-petraea",
      dir_taxa_classification_cache = dir_taxa_classification_cache
    )

  testthat::expect_equal(
    dplyr::pull(res_taxa_classification, sel_name),
    base::c("Quercus-petraea", "Quercus-petraea")
  )

  testthat::expect_equal(
    dplyr::pull(res_taxa_classification, name),
    base::c("Quercus", "Quercus petraea")
  )

  testthat::expect_equal(
    dplyr::pull(res_taxa_classification, rank),
    base::c("genus", "species")
  )
})

testthat::test_that("load_taxa_classification() renames a case-only hit", {
  dir_taxa_classification_cache <-
    base::tempfile(pattern = "taxospace_test_")
  base::dir.create(dir_taxa_classification_cache, recursive = TRUE)

  data_taxa_classification_fake <-
    tibble::tibble(
      sel_name = "Quercus petraea",
      name = "Quercus petraea",
      rank = "species",
      id = 2L
    )

  qs2::qs_save(
    data_taxa_classification_fake,
    base::file.path(dir_taxa_classification_cache, "Quercus_petraea.qs")
  )

  # Only where file names ignore case does "Quercus Petraea" hit this file
  testthat::skip_if_not(
    base::file.exists(
      base::file.path(dir_taxa_classification_cache, "Quercus_Petraea.qs")
    ),
    message = "File names are case-sensitive on this system."
  )

  res_taxa_classification <-
    load_taxa_classification(
      vec_taxa = "Quercus Petraea",
      dir_taxa_classification_cache = dir_taxa_classification_cache
    )

  testthat::expect_equal(
    dplyr::pull(res_taxa_classification, sel_name),
    "Quercus Petraea"
  )

  testthat::expect_equal(
    dplyr::pull(res_taxa_classification, name),
    "Quercus petraea"
  )
})

testthat::test_that("load_taxa_classification() keeps names of a set hit", {
  dir_taxa_classification_cache <-
    base::tempfile(pattern = "taxospace_test_")
  base::dir.create(dir_taxa_classification_cache, recursive = TRUE)

  vec_taxa <-
    base::c("Quercus robur", "Betula pendula")

  data_taxa_classification_fake <-
    tibble::tibble(
      sel_name = base::c("Betula pendula", "Quercus robur"),
      name = base::c("Betula pendula", "Quercus robur"),
      rank = base::c("species", "species"),
      id = base::c(1L, 2L)
    )

  qs2::qs_save(
    data_taxa_classification_fake,
    base::file.path(
      dir_taxa_classification_cache,
      stringr::str_glue("{rlang::hash(base::sort(vec_taxa))}.qs")
    )
  )

  res_taxa_classification <-
    load_taxa_classification(
      vec_taxa = vec_taxa,
      dir_taxa_classification_cache = dir_taxa_classification_cache
    )

  testthat::expect_equal(
    dplyr::pull(res_taxa_classification, sel_name),
    base::c("Betula pendula", "Quercus robur")
  )
})
