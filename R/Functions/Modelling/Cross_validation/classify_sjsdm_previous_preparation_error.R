#' @title Classify a Previous sjSDM Preparation Error
#' @description
#' Recovers an expected preparation diagnosis from target metadata without
#' allowing stale downstream model errors to contaminate the classification.
#' @param data_target_errors
#' Target metadata containing `name` and `error`.
#' @param data_new_errors
#' Optional target errors refreshed by the current run. Dependency-only cache
#' cascades defer to a registered expected root in `data_target_errors`.
#' @param classify_error_function
#' Injectable target-error classifier.
#' @return
#' A preparation-error classification list.
#' @export
classify_sjsdm_previous_preparation_error <- function(
    data_target_errors = NULL,
    data_new_errors = NULL,
    classify_error_function = classify_sjsdm_unit_pipeline_error) {
  assertthat::assert_that(
    base::is.data.frame(data_target_errors),
    base::all(
      base::c("name", "error") %in%
        base::colnames(data_target_errors)
    ),
    base::is.null(data_new_errors) ||
      (
        base::is.data.frame(data_new_errors) &&
          base::all(
            base::c("name", "error") %in%
              base::colnames(data_new_errors)
          )
      ),
    base::is.function(classify_error_function),
    msg = "Previous target errors and their classifier are required."
  )

  vec_expected <-
    base::seq_len(base::nrow(data_target_errors)) |>
    purrr::map_lgl(
      .f = function(index_error) {
        classification <-
          classify_error_function(
            data_target_errors[index_error, , drop = FALSE]
          )
        base::identical(
          classification[["status"]],
          "expected_infeasible"
        )
      }
    )
  data_to_classify <-
    if (
      base::any(vec_expected)
    ) {
      data_target_errors[vec_expected, , drop = FALSE]
    } else {
      data_target_errors
    }

  list_previous_classification <-
    classify_error_function(data_to_classify)
  if (
    base::is.null(data_new_errors) ||
      base::nrow(data_new_errors) == 0L
  ) {
    return(list_previous_classification)
  }

  flag_dependency_cascade <-
    stringr::str_detect(
      data_new_errors[["error"]],
      "(?:no package called|package) ['\"]qs['\"]"
    ) |
    stringr::str_starts(
      data_new_errors[["error"]],
      "could not load dependency "
    ) |
    stringr::str_detect(
      data_new_errors[["error"]],
      "^object ['\"].*['\"] not found$"
    ) |
    stringr::str_detect(
      data_new_errors[["error"]],
      "^cannot branch over empty target"
    )
  if (
    base::all(flag_dependency_cascade) &&
      base::identical(
        list_previous_classification[["status"]],
        "expected_infeasible"
      )
  ) {
    return(list_previous_classification)
  }

  return(classify_error_function(data_new_errors))
}
