testthat::test_that(
  "build_sjsdm_tuning_work_items() creates stable granular identities",
  {
    data_assignments <-
      tibble::tibble(
        repeat_id = base::rep(1L, 2L),
        fold_id = 1:2,
        location_id = base::c("a", "b"),
        n_samples = base::rep(1L, 2L),
        row_indices = base::list(1L, 2L),
        cv_strategy = "leave_one_location_out"
      )

    data_candidates <-
      make_sjsdm_regularization_candidates(
        lambda_cov = base::c(0, 0.1)
      )

    data_items <-
      build_sjsdm_tuning_work_items(
        data_assignments = data_assignments,
        data_candidates = data_candidates,
        seed = 900723L
      )

    data_reordered <-
      build_sjsdm_tuning_work_items(
        data_assignments = data_assignments,
        data_candidates = data_candidates[2:1, ],
        seed = 900723L
      )

    testthat::expect_equal(base::nrow(data_items), 4L)
    testthat::expect_identical(
      data_items[["work_item_id"]],
      data_reordered[["work_item_id"]]
    )
    testthat::expect_length(base::unique(data_items[["work_item_id"]]), 4L)
    testthat::expect_identical(
      data_items[["candidate_id"]],
      base::rep(base::c("candidate_001", "candidate_002"), 2L)
    )

    data_changed_seed <-
      build_sjsdm_tuning_work_items(
        data_assignments = data_assignments,
        data_candidates = data_candidates,
        seed = 900724L
      )

    testthat::expect_false(
      base::identical(
        data_items[["work_item_id"]],
        data_changed_seed[["work_item_id"]]
      )
    )
  }
)
