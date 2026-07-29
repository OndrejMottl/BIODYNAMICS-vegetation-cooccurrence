#' @title Build Shared Interpolation Data
#' @description
#' Builds a shared-memory interpolation data object using
#' [mori::share()] so local worker processes can read it without each
#' retaining a separate private copy.
#' @param data_interpolation
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
#' data_interpolation <-
#'   tibble::tibble(dataset_name = "core_a")
#'
#' data_shared <-
#'   build_shared_interpolation_data(
#'     data_interpolation = data_interpolation
#'   )
#' @seealso [mori::share()]
#' @export
build_shared_interpolation_data <- function(
    data_interpolation = NULL,
    registry_key = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_interpolation),
    msg = "data_interpolation must be a data frame"
  )

  assertthat::assert_that(
    base::is.null(registry_key) ||
      (
        base::is.character(registry_key) &&
          base::length(registry_key) == 1L &&
          !base::is.na(registry_key) &&
          base::nzchar(registry_key)
      ),
    msg = "registry_key must be NULL or one non-empty string"
  )

  if (
    !base::requireNamespace("mori", quietly = TRUE)
  ) {
    base::stop(
      "Package 'mori' is required to share interpolation data.",
      call. = FALSE
    )
  }

  res_shared_data <-
    mori::share(data_interpolation)

  environment_shared_registry <-
    base::getOption(
      "biodynamics.interpolation_shared_registry"
    )

  if (
    !base::is.environment(environment_shared_registry)
  ) {
    environment_shared_registry <-
      base::new.env(parent = base::emptyenv())

    base::options(
      biodynamics.interpolation_shared_registry =
        environment_shared_registry
    )
  }

  registry_key_selected <-
    if (
      base::is.null(registry_key)
    ) {
      mori::shared_name(res_shared_data)
    } else {
      registry_key
    }

  base::assign(
    x = registry_key_selected,
    value = res_shared_data,
    envir = environment_shared_registry
  )

  return(res_shared_data)
}
