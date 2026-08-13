#' @title Check for Shared sjSDM Tuning Evidence
#' @description
#' Reads every requested native-v2 unit tuning artifact and reports whether at
#' least one contains candidate evidence. Missing, unreadable, or malformed
#' inputs fail closed.
#' @param store_paths
#' Non-empty character vector of unit targets-store paths.
#' @param target_names
#' Non-empty character vector of tuning-summary target names.
#' @param read_target_function
#' Injectable target reader. Defaults to [targets::tar_read_raw()].
#' @return
#' One logical value.
#' @examples
#' \dontrun{
#' has_sjsdm_tuning_evidence(
#'   store_paths = "Data/targets/unit/pipeline",
#'   target_names = "list_sjsdm_cv_tuning_artifact"
#' )
#' }
#' @export
has_sjsdm_tuning_evidence <- function(
    store_paths = NULL,
    target_names = NULL,
    read_target_function = targets::tar_read_raw) {
  assertthat::assert_that(
    base::is.character(store_paths),
    base::length(store_paths) > 0L,
    base::all(!base::is.na(store_paths)),
    base::all(base::nzchar(store_paths)),
    msg = "store_paths must contain non-empty store paths."
  )

  assertthat::assert_that(
    base::is.character(target_names),
    base::length(target_names) > 0L,
    base::all(!base::is.na(target_names)),
    base::all(base::nzchar(target_names)),
    msg = "target_names must contain non-empty target names."
  )

  assertthat::assert_that(
    base::is.function(read_target_function),
    msg = "read_target_function must be a function."
  )

  data_requests <-
    tidyr::crossing(
      store_path = base::unique(store_paths),
      target_name = base::unique(target_names)
    )

  list_summaries <-
    purrr::pmap(
      .l = data_requests,
      .f = function(store_path, target_name) {
        data_summary <-
          tryCatch(
            expr = read_target_function(
              name = target_name,
              store = store_path
            ),
            error = function(error_condition) {
              error_condition
            }
          )

        if (
          base::inherits(data_summary, "error")
        ) {
          cli::cli_abort(
            c(
              "Could not read every requested tuning summary.",
              "x" = stringr::str_glue(
                "{target_name} in {store_path}: ",
                "{base::conditionMessage(data_summary)}"
              )
            )
          )
        }

        validate_sjsdm_artifact_envelope(
          list_artifact = data_summary,
          expected_artifact_type = "sjsdm_cv_tuning"
        )

        data_summary <-
          data_summary[["payload"]][[
            "data_candidate_repeat_summary"
          ]]

        return(data_summary)
      }
    )

  res <-
    purrr::some(
      .x = list_summaries,
      .p = ~ base::nrow(.x) > 0L
    )

  return(res)
}
