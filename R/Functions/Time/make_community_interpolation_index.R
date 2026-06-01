#' @title Make Community Interpolation Index
#' @description
#' Creates small per-dataset branch metadata for paleo community
#' interpolation.
#' @param data
#' A data frame containing a `dataset_name` column.
#' @return
#' A list of branch metadata objects. Each object contains
#' `dataset_name` and `flag_empty` elements.
#' @details
#' Dynamic `{targets}` branches should pass these small metadata objects
#' instead of nested community data frames. Worker branches can then
#' filter shared read-only inputs by `dataset_name`.
#' @examples
#' data_example <- tibble::tibble(dataset_name = c("core_b", "core_a"))
#' make_community_interpolation_index(data = data_example)
#' @seealso [interpolate_community_dataset_from_shared_inputs()]
#' @export
make_community_interpolation_index <- function(data) {
  assertthat::assert_that(
    base::is.data.frame(data),
    msg = "'data' must be a data frame"
  )

  assertthat::assert_that(
    "dataset_name" %in% base::colnames(data),
    msg = "'data' must contain a 'dataset_name' column"
  )

  if (
    base::nrow(data) == 0L
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

  res_index <-
    data |>
    dplyr::distinct(dataset_name) |>
    dplyr::arrange(dataset_name) |>
    dplyr::pull(dataset_name) |>
    purrr::map(
      .f = ~ base::list(
        dataset_name = .x,
        flag_empty = FALSE
      )
    )

  base::return(res_index)
}
