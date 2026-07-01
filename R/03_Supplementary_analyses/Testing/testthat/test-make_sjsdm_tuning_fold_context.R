testthat::test_that(
  "make_sjsdm_tuning_fold_context() creates disjoint fold indices",
  {
    data_assignments <-
      tibble::tibble(
        repeat_id = base::rep(1L, 4L),
        fold_id = base::c(1L, 1L, 2L, 2L),
        location_id = base::letters[1:4],
        row_indices = base::list(1L, 2L, 3L, 4L),
        cv_strategy = "spatially_stratified_group_kfold"
      )

    res <-
      make_sjsdm_tuning_fold_context(
        data_assignments = data_assignments,
        repeat_id = 1L,
        fold_id = 1L
      )

    testthat::expect_equal(
      res,
      base::list(
        repeat_id = 1L,
        fold_id = 1L,
        train_indices = base::c(3L, 4L),
        test_indices = base::c(1L, 2L),
        n_train_locations = 2L,
        n_test_locations = 2L,
        n_train_samples = 2L,
        n_test_samples = 2L,
        cv_strategy = "spatially_stratified_group_kfold"
      )
    )
  }
)

testthat::test_that(
  "make_sjsdm_tuning_fold_context() rejects overlapping row indices",
  {
    data_assignments <-
      tibble::tibble(
        repeat_id = base::rep(1L, 2L),
        fold_id = base::c(1L, 2L),
        location_id = base::c("a", "b"),
        row_indices = base::list(base::c(1L, 2L), base::c(2L, 3L))
      )

    testthat::expect_error(
      make_sjsdm_tuning_fold_context(
        data_assignments = data_assignments,
        repeat_id = 1L,
        fold_id = 1L
      ),
      "disjoint"
    )
  }
)
