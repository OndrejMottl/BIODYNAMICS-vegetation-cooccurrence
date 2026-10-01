testthat::test_that(
  "load_results_snapshot() loads frozen result metadata",
  {
    path_snapshot <-
      here::here(
        "Documentation",
        "Presentations",
        "CSPE_2026",
        "results_snapshot.json"
      )

    list_snapshot <-
      load_results_snapshot(path = path_snapshot)

    testthat::expect_identical(
      list_snapshot[["mode"]],
      "frozen_iavs_artifacts"
    )
    testthat::expect_identical(
      list_snapshot[["snapshot_id"]],
      "2026-08-31_pre_trait_cv_rerun"
    )
    testthat::expect_equal(
      list_snapshot[["summary_counts"]][["models"]],
      263
    )
  }
)

testthat::test_that(
  "load_results_snapshot() rejects missing fields",
  {
    path_snapshot <-
      base::tempfile(fileext = ".json")

    jsonlite::write_json(
      x = base::list(mode = "frozen_iavs_artifacts"),
      path = path_snapshot,
      auto_unbox = TRUE
    )

    testthat::expect_error(
      load_results_snapshot(path = path_snapshot),
      "missing required fields"
    )
  }
)

testthat::test_that(
  "load_results_snapshot() does not require the archive to exist",
  {
    path_snapshot <-
      base::tempfile(fileext = ".json")

    list_snapshot <-
      base::list(
        schema_version = 1L,
        mode = "frozen_iavs_artifacts",
        snapshot_id = "example_snapshot",
        snapshot_display_date = "Example date",
        source_presentation = "example_source",
        spatial_targets_archive = "Z:/unavailable/archive",
        rationale = "Frozen test results.",
        summary_counts = base::list(
          cores = 1L,
          communities = 2L,
          taxa = 3L,
          trait_values = 4L,
          functional_types = 5L,
          models = 6L
        )
      )

    jsonlite::write_json(
      x = list_snapshot,
      path = path_snapshot,
      auto_unbox = TRUE,
      pretty = TRUE
    )

    testthat::expect_no_error(
      load_results_snapshot(path = path_snapshot)
    )
  }
)
