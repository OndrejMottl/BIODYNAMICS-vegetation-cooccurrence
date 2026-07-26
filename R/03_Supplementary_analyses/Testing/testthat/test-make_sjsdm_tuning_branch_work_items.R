testthat::test_that(
  "make_sjsdm_tuning_branch_work_items() preserves real work",
  {
    data_work_items <-
      tibble::tibble(
        work_item_id = "item_1",
        fold_key = "repeat_001__fold_001",
        repeat_id = 1L,
        fold_id = 1L,
        candidate_id = "candidate_001",
        alpha_cov = 0.5,
        alpha_coef = 0.5,
        alpha_spatial = 0.5,
        lambda_cov = 0,
        lambda_coef = 0,
        lambda_spatial = 0,
        tuning_seed = 900723L
      )

    res <-
      make_sjsdm_tuning_branch_work_items(
        data_work_items = data_work_items
      )

    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_true(res[["tuning_applicable"]][[1L]])
    testthat::expect_equal(
      res[["work_item_id"]],
      data_work_items[["work_item_id"]]
    )
  }
)

testthat::test_that(
  "make_sjsdm_tuning_branch_work_items() makes an empty sentinel",
  {
    data_work_items <-
      build_sjsdm_tuning_work_items(
        data_assignments = tibble::tibble(
          repeat_id = base::integer(),
          fold_id = base::integer(),
          location_id = base::character(),
          n_samples = base::integer(),
          row_indices = base::list()
        ),
        data_candidates = make_sjsdm_regularization_candidates(
          alpha_cov = 0.5,
          alpha_coef = 0.5,
          alpha_spatial = 0.5,
          lambda_cov = 0,
          lambda_coef = 0,
          lambda_spatial = 0
        )
      )

    res <-
      make_sjsdm_tuning_branch_work_items(
        data_work_items = data_work_items
      )

    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_false(res[["tuning_applicable"]][[1L]])
    testthat::expect_equal(
      res[["work_item_id"]],
      "sjsdm_cv_not_applicable"
    )
    testthat::expect_true(base::is.na(res[["candidate_id"]][[1L]]))
  }
)

testthat::test_that(
  "make_sjsdm_tuning_branch_work_items() validates its schema",
  {
    testthat::expect_error(
      make_sjsdm_tuning_branch_work_items(
        data_work_items = tibble::tibble(work_item_id = "item_1")
      ),
      "incomplete"
    )
  }
)
