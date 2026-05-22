#' @title Check Whether a Targets Target Succeeded
#' @description
#' Checks targets metadata for one target name and returns `TRUE` when
#' the target is present and has no recorded error.
#' @param data_meta
#' A targets metadata data frame with columns `name` and `error`, or
#' `NULL`. `NULL` is treated as no successful target.
#' @param target_name
#' A single non-empty character string identifying the target to check.
#' @return
#' A single logical value.
#' @examples
#' data_meta <- tibble::tibble(
#'   name = "model_evaluation_genus",
#'   error = NA_character_
#' )
#' check_target_succeeded(data_meta, "model_evaluation_genus")
#' @export
check_target_succeeded <- function(data_meta, target_name) {
  assertthat::assert_that(
    base::is.character(target_name) &&
      base::length(target_name) == 1L &&
      base::nchar(target_name) > 0L,
    msg = "`target_name` must be a single non-empty character string."
  )

  if (
    base::is.null(data_meta)
  ) {
    return(FALSE)
  }

  assertthat::assert_that(
    base::is.data.frame(data_meta),
    msg = "`data_meta` must be a data frame or NULL."
  )

  if (
    !base::all(c("name", "error") %in% base::colnames(data_meta))
  ) {
    return(FALSE)
  }

  data_target_row <-
    data_meta |>
    dplyr::filter(
      .data$name == .env$target_name
    )

  res <-
    base::nrow(data_target_row) > 0L &&
    base::any(base::is.na(data_target_row[["error"]]))

  return(res)
}
