#' @title Build a Shared Interpolation Descriptor
#' @description
#' Shares interpolation data with [mori::share()] and returns a stable
#' descriptor instead of persisting a process-local memory handle.
#' @param data_interpolation
#' A data frame to share across local worker processes.
#' @param registry_key
#' Optional non-empty key used to retain the shared object in a
#' process-local registry. Reusing a key replaces the previous region.
#' @return
#' A list containing `registry_key` and deterministic `source_hash`.
#' @details
#' The live memory name is written to the store-scoped directory in
#' `BIODYNAMICS_INTERPOLATION_SHARED_REGISTRY`. Workers must treat the
#' mapped data as read-only.
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

  path_shared_registry <-
    base::Sys.getenv(
      "BIODYNAMICS_INTERPOLATION_SHARED_REGISTRY",
      unset = ""
    )
  if (
    !base::nzchar(path_shared_registry)
  ) {
    cli::cli_abort(
      base::c(
        "The interpolation shared-memory registry is not configured.",
        "i" = "Run this target through run_pipeline()."
      )
    )
  }
  base::dir.create(
    path = path_shared_registry,
    recursive = TRUE,
    showWarnings = FALSE
  )
  source_hash <-
    digest::digest(
      object = data_interpolation,
      algo = "xxhash64",
      serialize = TRUE
    )

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
      stringr::str_glue("interpolation_{source_hash}")
    } else {
      registry_key
    }

  base::assign(
    x = registry_key_selected,
    value = res_shared_data,
    envir = environment_shared_registry
  )

  path_shared_name <-
    base::file.path(
      path_shared_registry,
      stringr::str_glue("{registry_key_selected}.txt")
    )
  base::writeLines(
    text = mori::shared_name(res_shared_data),
    con = path_shared_name,
    useBytes = TRUE
  )

  res_shared_descriptor <-
    base::list(
      registry_key = registry_key_selected,
      source_hash = source_hash
    )

  return(res_shared_descriptor)
}
