#' @title Count Successful Targets in Store Metadata
#' @description
#' Counts targets matching a regex pattern whose metadata do not report an
#' error.
#' @param store_path
#' Character scalar. Path to the targets store.
#' @param target_pattern
#' Character scalar. Regex used to select target names.
#' @param data_meta
#' Optional tibble with `name` and `error` columns. When `NULL`, metadata
#' are read with [read_target_meta_or_empty()].
#' @return
#' Integer scalar count of successful matching targets.
#' @examples
#' count_successful_targets(
#'   store_path = "Data/targets/paleo_temporal_europe/pipeline_paleo_temporal",
#'   target_pattern = "^model_evaluation_"
#' )
#' @export
count_successful_targets <- function(
    store_path,
    target_pattern,
    data_meta = NULL) {
  assertthat::assert_that(
    base::is.character(store_path),
    base::length(store_path) == 1L,
    base::nchar(store_path) > 0L,
    msg = "'store_path' must be a single non-empty character value."
  )

  assertthat::assert_that(
    base::is.character(target_pattern),
    base::length(target_pattern) == 1L,
    base::nchar(target_pattern) > 0L,
    msg = "'target_pattern' must be a single non-empty character value."
  )

  if (
    base::is.null(data_meta)
  ) {
    data_meta <-
      read_target_meta_or_empty(store_path = store_path)
  }

  assertthat::assert_that(
    base::all(base::c("name", "error") %in% base::colnames(data_meta)),
    msg = "'data_meta' must contain columns 'name' and 'error'."
  )

  res_count <-
    data_meta |>
    dplyr::filter(
      stringr::str_detect(.data$name, target_pattern),
      base::is.na(.data$error)
    ) |>
    base::nrow() |>
    base::as.integer()

  return(res_count)
}
