#' @title Share Interpolation Data
#' @description
#' Stores an interpolation input data frame in shared memory using
#' [mori::share()] so local worker processes can read it without each
#' retaining a separate private copy.
#' @param data
#' A data frame to share across local worker processes.
#' @param registry_key
#' Optional non-empty key used to retain the shared object in a
#' process-local registry. Reusing a key replaces the previous region.
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
share_interpolation_data <- function(data, registry_key = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data),
    msg = "'data' must be a data frame"
  )
  assertthat::assert_that(
    base::is.null(registry_key) ||
      (
        base::is.character(registry_key) &&
          base::length(registry_key) == 1L &&
          !base::is.na(registry_key) &&
          base::nzchar(registry_key)
      ),
    msg = "'registry_key' must be NULL or one non-empty string"
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

  registry <-
    base::getOption(
      "biodynamics.interpolation_shared_registry"
    )

  if (
    !base::is.environment(registry)
  ) {
    registry <-
      base::new.env(parent = base::emptyenv())

    base::options(
      biodynamics.interpolation_shared_registry = registry
    )
  }

  selected_registry_key <-
    if (
      base::is.null(registry_key)
    ) {
      mori::shared_name(res_data)
    } else {
      registry_key
    }

  base::assign(
    x = selected_registry_key,
    value = res_data,
    envir = registry
  )

  base::return(res_data)
}
