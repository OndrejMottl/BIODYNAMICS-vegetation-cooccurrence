testthat::test_that(
  "summarise_sjsdm_tuning_execution() reports avoided refits",
  {
    data_tuning <-
      tidyr::crossing(
        repeat_id = 1:3,
        fold_id = 1:5,
        candidate_id = stringr::str_c("candidate_", 1:8)
      ) |>
      dplyr::mutate(fit_status = "ok")

    data_schedule <-
      build_sjsdm_tuning_schedule(
        tuning_strategy = "exhaustive",
        n_candidates = 8L,
        repeat_ids = 1:3
      )

    data_result <-
      summarise_sjsdm_tuning_execution(
        data_tuning = data_tuning,
        data_schedule = data_schedule,
        data_work_items = data_tuning |>
          dplyr::mutate(
            work_item_id = stringr::str_c(
              "item_",
              dplyr::row_number()
            )
          )
      )

    testthat::expect_identical(data_result[["n_fits_executed"]], 120L)
    testthat::expect_identical(
      data_result[["n_selected_refits_reused"]],
      15L
    )
    testthat::expect_equal(
      data_result[["fit_reduction_fraction"]],
      15 / 135
    )
    testthat::expect_identical(
      data_result[["evaluation_prediction_source"]],
      "tuning_prediction_cache"
    )
    testthat::expect_identical(
      data_result[["work_item_identity_version"]],
      "sjsdm_cv_work_item_v1"
    )
    testthat::expect_identical(
      data_result[["restart_boundary"]],
      "repeat_fold_candidate"
    )
    testthat::expect_identical(
      data_result[["n_work_items_materialized"]],
      120L
    )
  }
)

testthat::test_that(
  "summarise_sjsdm_tuning_execution() reports staged fit budgets",
  {
    data_tuning <-
      base::list(
        tidyr::crossing(
          repeat_id = 1L,
          fold_id = 1:5,
          candidate_id = stringr::str_c("candidate_", 1:8)
        ),
        tidyr::crossing(
          repeat_id = 2L,
          fold_id = 1:5,
          candidate_id = stringr::str_c("candidate_", 1:4)
        ),
        tidyr::crossing(
          repeat_id = 3L,
          fold_id = 1:5,
          candidate_id = stringr::str_c("candidate_", 1:2)
        )
      ) |>
      purrr::list_rbind() |>
      dplyr::mutate(fit_status = "ok")

    data_schedule <-
      build_sjsdm_tuning_schedule(
        tuning_strategy = "staged",
        n_candidates = 8L,
        repeat_ids = 1:3,
        survivor_counts = base::c(4L, 2L)
      )

    data_result <-
      summarise_sjsdm_tuning_execution(
        data_tuning = data_tuning,
        data_schedule = data_schedule
      )

    testthat::expect_identical(data_result[["n_fits_executed"]], 70L)
    testthat::expect_identical(data_result[["n_fits_historical"]], 135L)
    testthat::expect_equal(
      data_result[["fit_reduction_fraction"]],
      65 / 135
    )
  }
)

testthat::test_that(
  "summarise_sjsdm_tuning_execution() handles units without folds",
  {
    data_tuning <-
      tibble::tibble(
        repeat_id = base::integer(),
        fold_id = base::integer(),
        candidate_id = base::character(),
        fit_status = base::character()
      )

    data_schedule <-
      build_sjsdm_tuning_schedule(
        tuning_strategy = "exhaustive",
        n_candidates = 1L,
        repeat_ids = 1L
      )

    data_result <-
      summarise_sjsdm_tuning_execution(
        data_tuning = data_tuning,
        data_schedule = data_schedule
      )

    testthat::expect_identical(data_result[["n_fits_executed"]], 0L)
    testthat::expect_identical(data_result[["n_fold_preparations"]], 0L)
    testthat::expect_identical(data_result[["n_selected_refits_reused"]], 0L)
    testthat::expect_true(
      base::is.na(data_result[["fit_reduction_fraction"]])
    )
  }
)
