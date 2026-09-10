testthat::test_that(
  "select_sjsdm_cv_calibration_budget applies stability criteria",
  {
    data_benchmark <-
      tidyr::crossing(
        repeat_id = 1:2,
        budget_order = 1:3,
        fold_id = 1:5,
        candidate_id = c("candidate_1", "candidate_2")
      ) |>
      dplyr::mutate(
        n_iter = c(500L, 1000L, 2000L)[.data[["budget_order"]]],
        n_sampling = 200L,
        converged = !(
          .data[["repeat_id"]] == 1L &
            .data[["budget_order"]] == 1L
        ),
        normalized_loss = dplyr::if_else(
          .data[["candidate_id"]] == "candidate_1",
          0.2 + .data[["budget_order"]] * 0.0005,
          0.4 + .data[["budget_order"]] * 0.0005
        )
      )

    res <-
      select_sjsdm_cv_calibration_budget(data_benchmark)

    testthat::expect_equal(res[["n_iter_initial"]], 1000L)
    testthat::expect_equal(res[["n_iter_max"]], 4000L)
    testthat::expect_equal(res[["n_sampling"]], 200L)
    testthat::expect_equal(res[["candidate_id"]], "candidate_1")
    testthat::expect_true(res[["repeat_two_confirmed"]])
  }
)

testthat::test_that(
  "select_sjsdm_cv_calibration_budget rejects unstable winners",
  {
    data_benchmark <-
      tidyr::crossing(
        repeat_id = 1:2,
        budget_order = 1:2,
        fold_id = 1:5,
        candidate_id = c("candidate_1", "candidate_2")
      ) |>
      dplyr::mutate(
        n_iter = c(500L, 1000L)[.data[["budget_order"]]],
        n_sampling = 200L,
        converged = TRUE,
        normalized_loss = dplyr::case_when(
          .data[["budget_order"]] == 1L &
            .data[["candidate_id"]] == "candidate_1" ~ 0.1,
          .data[["budget_order"]] == 1L ~ 0.2,
          .data[["candidate_id"]] == "candidate_1" ~ 0.3,
          TRUE ~ 0.1
        )
      )

    testthat::expect_error(
      select_sjsdm_cv_calibration_budget(data_benchmark),
      regexp = "No benchmark budget"
    )
  }
)

testthat::test_that(
  "select_sjsdm_cv_calibration_budget rejects incomplete fold coverage",
  {
    data_benchmark <-
      tidyr::crossing(
        repeat_id = 1:2,
        budget_order = 1:2,
        fold_id = 1:5,
        candidate_id = base::c("candidate_1", "candidate_2")
      ) |>
      dplyr::filter(
        !(
          .data[["candidate_id"]] == "candidate_1" &
            .data[["fold_id"]] == 5L
        )
      ) |>
      dplyr::mutate(
        n_iter = 500L * 2L^(.data[["budget_order"]] - 1L),
        n_sampling = 200L,
        converged = TRUE,
        normalized_loss = dplyr::if_else(
          .data[["candidate_id"]] == "candidate_1",
          0.2,
          0.4
        )
      )

    testthat::expect_error(
      select_sjsdm_cv_calibration_budget(data_benchmark),
      regexp = "No benchmark budget"
    )
  }
)
