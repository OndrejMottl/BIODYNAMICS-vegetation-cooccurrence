testthat::test_that(
  "prepare_sjsdm_tuning_folds() prepares each fold once",
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

    environment_calls <-
      base::new.env(parent = base::emptyenv())

    environment_calls[["count"]] <- 0L

    prepare_fold_function <- function(...) {
      environment_calls[["count"]] <-
        environment_calls[["count"]] + 1L

      return(base::list(prepared = TRUE))
    }

    list_folds <-
      prepare_sjsdm_tuning_folds(
        data_assignments = data_assignments,
        prepare_fold_function = prepare_fold_function
      )

    testthat::expect_length(list_folds, 2L)
    testthat::expect_identical(environment_calls[["count"]], 2L)
    testthat::expect_identical(
      purrr::map_chr(list_folds, "preparation_status") |>
        base::unname(),
      base::rep("ok", 2L)
    )
    testthat::expect_identical(
      purrr::map_chr(list_folds, "fold_key") |>
        base::unname(),
      base::c("repeat_001__fold_001", "repeat_001__fold_002")
    )
  }
)

testthat::test_that(
  "prepare_sjsdm_tuning_folds() retains preparation failures",
  {
    data_assignments <-
      tibble::tibble(
        repeat_id = base::rep(1L, 2L),
        fold_id = 1:2,
        location_id = base::c("a", "b"),
        n_samples = base::rep(1L, 2L),
        row_indices = base::list(1L, 2L)
      )

    list_folds <-
      prepare_sjsdm_tuning_folds(
        data_assignments = data_assignments,
        prepare_fold_function = function(...) {
          base::stop("cannot prepare")
        }
      )

    testthat::expect_identical(
      list_folds[[1L]][["preparation_status"]],
      "preparation_error"
    )
    testthat::expect_match(
      list_folds[[1L]][["error_message"]],
      "cannot prepare"
    )
  }
)
