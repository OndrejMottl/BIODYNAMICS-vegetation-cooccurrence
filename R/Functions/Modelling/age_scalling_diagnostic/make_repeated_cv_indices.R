#' @title Make Repeated Cross-Validation Indices
#' @description
#' Creates reproducible repeated K-fold test-index lists for use with
#' `sjSDM::sjSDM_cv()`.
#' @param n_samples
#' Single integer. Number of samples to split into folds.
#' @param n_folds
#' Single integer. Number of folds per repeat. Default is `2L`.
#' @param n_repeats
#' Single integer. Number of repeated fold partitions. Default is `1L`.
#' @param seed
#' Single integer. Random seed used for reproducible fold assignment.
#' @return
#' A named list with one element per repeat. Each repeat is a named list
#' of integer test indices, one element per fold.
#' @export
make_repeated_cv_indices <- function(
    n_samples,
    n_folds = 2L,
    n_repeats = 1L,
    seed = 900723L) {
  assertthat::assert_that(
    base::is.numeric(n_samples),
    base::length(n_samples) == 1L,
    base::is.finite(n_samples),
    n_samples >= 2L,
    msg = "`n_samples` must be a single finite number >= 2."
  )

  assertthat::assert_that(
    base::is.numeric(n_folds),
    base::length(n_folds) == 1L,
    base::is.finite(n_folds),
    n_folds >= 2L,
    msg = "`n_folds` must be a single finite number >= 2."
  )

  assertthat::assert_that(
    base::is.numeric(n_repeats),
    base::length(n_repeats) == 1L,
    base::is.finite(n_repeats),
    n_repeats >= 1L,
    msg = "`n_repeats` must be a single finite number >= 1."
  )

  assertthat::assert_that(
    base::is.numeric(seed),
    base::length(seed) == 1L,
    base::is.finite(seed),
    msg = "`seed` must be a single finite number."
  )

  n_samples <- base::as.integer(n_samples)
  n_folds <- base::as.integer(n_folds)
  n_repeats <- base::as.integer(n_repeats)
  seed <- base::as.integer(seed)

  assertthat::assert_that(
    n_folds <= n_samples,
    msg = "`n_folds` must be less than or equal to `n_samples`."
  )

  flag_had_seed <-
    base::exists(
      x = ".Random.seed",
      envir = .GlobalEnv,
      inherits = FALSE
    )

  if (
    flag_had_seed
  ) {
    old_seed <-
      base::get(
        x = ".Random.seed",
        envir = .GlobalEnv,
        inherits = FALSE
      )
  } else {
    old_seed <- NULL
  }

  on.exit(
    expr = {
      if (
        flag_had_seed
      ) {
        base::assign(
          x = ".Random.seed",
          value = old_seed,
          envir = .GlobalEnv
        )
      } else if (
        base::exists(
          x = ".Random.seed",
          envir = .GlobalEnv,
          inherits = FALSE
        )
      ) {
        base::rm(
          list = ".Random.seed",
          envir = .GlobalEnv
        )
      }
    },
    add = TRUE
  )

  base::set.seed(seed)

  res <-
    base::seq_len(n_repeats) |>
    purrr::map(
      .f = ~ {
        vec_indices <-
          base::sample.int(n = n_samples)

        vec_fold_id <-
          base::rep(
            x = base::seq_len(n_folds),
            length.out = n_samples
          )

        vec_indices |>
          base::split(f = vec_fold_id) |>
          purrr::map(base::sort) |>
          rlang::set_names(
            nm = stringr::str_glue(
              "fold_{stringr::str_pad(seq_len(n_folds), 3, pad = '0')}"
            )
          )
      }
    ) |>
    rlang::set_names(
      nm = stringr::str_glue(
        "repeat_{stringr::str_pad(seq_len(n_repeats), 3, pad = '0')}"
      )
    )

  return(res)
}
