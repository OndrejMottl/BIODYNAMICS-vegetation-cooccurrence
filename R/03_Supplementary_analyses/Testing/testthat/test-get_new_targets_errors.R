testthat::test_that("get_new_targets_errors() detects new and retried errors", {
  time_before <-
    base::as.POSIXct("2026-07-25 12:00:00", tz = "UTC")

  time_after <-
    base::as.POSIXct("2026-07-25 12:01:00", tz = "UTC")

  data_before <-
    tibble::tibble(
      name = base::c("unchanged", "retried"),
      error = base::c("old error", "same error"),
      time = base::c(time_before, time_before)
    )

  data_after <-
    tibble::tibble(
      name = base::c("unchanged", "retried", "new"),
      error = base::c("old error", "same error", "new error"),
      time = base::c(time_before, time_after, time_after)
    )

  res <-
    get_new_targets_errors(
      data_errors_before = data_before,
      data_errors_after = data_after
    )

  testthat::expect_identical(
    res[["name"]],
    base::c("retried", "new")
  )
})

testthat::test_that("get_new_targets_errors() ignores missing errors", {
  data_empty <-
    tibble::tibble(
      name = "target",
      error = NA_character_,
      time = base::as.POSIXct(NA)
    )

  testthat::expect_equal(
    base::nrow(
      get_new_targets_errors(
        data_errors_before = data_empty,
        data_errors_after = data_empty
      )
    ),
    0L
  )
})
