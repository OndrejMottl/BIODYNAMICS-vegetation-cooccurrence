#' @title Interpolate Grouped Time Series
#' @description
#' Interpolates grouped numeric time series to a regular age grid.
#' @param data_time_series
#' A data frame containing grouping, age, and value columns.
#' @param grouping_variables
#' A character vector of column names that define independent time series.
#' @param age_variable_name
#' Name of the numeric age column.
#' @param value_variable_name
#' Name of the numeric value column.
#' @param interpolation_method
#' Interpolation method passed to [stats::approx()].
#' @param extrapolation_rule
#' Numeric extrapolation rule passed to [stats::approx()].
#' @param ties_function
#' Function used by [stats::approx()] to combine tied ages.
#' @param age_min
#' Minimum age in the output grid.
#' @param age_max
#' Maximum age in the output grid.
#' @param time_step
#' Positive spacing between consecutive ages in the output grid.
#' @param n_cores
#' Number of workers. Use `1` for sequential `purrr::map()` execution or a
#' larger integer for parallel `furrr::future_map()` execution.
#' @param show_progress
#' Logical indicating whether supported map operations display progress.
#' @return
#' A data frame containing the grouping columns and interpolated age and value
#' columns.
#' @details
#' Each unique combination of `grouping_variables` is interpolated
#' independently with [stats::approx()]. Groups that cannot be interpolated
#' return no rows.
#'
#' Parallel execution temporarily owns the active `{future}` plan. The previous
#' plan is restored when the function exits.
#' @seealso [stats::approx()]
#' @export
interpolate_grouped_time_series <- function(
    data_time_series = NULL,
    grouping_variables = "dataset_name",
    age_variable_name = "age",
    value_variable_name = "value",
    interpolation_method = "linear",
    extrapolation_rule = 1,
    ties_function = base::mean,
    age_min = 0,
    age_max = 12e03,
    time_step = 500,
    n_cores = 1,
    show_progress = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data_time_series),
    msg = "data_time_series must be a data frame"
  )

  assertthat::assert_that(
    base::is.character(grouping_variables) &&
      base::length(grouping_variables) > 0L &&
      !base::anyNA(grouping_variables),
    msg = stringr::str_c(
      "grouping_variables must be a character vector ",
      "with at least one non-missing element"
    )
  )

  assertthat::assert_that(
    base::all(
      grouping_variables %in% base::colnames(data_time_series)
    ),
    msg = stringr::str_glue(
      "data_time_series must contain the following grouping columns: ",
      "{stringr::str_c(grouping_variables, collapse = ', ')}"
    )
  )

  assertthat::assert_that(
    base::is.character(age_variable_name) &&
      base::length(age_variable_name) == 1L &&
      !base::is.na(age_variable_name),
    msg = "age_variable_name must be one non-missing character string"
  )

  assertthat::assert_that(
    base::is.character(value_variable_name) &&
      base::length(value_variable_name) == 1L &&
      !base::is.na(value_variable_name),
    msg = "value_variable_name must be one non-missing character string"
  )

  assertthat::assert_that(
    base::all(
      base::c(
        age_variable_name,
        value_variable_name
      ) %in% base::colnames(data_time_series)
    ),
    msg = stringr::str_glue(
      "data_time_series must contain age column `{age_variable_name}` ",
      "and value column `{value_variable_name}`"
    )
  )

  assertthat::assert_that(
    base::is.character(interpolation_method) &&
      base::length(interpolation_method) == 1L &&
      !base::is.na(interpolation_method),
    msg = "interpolation_method must be one non-missing character string"
  )

  assertthat::assert_that(
    base::is.numeric(extrapolation_rule) &&
      base::length(extrapolation_rule) == 1L &&
      base::is.finite(extrapolation_rule),
    msg = "extrapolation_rule must be one finite numeric value"
  )

  assertthat::assert_that(
    base::is.function(ties_function),
    msg = "ties_function must be a function"
  )

  assertthat::assert_that(
    base::is.numeric(age_min) &&
      base::length(age_min) == 1L &&
      base::is.finite(age_min),
    msg = "age_min must be one finite numeric value"
  )

  assertthat::assert_that(
    base::is.numeric(age_max) &&
      base::length(age_max) == 1L &&
      base::is.finite(age_max),
    msg = "age_max must be one finite numeric value"
  )

  assertthat::assert_that(
    age_min < age_max,
    msg = "age_min must be less than age_max"
  )

  assertthat::assert_that(
    base::is.numeric(time_step) &&
      base::length(time_step) == 1L &&
      base::is.finite(time_step) &&
      time_step > 0,
    msg = "time_step must be one finite value greater than 0"
  )

  assertthat::assert_that(
    base::is.numeric(n_cores) &&
      base::length(n_cores) == 1L &&
      base::is.finite(n_cores) &&
      n_cores >= 1 &&
      n_cores == base::as.integer(n_cores),
    msg = "n_cores must be a single positive integer"
  )

  assertthat::assert_that(
    base::is.logical(show_progress) &&
      base::length(show_progress) == 1L &&
      !base::is.na(show_progress),
    msg = "show_progress must be one non-missing logical value"
  )

  n_cores <-
    base::as.integer(n_cores)

  compute_interpolation_on_age_grid_function <-
    .compute_interpolation_on_age_grid

  base::environment(compute_interpolation_on_age_grid_function) <-
    base::baseenv()

  interpolate_configured_group <-
    rlang::new_function(
      args = base::alist(data_time_series_group = ),
      body = base::quote(
        compute_interpolation_on_age_grid_function(
          data_time_series_group = data_time_series_group,
          age_variable_name = age_variable_name,
          value_variable_name = value_variable_name,
          interpolation_method = interpolation_method,
          extrapolation_rule = extrapolation_rule,
          ties_function = ties_function,
          age_min = age_min,
          age_max = age_max,
          time_step = time_step
        )
      ),
      env = rlang::env(
        base::baseenv(),
        compute_interpolation_on_age_grid_function =
          compute_interpolation_on_age_grid_function,
        age_variable_name = age_variable_name,
        value_variable_name = value_variable_name,
        interpolation_method = interpolation_method,
        extrapolation_rule = extrapolation_rule,
        ties_function = ties_function,
        age_min = age_min,
        age_max = age_max,
        time_step = time_step
      )
    )

  interpolate_one_group <-
    purrr::possibly(
      .f = interpolate_configured_group,
      otherwise = NULL
    )

  # `purrr::possibly()` creates a wrapper with its own environment. Strip that
  # wrapper so future workers receive only the small interpolation closure.
  base::environment(interpolate_one_group) <-
    rlang::env(
      base::baseenv(),
      .f = interpolate_configured_group,
      otherwise = NULL,
      quiet = TRUE
    )

  data_time_series_nested <-
    data_time_series |>
    tidyr::nest(
      data_time_series_group =
        !dplyr::any_of(grouping_variables)
    )

  data_time_series_nested <-
    if (
      n_cores == 1L
    ) {
      data_time_series_nested |>
        dplyr::mutate(
          data_interpolated = purrr::map(
            .x = data_time_series_group,
            .f = interpolate_one_group,
            .progress = show_progress
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

      base::on.exit(
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

      package_version_warning_handler <-
        .muffle_package_version_warning

      base::environment(package_version_warning_handler) <-
        base::baseenv()

      data_time_series_nested |>
        dplyr::mutate(
          data_interpolated = base::withCallingHandlers(
            furrr::future_map(
              .x = data_time_series_group,
              .f = interpolate_one_group,
              .progress = show_progress,
              .env_globals = base::emptyenv()
            ),
            warning = package_version_warning_handler
          )
        )
    }

  data_interpolated <-
    data_time_series_nested |>
    tidyr::unnest(data_interpolated) |>
    dplyr::select(
      dplyr::any_of(grouping_variables),
      !!rlang::sym(age_variable_name),
      !!rlang::sym(value_variable_name)
    )

  base::return(data_interpolated)
}
