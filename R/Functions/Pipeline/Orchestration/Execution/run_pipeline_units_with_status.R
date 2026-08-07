#' @title Run Pipeline Units With Status Capture
#' @description
#' Runs one isolated pipeline store per unit, continuing after unit failures
#' while retaining an explicit status row for every requested unit.
#' @param scale_ids
#' Non-empty character vector of unique spatial unit identifiers.
#' @param sel_script
#' Single pipeline script path passed to `run_pipeline_function`.
#' @param run_pipeline_function
#' Injectable pipeline runner called with `sel_script`, `store_suffix`, and
#' arguments supplied through `...`. Defaults to [run_pipeline()].
#' @param progress
#' Logical scalar controlling the progress indicator. Defaults to `TRUE`.
#' @param verbose
#' Logical scalar controlling per-unit status messages. Defaults to `TRUE`.
#' @param ...
#' Additional named arguments passed to `run_pipeline_function`.
#' @return
#' Tibble with one row per requested unit and columns `scale_id`,
#' `pipeline_status` (`"ok"` or `"error"`), and `error_message`.
#' @details
#' This helper is intended for post-selection full-unit execution. Upstream
#' tuning-summary production remains fail-fast so tier selection cannot use
#' incomplete evidence.
#' @examples
#' \dontrun{
#' run_pipeline_units_with_status(
#'   scale_ids = c("eu_r01", "eu_r02"),
#'   sel_script = "R/Pipelines/pipeline_paleo_spatial_resolution.R",
#'   prebuild_interpolation = TRUE
#' )
#' }
#' @export
run_pipeline_units_with_status <- function(
    scale_ids = NULL,
    sel_script = NULL,
    run_pipeline_function = run_pipeline,
    progress = TRUE,
    ...,
    verbose = TRUE) {
  flag_valid_scale_ids <-
    base::is.character(scale_ids) &&
    base::length(scale_ids) > 0L &&
    base::all(!base::is.na(scale_ids)) &&
    base::all(base::nzchar(scale_ids)) &&
    !base::any(base::duplicated(scale_ids))

  assertthat::assert_that(
    flag_valid_scale_ids,
    msg = "`scale_ids` must contain unique non-empty strings."
  )

  assertthat::assert_that(
    base::is.character(sel_script),
    base::length(sel_script) == 1L,
    !base::is.na(sel_script),
    base::nzchar(sel_script),
    msg = "`sel_script` must be one non-empty string."
  )

  assertthat::assert_that(
    base::is.function(run_pipeline_function),
    msg = "`run_pipeline_function` must be a function."
  )

  assertthat::assert_that(
    assertthat::is.flag(progress),
    msg = "`progress` must be `TRUE` or `FALSE`."
  )

  assertthat::assert_that(
    assertthat::is.flag(verbose),
    msg = "`verbose` must be `TRUE` or `FALSE`."
  )

  additional_arguments <-
    base::list(...)

  additional_argument_names <-
    base::names(additional_arguments)

  flag_valid_additional_arguments <-
    base::length(additional_arguments) == 0L ||
    (
      !base::is.null(additional_argument_names) &&
        base::all(base::nzchar(additional_argument_names)) &&
        !base::any(
          additional_argument_names %in%
            base::c("sel_script", "store_suffix")
        )
    )

  assertthat::assert_that(
    flag_valid_additional_arguments,
    msg = stringr::str_c(
      "Additional pipeline arguments must be named and cannot replace ",
      "`sel_script` or `store_suffix`."
    )
  )

  res <-
    scale_ids |>
    purrr::map(
      .progress = progress,
      .f = function(scale_id) {
        if (
          base::isTRUE(verbose)
        ) {
          base::message(
            "Running pipeline for spatial unit: ",
            scale_id
          )
        }

        error_condition <-
          tryCatch(
            expr = {
              base::do.call(
                what = run_pipeline_function,
                args = base::c(
                  base::list(
                    sel_script = sel_script,
                    store_suffix = scale_id
                  ),
                  additional_arguments
                )
              )

              NULL
            },
            error = function(error_captured) {
              error_captured
            }
          )

        if (
          base::inherits(error_condition, "error")
        ) {
          error_message <-
            base::conditionMessage(error_condition)

          if (
            base::isTRUE(verbose)
          ) {
            base::message(
              "Pipeline failed for spatial unit ",
              scale_id,
              ": ",
              error_message
            )
          }

          pipeline_status <-
            "error"
        } else {
          error_message <-
            NA_character_

          pipeline_status <-
            "ok"
        }

        return(
          tibble::tibble(
            scale_id = scale_id,
            pipeline_status = pipeline_status,
            error_message = error_message
          )
        )
      }
    ) |>
    purrr::list_rbind()

  return(res)
}
