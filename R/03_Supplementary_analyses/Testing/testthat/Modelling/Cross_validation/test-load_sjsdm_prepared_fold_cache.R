testthat::test_that("prepared-fold cache loader reads the prior object", {
  file_cache <-
    withr::local_tempfile()
  list_cached <-
    base::list(fold = base::list(value = 1L))
  qs2::qs_save(list_cached, file = file_cache)
  testthat::expect_identical(
    load_sjsdm_prepared_fold_cache(file_cache = file_cache), list_cached
  )
  file_rds <-
    withr::local_tempfile()
  base::saveRDS(list_cached, file = file_rds)
  testthat::expect_identical(
    load_sjsdm_prepared_fold_cache(file_cache = file_rds,
      read_cache_function = base::readRDS), list_cached
  )
})

testthat::test_that("prepared-fold cache loader fails closed", {
  file_missing <-
    withr::local_tempfile()
  testthat::expect_null(
    load_sjsdm_prepared_fold_cache(file_cache = file_missing)
  )
  testthat::expect_null(
    load_sjsdm_prepared_fold_cache(file_cache = NA_character_)
  )
  file_cache <-
    withr::local_tempfile()
  qs2::qs_save("malformed", file = file_cache)
  testthat::expect_null(
    load_sjsdm_prepared_fold_cache(file_cache = file_cache)
  )
  testthat::expect_null(load_sjsdm_prepared_fold_cache(
    file_cache = file_cache,
    read_cache_function = function(file) base::stop("unreadable")
  ))
})

testthat::test_that("prepared-fold cache loader validates arguments", {
  testthat::expect_error(
    load_sjsdm_prepared_fold_cache(file_cache = 1L), "path"
  )
  testthat::expect_error(
    load_sjsdm_prepared_fold_cache(file_cache = base::c("a", "b")), "path"
  )
  testthat::expect_error(
    load_sjsdm_prepared_fold_cache(file_cache = NA_character_,
      read_cache_function = 1L), "reader"
  )
})
