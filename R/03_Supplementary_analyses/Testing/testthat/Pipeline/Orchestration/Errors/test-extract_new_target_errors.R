testthat::test_that(
  "extract_new_target_errors() detects new and retried errors",
  {
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
      extract_new_target_errors(
        data_errors_before = data_before,
        data_errors_after = data_after
      )

    testthat::expect_identical(
      res[["name"]],
      base::c("retried", "new")
    )
  }
)

testthat::test_that("extract_new_target_errors() ignores missing errors", {
  data_empty <-
    tibble::tibble(
      name = "target",
      error = NA_character_,
      time = base::as.POSIXct(NA)
    )

  testthat::expect_equal(
    base::nrow(
      extract_new_target_errors(
        data_errors_before = data_empty,
        data_errors_after = data_empty
      )
    ),
    0L
  )
  }
)

testthat::test_that(
  "extract_new_target_errors() prioritizes direct target errors",
  {
    time_after <-
      base::as.POSIXct("2026-09-23 03:00:00", tz = "UTC")
    data_before <-
      tibble::tibble(
        name = base::character(),
        error = base::character(),
        time = base::as.POSIXct(base::character())
      )
    data_after <-
      tibble::tibble(
        name = base::c("dependent", "root", "dependent_two"),
        error = base::c(
          "could not load dependency root of target dependent. qs missing",
          "argument of length 0",
          "Could not load dependency root of target dependent_two"
        ),
        time = base::rep(time_after, 3L)
      )

    res <-
      extract_new_target_errors(
        data_errors_before = data_before,
        data_errors_after = data_after
      )

    testthat::expect_identical(
      res[["name"]],
      base::c("root", "dependent", "dependent_two")
    )
  }
)
