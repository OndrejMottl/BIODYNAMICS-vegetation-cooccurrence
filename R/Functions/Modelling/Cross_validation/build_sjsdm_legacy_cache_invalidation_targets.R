#' @title Collect Unreadable Legacy sjSDM Cache Targets
#' @description
#' Collects prepared endpoints, errored targets, and named dependencies that
#' participate in a legacy `qs` cache-read failure.
#' @param data_endpoints
#' Prepared-endpoint diagnostics containing `target_name`, `endpoint_status`,
#' and `error_message`.
#' @param data_target_errors
#' Target metadata containing `name` and `error`.
#' @return
#' A unique character vector of targets to invalidate before retrying.
#' @export
build_sjsdm_legacy_cache_invalidation_targets <- function(
    data_endpoints = NULL,
    data_target_errors = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_endpoints),
    base::all(
      base::c(
        "target_name",
        "endpoint_status",
        "error_message"
      ) %in% base::colnames(data_endpoints)
    ),
    base::is.null(data_target_errors) ||
      (
        base::is.data.frame(data_target_errors) &&
          base::all(
            base::c("name", "error") %in%
              base::colnames(data_target_errors)
          )
      ),
    msg = "Legacy-cache diagnostics have incomplete columns."
  )

  data_cache_endpoints <-
    data_endpoints |>
    dplyr::filter(
      .data[["endpoint_status"]] ==
        "cache_format_incompatible"
    )
  data_cache_errors <-
    if (
      base::is.null(data_target_errors)
    ) {
      tibble::tibble(
        name = base::character(),
        error = base::character()
      )
    } else {
      data_target_errors |>
        dplyr::filter(
          !base::is.na(.data[["error"]]),
          stringr::str_detect(
            .data[["error"]],
            "(?:no package called|package) ['\"]qs['\"]"
          )
        )
    }
  vec_messages <-
    base::c(
      data_cache_endpoints[["error_message"]],
      data_cache_errors[["error"]]
    )
  mat_dependencies <-
    stringr::str_match(
      vec_messages,
      "could not load dependency ['\"]?([A-Za-z0-9_]+)"
    )
  vec_dependencies <-
    mat_dependencies[, 2L] |>
    stats::na.omit() |>
    base::as.character()

  return(
    base::unique(
      base::c(
        data_cache_endpoints[["target_name"]],
        data_cache_errors[["name"]],
        vec_dependencies
      )
    )
  )
}
