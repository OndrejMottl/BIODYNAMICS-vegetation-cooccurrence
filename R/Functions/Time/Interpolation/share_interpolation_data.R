#' @title Share Interpolation Data
#' @description
#' Stores an interpolation input data frame in shared memory using
#' [mori::share()] so local worker processes can read it without each
#' retaining a separate private copy.
#' @param data
#' A data frame to share across local worker processes.
#' @return
#' A data frame-like shared-memory object created by [mori::share()].
#' @details
#' The returned object must be treated as read-only. Mutating it in a
#' worker can force R to create private copies and remove the memory
#' benefit.
#' @examples
#' data_example <- tibble::tibble(dataset_name = "core_a")
#' data_shared <- share_interpolation_data(data = data_example)
#' @seealso [mori::share()]
#' @export
share_interpolation_data <- function(data) {
  assertthat::assert_that(
    base::is.data.frame(data),
    msg = "'data' must be a data frame"
  )

  if (
    !base::requireNamespace("mori", quietly = TRUE)
  ) {
    base::stop(
      "Package 'mori' is required to share interpolation data.",
      call. = FALSE
    )
  }

  res_data <-
    mori::share(data)

  base::return(res_data)
}
