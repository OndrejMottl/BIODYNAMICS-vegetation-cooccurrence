#' @title Interpolate Data
#' @description
#' Interpolates data over a specified age range and timestep using a method.
#' @param data
#' A data frame containing the data to be interpolated.
#' @param by
#' A character vector of column name(s) to group by when nesting data for
#' interpolation (default: "dataset_name").
#' @param age_var
#' Name of the age variable column (default: "age").
#' @param value_var
#' Name of the value variable column (default: "value").
#' @param method
#' Interpolation method to use (default: "linear").
#' @param rule
#' Integer specifying the extrapolation rule (default: 1).
#' @param ties
#' Function to handle tied values (default: `mean`).
#' @param age_min
#' Minimum age for interpolation (default: 0).
#' @param age_max
#' Maximum age for interpolation (default: 12000).
#' @param timestep
#' Timestep for interpolation (default: 500).
#' @param n_cores
#' Number of cores to use for interpolation. Use `1` for sequential
#' `purrr::map()` execution, or a value greater than `1` for parallel
#' `furrr::future_map()` execution.
#' @param verbose
#' Logical. If `TRUE` (default), progress bars are displayed where supported.
#' @return
#' A data frame with interpolated values, including dataset name, taxon, age,
#' and value columns.
#' @details
#' Nests data by dataset and taxon. It interpolates with `stats::approx()`
#' and returns the interpolated data in a flat format.
#' @seealso [stats::approx()]
#' @export
interpolate_data <- function(data = NULL,
                             by = "dataset_name",
                             age_var = "age",
                             value_var = "value",
                             method = "linear",
                             rule = 1,
                             ties = mean,
                             age_min = 0,
                             age_max = 12e03,
                             timestep = 500,
                             n_cores = 1,
                             verbose = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    base::is.character(by) && base::length(by) > 0,
    msg = "by must be a character vector with at least one element"
  )

  assertthat::assert_that(
    base::all(by %in% base::colnames(data)),
    msg = stringr::str_glue(
      "data must contain the following columns: ",
      "{stringr::str_c(by, collapse = ', ')}"
    )
  )

  assertthat::assert_that(
    base::is.character(age_var) && base::length(age_var) == 1,
    msg = "age_var must be a single character string"
  )

  assertthat::assert_that(
    base::is.character(value_var) && base::length(value_var) == 1,
    msg = "value_var must be a single character string"
  )

  assertthat::assert_that(
    base::is.character(method) && base::length(method) == 1,
    msg = "method must be a single character string"
  )

  assertthat::assert_that(
    base::is.numeric(rule) && base::length(rule) == 1,
    msg = "rule must be a single numeric value"
  )

  assertthat::assert_that(
    base::is.function(ties),
    msg = "ties must be a function"
  )

  assertthat::assert_that(
    base::is.numeric(age_min) && base::length(age_min) == 1,
    msg = "age_min must be a single numeric value"
  )

  assertthat::assert_that(
    base::is.numeric(age_max) && base::length(age_max) == 1,
    msg = "age_max must be a single numeric value"
  )

  assertthat::assert_that(
    age_min < age_max,
    msg = "age_min must be less than age_max"
  )

  assertthat::assert_that(
    base::is.numeric(timestep) && base::length(timestep) == 1,
    msg = "timestep must be a single numeric value"
  )

  assertthat::assert_that(
    timestep > 0,
    msg = "timestep must be greater than 0"
  )

  assertthat::assert_that(
    base::is.numeric(n_cores) &&
      base::length(n_cores) == 1 &&
      base::is.finite(n_cores) &&
      n_cores >= 1 &&
      n_cores == base::as.integer(n_cores),
    msg = "n_cores must be a single positive integer"
  )

  assertthat::assert_that(
    base::is.logical(verbose) && base::length(verbose) == 1,
    msg = "verbose must be a single logical value"
  )

  n_cores <-
    base::as.integer(n_cores)

  # Future workers can replay package-version warnings when they start.
  # These are environment noise and otherwise get stored as target warnings.
  muffle_package_version_warning <- function(condition) {
    warning_message <-
      base::conditionMessage(condition)

    if (
      base::startsWith(warning_message, "package '") &&
        base::grepl(
          pattern = "built under R version",
          x = warning_message,
          fixed = TRUE
        )
    ) {
      base::invokeRestart("muffleWarning")
    }
  }

  # The actual interpolation happens one nested group at a time.
  # Grouping is controlled by `by`, so this helper stays group-agnostic.
  interpolate_group <- function(data_nested_group) {
    data_nested_group |>
      dplyr::select(
        !!rlang::sym(age_var),
        !!rlang::sym(value_var)
      ) |>
      grDevices::xy.coords() |>
      stats::approx(
        xout = base::seq(
          age_min,
          age_max,
          by = timestep
        ),
        ties = ties,
        method = method,
        rule = rule
      ) |>
      tibble::as_tibble() |>
      dplyr::rename(
        !!rlang::sym(age_var) := x,
        !!rlang::sym(value_var) := y
      )
  }

  # Future finds globals through function environments. Keep the mapped
  # helper detached from target data so workers receive only small scalars.
  base::environment(interpolate_group) <-
    rlang::env(
      base::baseenv(),
      age_max = age_max,
      age_min = age_min,
      age_var = age_var,
      method = method,
      rule = rule,
      ties = ties,
      timestep = timestep,
      value_var = value_var
    )

  interpolate_one <-
    purrr::possibly(
      .f = interpolate_group,
      otherwise = NULL
    )

  # `purrr::possibly()` creates a wrapper with its own environment.
  # Strip that wrapper too, otherwise it can still capture target data.
  base::environment(interpolate_one) <-
    rlang::env(
      base::baseenv(),
      .f = interpolate_group,
      otherwise = NULL,
      quiet = TRUE
    )

  data_nested <-
    data |>
    tidyr::nest(
      data_nested = !dplyr::any_of(by)
    )

  data_nested <-
    if (
      n_cores == 1L
    ) {
      data_nested |>
        dplyr::mutate(
          data_interpolated = purrr::map(
            .progress = verbose,
            .x = data_nested,
            .f = interpolate_one
          )
        )
    } else {
      if (
        !base::requireNamespace("furrr", quietly = TRUE)
      ) {
        base::stop(
          "Package 'furrr' is required when n_cores is greater than 1",
          call. = FALSE
        )
      }

      # Use forked workers where supported; Windows needs multisession.
      future_strategy <-
        if (
          base::Sys.info()[["sysname"]] == "Windows" ||
            !future::supportsMulticore()
        ) {
          "multisession"
        } else {
          "multicore"
        }

      future_plan_previous <-
        future::plan()

      # This function temporarily owns the future plan for its map call.
      # Restore the caller's plan even if interpolation fails.
      on.exit(
        future::plan(future_plan_previous),
        add = TRUE
      )

      if (
        future_strategy == "multicore"
      ) {
        future::plan(
          future::multicore,
          workers = n_cores
        )
      } else {
        future::plan(
          future::multisession,
          workers = n_cores
        )
      }

      data_nested |>
        dplyr::mutate(
          data_interpolated = base::withCallingHandlers(
            furrr::future_map(
              .progress = verbose,
              .x = data_nested,
              .f = interpolate_one,
              .env_globals = base::emptyenv()
            ),
            warning = muffle_package_version_warning
          )
        )
    }

  res <-
    data_nested |>
    tidyr::unnest(data_interpolated) |>
    dplyr::select(
      dplyr::any_of(by),
      !!rlang::sym(age_var),
      !!rlang::sym(value_var)
    )

  base::return(res)
}
