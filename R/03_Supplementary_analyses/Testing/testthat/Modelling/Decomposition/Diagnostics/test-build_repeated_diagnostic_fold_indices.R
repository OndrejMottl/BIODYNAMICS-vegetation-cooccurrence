testthat::test_that(
  "build_repeated_diagnostic_fold_indices() creates exhaustive folds",
  {
    list_indices <-
      build_repeated_diagnostic_fold_indices(
        n_samples = 10L,
        n_folds = 2L,
        n_repeats = 1L,
        seed = 900723L
      )

    vec_indices <-
      list_indices |>
      purrr::chuck(1L) |>
      base::unlist(use.names = FALSE) |>
      base::sort()

    testthat::expect_equal(vec_indices, base::seq_len(10L))
  }
)

testthat::test_that(
  "build_repeated_diagnostic_fold_indices() is reproducible",
  {
    list_indices_one <-
      build_repeated_diagnostic_fold_indices(
        n_samples = 12L,
        n_folds = 3L,
        n_repeats = 2L,
        seed = 900723L
      )

    list_indices_two <-
      build_repeated_diagnostic_fold_indices(
        n_samples = 12L,
        n_folds = 3L,
        n_repeats = 2L,
        seed = 900723L
      )

    testthat::expect_equal(list_indices_one, list_indices_two)
  }
)

testthat::test_that(
  "build_repeated_diagnostic_fold_indices() rejects impossible fold counts",
  {
    testthat::expect_error(
      build_repeated_diagnostic_fold_indices(
        n_samples = 3L,
        n_folds = 4L,
        n_repeats = 1L
      ),
      "`n_folds` must be less than or equal to `n_samples`."
    )
  }
)

testthat::test_that(
  "build_repeated_diagnostic_fold_indices() documents its consumer",
  {
    source_text <-
      here::here(
        "R/Functions/Modelling/Decomposition/Diagnostics",
        "build_repeated_diagnostic_fold_indices.R"
      ) |>
      base::readLines(warn = FALSE) |>
      stringr::str_c(collapse = "\n")

    testthat::expect_match(
      source_text,
      "run_decomposition_diagnostic_folds"
    )
    testthat::expect_false(
      stringr::str_detect(source_text, "sjSDM_cv")
    )
  }
)
