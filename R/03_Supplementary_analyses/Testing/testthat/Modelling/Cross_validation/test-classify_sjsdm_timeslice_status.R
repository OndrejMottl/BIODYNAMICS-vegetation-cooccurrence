testthat::test_that(
  "classify_sjsdm_timeslice_status() labels every slice",
  {
    data_target_errors <-
      tibble::tibble(
        name = base::c(
          "data_sample_ids_checked_timeslice_0",
          "data_abiotic_wide_timeslice_0",
          "mod_jsdm_timeslice_1000",
          "list_jsdm_variance_partition_timeslice_500"
        ),
        error = base::c(
          stringr::str_c(
            "Too few samples in this time slice to proceed. ",
            "Found 1 sample(s) but at least 10 are required."
          ),
          "data_sample_ids must be a data frame",
          "ZeroDivisionError: division by zero",
          NA_character_
        )
      )

    res <-
      classify_sjsdm_timeslice_status(
        data_target_errors = data_target_errors,
        vec_slice_ids = base::c(
          "timeslice_0",
          "timeslice_500",
          "timeslice_1000",
          "timeslice_20000"
        ),
        vec_window_slice_ids = base::c(
          "timeslice_0",
          "timeslice_500",
          "timeslice_1000"
        )
      )

    testthat::expect_equal(
      res[["status"]],
      base::c("expected_infeasible", "ok", "unexpected_error", "outside_window")
    )
    testthat::expect_equal(res[["age"]], base::c(0, 500, 1000, 20000))
    testthat::expect_equal(res[["reason_code"]][[1L]], "insufficient_samples")
    testthat::expect_equal(
      res[["root_target"]][[3L]],
      "mod_jsdm_timeslice_1000"
    )
  }
)

testthat::test_that(
  "classify_sjsdm_timeslice_status() keeps slice suffixes apart",
  {
    res <-
      classify_sjsdm_timeslice_status(
        data_target_errors = tibble::tibble(
          name = "mod_jsdm_timeslice_10",
          error = "failure"
        ),
        vec_slice_ids = base::c("timeslice_0", "timeslice_10")
      )

    testthat::expect_equal(res[["status"]], base::c("ok", "unexpected_error"))
  }
)

testthat::test_that(
  "classify_sjsdm_timeslice_status() reports shared failures separately",
  {
    res <-
      classify_sjsdm_timeslice_status(
        data_target_errors = tibble::tibble(
          name = "data_community_interpolated",
          error = "out of memory"
        ),
        vec_slice_ids = "timeslice_0"
      )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_true(base::is.na(res[["slice_id"]][[2L]]))
    testthat::expect_equal(res[["status"]][[2L]], "unexpected_error")
  }
)

testthat::test_that(
  "classify_sjsdm_timeslice_status() validates its inputs",
  {
    testthat::expect_error(
      classify_sjsdm_timeslice_status(
        data_target_errors = tibble::tibble(name = "a"),
        vec_slice_ids = "timeslice_0"
      ),
      "name and error"
    )
    testthat::expect_error(
      classify_sjsdm_timeslice_status(
        data_target_errors = NULL,
        vec_slice_ids = character()
      ),
      "non-missing character"
    )
  }
)

testthat::test_that(
  "classify_sjsdm_timeslice_status() labels configured exclusions",
  {
    res <-
      classify_sjsdm_timeslice_status(
        data_target_errors = NULL,
        vec_slice_ids = base::c("timeslice_0", "timeslice_500"),
        vec_excluded_slice_ids = "timeslice_0"
      )

    testthat::expect_equal(
      res[["status"]],
      base::c("expected_infeasible", "ok")
    )
    testthat::expect_equal(
      res[["reason_code"]][[1L]],
      "excluded_in_configuration"
    )
  }
)

testthat::test_that(
  "classify_sjsdm_timeslice_status() needs the terminal target for ok",
  {
    data_target_meta <-
      tibble::tibble(
        name = base::c(
          "list_jsdm_variance_partition_timeslice_0",
          "list_jsdm_variance_partition_timeslice_500",
          "mod_jsdm_timeslice_1000"
        ),
        error = base::c(NA_character_, "", NA_character_)
      )

    res <-
      classify_sjsdm_timeslice_status(
        data_target_errors = data_target_meta,
        vec_slice_ids = base::c(
          "timeslice_0",
          "timeslice_500",
          "timeslice_1000"
        ),
        terminal_target_prefix = "list_jsdm_variance_partition_"
      )

    testthat::expect_equal(
      res[["status"]],
      base::c("ok", "ok", "not_built")
    )
    testthat::expect_equal(
      res[["reason_code"]][[3L]],
      "terminal_target_missing"
    )
    testthat::expect_equal(
      res[["root_target"]][[3L]],
      "list_jsdm_variance_partition_timeslice_1000"
    )
  }
)

testthat::test_that(
  "classify_sjsdm_timeslice_status() rejects a malformed prefix",
  {
    testthat::expect_error(
      classify_sjsdm_timeslice_status(
        data_target_errors = NULL,
        vec_slice_ids = "timeslice_0",
        terminal_target_prefix = base::c("a", "b")
      ),
      regexp = "terminal_target_prefix"
    )
  }
)
