#' @title Build Community Interpolation Index
#' @description
#' Builds small per-dataset branch metadata for paleo community interpolation.
#' @param data_community
#' A data frame containing a `dataset_name` column.
#' @return
#' A list of branch metadata objects. Each object contains
#' `dataset_name` and `flag_empty` elements.
#' @details
#' Dynamic `{targets}` branches should pass these small metadata objects
#' instead of nested community data frames. Worker branches can then
#' filter shared read-only inputs by `dataset_name`.
#' @examples
#' data_community <-
#'   tibble::tibble(
#'     dataset_name = base::c("core_b", "core_a")
#'   )
#'
#' build_community_interpolation_index(
#'   data_community = data_community
#' )
#' @seealso [interpolate_community_dataset_from_shared_inputs()]
#' @export
build_community_interpolation_index <- function(
    data_community = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_community),
    msg = "data_community must be a data frame"
  )

  assertthat::assert_that(
    "dataset_name" %in% base::colnames(data_community),
    msg = "data_community must contain a `dataset_name` column"
  )

  if (
    base::nrow(data_community) == 0L
  ) {
    return(
      base::list(
        base::list(
          dataset_name = NA_character_,
          flag_empty = TRUE
        )
      )
    )
  }

  res_interpolation_index <-
    data_community |>
    dplyr::distinct(.data[["dataset_name"]]) |>
    dplyr::arrange(.data[["dataset_name"]]) |>
    dplyr::pull("dataset_name") |>
    purrr::map(
      .f = ~ base::list(
        dataset_name = .x,
        flag_empty = FALSE
      )
    )

  return(res_interpolation_index)
}
