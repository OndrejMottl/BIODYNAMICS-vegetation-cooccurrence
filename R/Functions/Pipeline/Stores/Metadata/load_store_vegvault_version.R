#' @title Load the VegVault Version a Targets Store Was Built From
#' @description
#' Reads the `config_vegvault_release` target of one targets store and
#' returns the VegVault version it records.
#' @param store_path
#' A single character string with the path to the targets store.
#' @param data_meta
#' Metadata of the store with at least the columns `name` and `error`, as
#' returned by [targets::tar_meta()], or `NULL` when it could not be read.
#' @param read_target_fn
#' Function used to load one target. Defaults to [targets::tar_read_raw()].
#' @return
#' A single character string, the VegVault version of the store, for
#' example `"2.0.0"`. `NA_character_` when the store has no successful
#' `config_vegvault_release` target.
#' @details
#' Stores built before the release record was added to the pipelines have
#' no `config_vegvault_release` target, so published tables show `NA` for
#' them rather than a guessed version. The target is read only when its
#' metadata records no error.
#' @seealso [load_vegvault_database_version()], [has_target_succeeded()]
#' @examples
#' \dontrun{
#' store_path <-
#'   "Data/targets/paleo_temporal_europe/pipeline_paleo_temporal"
#'
#' load_store_vegvault_version(
#'   store_path = store_path,
#'   data_meta = targets::tar_meta(store = store_path)
#' )
#' }
#' @export
load_store_vegvault_version <- function(
    store_path,
    data_meta,
    read_target_fn = targets::tar_read_raw) {
  assertthat::assert_that(
    assertthat::is.string(store_path),
    msg = "'store_path' must be a single character string."
  )

  assertthat::assert_that(
    base::is.function(read_target_fn),
    msg = "'read_target_fn' must be a function."
  )

  flag_release_built <-
    has_target_succeeded(
      data_meta = data_meta,
      target_name = "config_vegvault_release"
    )

  if (
    isFALSE(flag_release_built)
  ) {
    return(NA_character_)
  }

  data_vegvault_release <-
    read_target_fn(
      name = "config_vegvault_release",
      store = store_path
    )

  if (
    !base::is.data.frame(data_vegvault_release) ||
      !"vegvault_version" %in% base::names(data_vegvault_release) ||
      base::nrow(data_vegvault_release) != 1L
  ) {
    cli::cli_abort(
      c(
        stringr::str_c(
          "{.field config_vegvault_release} is not a one-row release ",
          "record with a {.field vegvault_version} column."
        ),
        "i" = "Store: {.file {store_path}}"
      )
    )
  }

  res_vegvault_version <-
    data_vegvault_release |>
    dplyr::pull(vegvault_version) |>
    base::as.character()

  return(res_vegvault_version)
}
