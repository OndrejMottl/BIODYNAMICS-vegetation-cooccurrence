testthat::test_that(
  "make_repeated_cv_indices() creates exhaustive folds",
  {
    list_indices <-
      make_repeated_cv_indices(
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
  "make_repeated_cv_indices() is reproducible",
  {
    list_indices_one <-
      make_repeated_cv_indices(
        n_samples = 12L,
        n_folds = 3L,
        n_repeats = 2L,
        seed = 900723L
      )

    list_indices_two <-
      make_repeated_cv_indices(
        n_samples = 12L,
        n_folds = 3L,
        n_repeats = 2L,
        seed = 900723L
      )

    testthat::expect_equal(list_indices_one, list_indices_two)
  }
)

testthat::test_that(
  "make_repeated_cv_indices() rejects impossible fold counts",
  {
    testthat::expect_error(
      make_repeated_cv_indices(
        n_samples = 3L,
        n_folds = 4L,
        n_repeats = 1L
      ),
      "`n_folds` must be less than or equal to `n_samples`."
    )
  }
)
