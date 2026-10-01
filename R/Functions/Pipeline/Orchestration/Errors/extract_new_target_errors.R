#' @title Get New Targets Errors
#' @description
#' Compares `{targets}` error metadata before and after a pipeline run and
#' returns errors newly recorded or retried by that run.
#' @param data_errors_before
#' Error metadata captured before execution.
#' @param data_errors_after
#' Error metadata captured after execution.
#' @return
#' A tibble of new error records with `name`, `error`, and `time` columns.
#' Direct target errors precede cascading dependency-load errors while the
#' original order is retained within both groups.
#' @export
extract_new_target_errors <- function(
    data_errors_before = NULL,
    data_errors_after = NULL) {
  vec_required_columns <-
    base::c("name", "error", "time")

  assertthat::assert_that(
    base::is.data.frame(data_errors_before),
    base::is.data.frame(data_errors_after),
    base::all(
      vec_required_columns %in%
        base::colnames(data_errors_before)
    ),
    base::all(
      vec_required_columns %in%
        base::colnames(data_errors_after)
    ),
    msg = "Targets error metadata is incomplete."
  )

  res <-
    data_errors_after |>
    dplyr::filter(
      !base::is.na(.data[["error"]]),
      base::nzchar(.data[["error"]])
    ) |>
    dplyr::anti_join(
      data_errors_before |>
        dplyr::filter(
          !base::is.na(.data[["error"]]),
          base::nzchar(.data[["error"]])
      ),
      by = dplyr::join_by(name, error, time)
    ) |>
    dplyr::mutate(
      flag_dependency_error = base::startsWith(
        base::tolower(.data[["error"]]),
        "could not load dependency"
      )
    ) |>
    dplyr::arrange(.data[["flag_dependency_error"]]) |>
    dplyr::select(-dplyr::all_of("flag_dependency_error"))

  base::return(res)
}
