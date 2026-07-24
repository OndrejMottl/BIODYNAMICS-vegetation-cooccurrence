testthat::test_that(
  "build_sjsdm_tuning_schedule() builds the production budget",
  {
    data_schedule <-
      build_sjsdm_tuning_schedule(
        tuning_strategy = "staged",
        n_candidates = 8L,
        repeat_ids = 1:3,
        survivor_counts = base::c(4L, 2L)
      )

    testthat::expect_s3_class(data_schedule, "data.frame")
    testthat::expect_identical(
      data_schedule[["n_candidates_entering"]],
      base::c(8L, 4L, 2L)
    )
    testthat::expect_identical(
      data_schedule[["n_candidates_surviving"]],
      base::c(4L, 2L, 1L)
    )
    testthat::expect_identical(data_schedule[["repeat_id"]], 1:3)
    testthat::expect_identical(
      base::unique(data_schedule[["strategy_version"]]),
      "sjsdm_staged_tuning_v1"
    )
  }
)

testthat::test_that(
  "build_sjsdm_tuning_schedule() supports exhaustive tuning",
  {
    data_schedule <-
      build_sjsdm_tuning_schedule(
        tuning_strategy = "exhaustive",
        n_candidates = 3L,
        repeat_ids = 1:2
      )

    testthat::expect_identical(
      data_schedule[["n_candidates_entering"]],
      base::c(3L, 3L)
    )
    testthat::expect_identical(
      data_schedule[["n_candidates_surviving"]],
      base::c(3L, 1L)
    )
    testthat::expect_identical(
      base::unique(data_schedule[["strategy_version"]]),
      "sjsdm_exhaustive_tuning_v1"
    )
  }
)

testthat::test_that(
  "build_sjsdm_tuning_schedule() rejects invalid staged settings",
  {
    testthat::expect_error(
      build_sjsdm_tuning_schedule(
        tuning_strategy = "staged",
        n_candidates = 8L,
        repeat_ids = 1:3,
        survivor_counts = base::c(4L, 4L)
      ),
      "strictly decrease"
    )

    testthat::expect_error(
      build_sjsdm_tuning_schedule(
        tuning_strategy = "staged",
        n_candidates = 8L,
        repeat_ids = 1:2,
        survivor_counts = base::c(4L, 2L)
      ),
      "one fewer"
    )

    testthat::expect_error(
      build_sjsdm_tuning_schedule(
        tuning_strategy = "staged",
        n_candidates = 1L,
        repeat_ids = 1L,
        survivor_counts = base::integer()
      ),
      "at least two"
    )

    testthat::expect_error(
      build_sjsdm_tuning_schedule(
        tuning_strategy = "staged",
        n_candidates = 8L,
        repeat_ids = base::c(1L, 3L, 4L),
        survivor_counts = base::c(4L, 2L)
      ),
      "permutation"
    )
  }
)
