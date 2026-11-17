#' @title Load the Modelled Temporal Slice Ages
#' @description
#' Returns the time slices that a paleo temporal profile models, from the
#' profile's modelled-slice window and time step.
#' @param config_id
#' Configuration profile identifier. Defaults to the active profile
#' (`R_CONFIG_ACTIVE`).
#' @param file
#' Path to the generated configuration file.
#' @param flag_modelled_only
#' Logical. If `TRUE` (default), return only modelled slices. If `FALSE`,
#' also return slices inside the window that the profile excludes, with a
#' `flag_modelled` column.
#' @return
#' A tibble with columns `age` (numeric, years BP) and `age_name`
#' (`timeslice_<age>`), one row per slice in increasing age, plus
#' `flag_modelled` when `flag_modelled_only = FALSE`.
#' @details
#' The window is `temporal_slices.age_window` and the step is
#' `data_processing.time_step`. The window is deliberately separate from
#' `vegvault_data.age_lim`, which bounds data extraction and feeds the
#' expensive age interpolation: narrowing the modelled window must not
#' invalidate that preparation. Slices outside the window are not modelled.
#'
#' `temporal_slices.excluded_ages` (optional) lists ages inside the window
#' that are known to be infeasible, such as a slice with fewer samples than
#' `min_n_samples`. They are left out of the pipeline because an infeasible
#' slice aborts the whole temporal build at its dynamic tuning branches
#' (`cannot branch over empty target`), which would block every other slice.
#' @examples
#' \dontrun{
#' load_temporal_slice_ages(config_id = "project_paleo_temporal_europe")
#' }
#' @export
load_temporal_slice_ages <- function(
    config_id = base::Sys.getenv("R_CONFIG_ACTIVE"),
    file = here::here("config.yml"),
    flag_modelled_only = TRUE) {
  assertthat::assert_that(
    assertthat::is.string(config_id),
    base::nzchar(config_id),
    msg = "`config_id` must be one non-empty profile identifier."
  )

  # Read the parent key: config::get() errors on a nested path whose parent
  #   is missing, but returns NULL for a missing top-level key.
  list_temporal_slices <-
    load_config_value(
      config_id = config_id,
      value = "temporal_slices",
      file = file
    )
  vec_age_window <-
    purrr::pluck(list_temporal_slices, "age_window", .default = NULL)
  vec_excluded_ages <-
    purrr::pluck(
      list_temporal_slices,
      "excluded_ages",
      .default = base::numeric()
    )
  time_step <-
    load_config_value(
      config_id = config_id,
      value = base::c("data_processing", "time_step"),
      file = file
    )

  if (
    base::is.null(vec_age_window)
  ) {
    cli::cli_abort(
      base::c(
        "Profile {.val {config_id}} has no modelled-slice window.",
        "i" = "Set `temporal_slices.age_window` in its profile."
      ),
      class = "temporal_slice_window_missing"
    )
  }

  assertthat::assert_that(
    base::is.numeric(vec_age_window),
    base::length(vec_age_window) == 2L,
    base::all(base::is.finite(vec_age_window)),
    vec_age_window[[1L]] <= vec_age_window[[2L]],
    msg = "`temporal_slices.age_window` must be two increasing ages."
  )
  assertthat::assert_that(
    assertthat::is.flag(flag_modelled_only),
    !base::is.na(flag_modelled_only),
    msg = "`flag_modelled_only` must be TRUE or FALSE."
  )
  assertthat::assert_that(
    base::is.numeric(vec_excluded_ages),
    base::all(base::is.finite(vec_excluded_ages)),
    msg = "`temporal_slices.excluded_ages` must be numeric ages."
  )
  assertthat::assert_that(
    assertthat::is.number(time_step),
    time_step > 0,
    msg = "`data_processing.time_step` must be one positive number."
  )

  vec_ages <-
    base::seq(
      from = vec_age_window[[1L]],
      to = vec_age_window[[2L]],
      by = time_step
    )

  assertthat::assert_that(
    base::all(vec_excluded_ages %in% vec_ages),
    msg = "Every excluded age must be a slice inside the window."
  )

  data_slices <-
    tibble::tibble(
      age = vec_ages,
      age_name = stringr::str_c("timeslice_", vec_ages),
      flag_modelled = !vec_ages %in% vec_excluded_ages
    )

  res <-
    if (
      flag_modelled_only
    ) {
      data_slices |>
        dplyr::filter(.data[["flag_modelled"]]) |>
        dplyr::select("age", "age_name")
    } else {
      data_slices
    }

  return(res)
}
