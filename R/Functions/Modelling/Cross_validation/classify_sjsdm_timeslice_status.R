#' @title Classify the Status of Each Temporal Slice
#' @description
#' Classifies every time slice of one temporal store as fitted (`ok`), an
#' expected infeasible slice, an unexpected error, a slice that was not built,
#' or a slice outside the modelled window, from the store's target metadata.
#' @param data_target_errors
#' Data frame with `name` and `error` columns, such as `targets::tar_meta()`
#' output. Rows without an error count as built targets. May be `NULL`.
#' @param vec_slice_ids
#' Slice identifiers to report, for example `timeslice_0`.
#' @param vec_window_slice_ids
#' Slice identifiers inside the modelled-slice window. Slices in
#' `vec_slice_ids` but not here are labelled `outside_window`. Defaults to
#' `vec_slice_ids`.
#' @param vec_excluded_slice_ids
#' Slice identifiers excluded from modelling in the profile
#' (`temporal_slices.excluded_ages`). They are labelled
#' `expected_infeasible` with reason `excluded_in_configuration`.
#' @param terminal_target_prefix
#' Optional prefix of the last target of each slice, for example
#' `"list_jsdm_variance_partition_"`. When given, a slice without errors is
#' `ok` only if `<prefix><slice_id>` was built without error; otherwise it is
#' `not_built` (reason `terminal_target_missing`). `NULL` (default) skips the
#' check.
#' @return
#' A tibble with columns `slice_id`, `age`, `status`, `reason_code`,
#' `root_target`, and `root_error`, one row per slice. `status` is one of
#' `ok`, `expected_infeasible`, `unexpected_error`, `not_built`, or
#' `outside_window`. When
#' targets shared by all slices errored, one extra row with `slice_id = NA`
#' reports their classification.
#' @details
#' The errors of each slice are the errored targets whose names end in
#' `_<slice_id>`; they are classified with
#' [classify_sjsdm_unit_pipeline_error()], whose temporal cascade rules accept
#' downstream failures only when the same slice has an expected root.
#' @seealso [classify_sjsdm_unit_pipeline_error()],
#'   [load_temporal_slice_ages()]
#' @examples
#' classify_sjsdm_timeslice_status(
#'   data_target_errors = tibble::tibble(
#'     name = "data_sample_ids_checked_timeslice_0",
#'     error = stringr::str_c(
#'       "Too few samples in this time slice to proceed. ",
#'       "Found 1 sample(s) but at least 10 are required."
#'     )
#'   ),
#'   vec_slice_ids = base::c("timeslice_0", "timeslice_500")
#' )
#' @export
classify_sjsdm_timeslice_status <- function(
    data_target_errors,
    vec_slice_ids,
    vec_window_slice_ids = vec_slice_ids,
    vec_excluded_slice_ids = base::character(),
    terminal_target_prefix = NULL) {
  assertthat::assert_that(
    base::is.null(data_target_errors) ||
      (
        base::is.data.frame(data_target_errors) &&
          base::all(
            base::c("name", "error") %in% base::names(data_target_errors)
          )
      ),
    msg = "`data_target_errors` must be NULL or have name and error columns."
  )
  assertthat::assert_that(
    base::is.character(vec_slice_ids),
    base::length(vec_slice_ids) > 0L,
    base::all(!base::is.na(vec_slice_ids)),
    base::is.character(vec_window_slice_ids),
    base::is.character(vec_excluded_slice_ids),
    msg = "Slice identifiers must be non-missing character vectors."
  )
  assertthat::assert_that(
    base::is.null(terminal_target_prefix) ||
      assertthat::is.string(terminal_target_prefix),
    msg = "`terminal_target_prefix` must be NULL or one string."
  )

  vec_built_targets <-
    if (
      base::is.null(data_target_errors)
    ) {
      base::character()
    } else {
      data_target_errors[["name"]][
        base::is.na(data_target_errors[["error"]]) |
          !base::nzchar(data_target_errors[["error"]])
      ]
    }

  data_errors <-
    if (
      base::is.null(data_target_errors)
    ) {
      tibble::tibble(name = base::character(), error = base::character())
    } else {
      data_target_errors |>
        dplyr::select("name", "error") |>
        dplyr::filter(
          !base::is.na(.data[["error"]]),
          base::nzchar(.data[["error"]])
        )
    }

  data_slices <-
    base::unique(vec_slice_ids) |>
    purrr::map(
      .f = ~ {
        slice_id <- .x

        if (
          !slice_id %in% vec_window_slice_ids
        ) {
          return(
            tibble::tibble(
              slice_id = slice_id,
              status = "outside_window",
              reason_code = "outside_modelled_window",
              root_target = NA_character_,
              root_error = NA_character_
            )
          )
        }

        if (
          slice_id %in% vec_excluded_slice_ids
        ) {
          return(
            tibble::tibble(
              slice_id = slice_id,
              status = "expected_infeasible",
              reason_code = "excluded_in_configuration",
              root_target = NA_character_,
              root_error = NA_character_
            )
          )
        }

        data_slice_errors <-
          data_errors |>
          dplyr::filter(
            stringr::str_detect(
              .data[["name"]],
              stringr::str_c("_", slice_id, "$")
            )
          )

        target_terminal <-
          stringr::str_c(terminal_target_prefix, slice_id)

        if (
          base::nrow(data_slice_errors) == 0L &&
            !base::is.null(terminal_target_prefix) &&
            !target_terminal %in% vec_built_targets
        ) {
          return(
            tibble::tibble(
              slice_id = slice_id,
              status = "not_built",
              reason_code = "terminal_target_missing",
              root_target = target_terminal,
              root_error = NA_character_
            )
          )
        }

        if (
          base::nrow(data_slice_errors) == 0L
        ) {
          return(
            tibble::tibble(
              slice_id = slice_id,
              status = "ok",
              reason_code = NA_character_,
              root_target = NA_character_,
              root_error = NA_character_
            )
          )
        }

        list_classification <-
          classify_sjsdm_unit_pipeline_error(
            data_target_errors = data_slice_errors
          )

        tibble::tibble(
          slice_id = slice_id,
          status = list_classification[["status"]],
          reason_code = base::as.character(
            list_classification[["reason_code"]]
          ),
          root_target = base::as.character(
            list_classification[["root_target"]]
          ),
          root_error = base::as.character(list_classification[["root_error"]])
        )
      }
    ) |>
    purrr::list_rbind()

  data_shared_errors <-
    data_errors |>
    dplyr::filter(
      !stringr::str_detect(.data[["name"]], "_timeslice_[0-9]+$")
    )

  data_shared <-
    if (
      base::nrow(data_shared_errors) > 0L
    ) {
      list_classification_shared <-
        classify_sjsdm_unit_pipeline_error(
          data_target_errors = data_shared_errors
        )
      tibble::tibble(
        slice_id = NA_character_,
        status = list_classification_shared[["status"]],
        reason_code = base::as.character(
          list_classification_shared[["reason_code"]]
        ),
        root_target = base::as.character(
          list_classification_shared[["root_target"]]
        ),
        root_error = base::as.character(
          list_classification_shared[["root_error"]]
        )
      )
    } else {
      NULL
    }

  res <-
    dplyr::bind_rows(data_slices, data_shared) |>
    dplyr::mutate(
      age = stringr::str_extract(.data[["slice_id"]], "[0-9]+$") |>
        base::as.numeric(),
      .after = "slice_id"
    )

  return(res)
}
