testthat::test_that("current-fold proof compares full analytical content", {
  list_fold <-
    base::list(response = base::matrix(1, 1L, 1L),
      data_spatial_provenance = tibble::tibble(basis_bytes = 100))
  list_records <-
    base::list(fold_1 = base::list(
      preparation_status = "ok", preparation_seconds = 2,
      list_fold_context = base::list(train_indices = 1L, test_indices = 2L,
        repeat_id = 1L, fold_id = 1L),
      list_prepared_fold = list_fold
    ))
  read_function <- function(name, ...) {
    if (
      name == "list_sjsdm_prepared_tuning_folds_genus"
    ) {
      return(list_records)
    }
    return(base::list())
  }
  metadata_function <- function(...) {
    tibble::tibble(name = base::c("data_coords_projected",
      "config_model_fitting_genus"))
  }
  testthat::expect_true(is_sjsdm_cv_prepared_folds_current(
    "store", "list_sjsdm_prepared_tuning_folds_genus",
    read_target_function = read_function,
    prepare_fold_function = function(...) {
      list_rebuilt <- list_fold
      list_rebuilt[["data_spatial_provenance"]][["basis_bytes"]] <- 200
      return(list_rebuilt)
    },
    load_metadata_function = metadata_function
  ))
  testthat::expect_false(is_sjsdm_cv_prepared_folds_current(
    "store", "list_sjsdm_prepared_tuning_folds_genus",
    read_target_function = read_function,
    prepare_fold_function = function(...) {
      list_rebuilt <- list_fold
      list_rebuilt[["response"]] <-
        base::matrix(0, 1L, 1L)
      return(list_rebuilt)
    },
    load_metadata_function = metadata_function
  ))
  testthat::expect_false(is_sjsdm_cv_prepared_folds_current(
    "store", "list_sjsdm_prepared_tuning_folds_genus",
    read_target_function = function(...) base::stop("unreadable"),
    load_metadata_function = metadata_function
  ))
})
