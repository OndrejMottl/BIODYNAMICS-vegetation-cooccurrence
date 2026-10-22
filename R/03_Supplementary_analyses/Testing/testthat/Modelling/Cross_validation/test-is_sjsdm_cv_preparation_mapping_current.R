testthat::test_that("mapping proof compares exact analytical content", {
  command <-
    stringr::str_c("resolve_modern_community_resolution(",
      "resolution_id = 'genus', data_community_classified = input)")
  testthat::expect_true(is_sjsdm_cv_preparation_mapping_current(
    "store", "data_community_by_resolution_genus", command,
    read_target_function = function(...) tibble::tibble(value = 1L),
    mapping_function = function(resolution_id, data_community_classified) {
      data_community_classified
    }
  ))
  testthat::expect_false(is_sjsdm_cv_preparation_mapping_current(
    "store", "data_community_by_resolution_genus", command,
    read_target_function = function(...) tibble::tibble(value = 1L),
    mapping_function = function(...) tibble::tibble(value = 2L)
  ))
  testthat::expect_false(is_sjsdm_cv_preparation_mapping_current(
    "store", "unknown", "stop('must not execute')"
  ))
})
