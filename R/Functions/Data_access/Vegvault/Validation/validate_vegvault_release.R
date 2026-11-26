#' @title Validate That a VegVault File Holds the Recorded Release
#' @description
#' Re-reads the release record of a VegVault SQLite file and stops with an
#' error unless it equals the record the pipeline built from the same file
#' (the `config_vegvault_release` target).
#' @param path_to_vegvault
#' A character string with the path to the VegVault SQLite database.
#' @param data_vegvault_release
#' A one-row data frame with character columns `vegvault_version`,
#' `git_commit` and `manifest_sha256`, as returned by
#' [load_vegvault_database_version()].
#' @return
#' `TRUE`, invisibly, when the file holds the recorded release.
#' @details
#' The release record is read with [load_vegvault_database_version()],
#' which opens the file read-only and stops when the version differs from
#' `vegvault_version`. The three fields are then compared one by one, with
#' `NA` equal only to `NA`. A difference in `git_commit` or
#' `manifest_sha256` means the file was rebuilt or replaced under the same
#' version, and stops with an error of class
#' `biodynamics_vegvault_release_mismatch`.
#'
#' Functions that open VegVault for a pipeline target call this check
#' before any query, so a target never reads a file other than the one its
#' `config_vegvault_release` dependency describes. The check does not rely
#' on vaultkeepr: vaultkeepr 0.2.0 records the version only on the object
#' returned by `vaultkeepr::open_vault()`, and the later steps of a query
#' drop it.
#' @seealso [load_vegvault_database_version()], [build_vegvault_plan()]
#' @examples
#' \dontrun{
#' data_vegvault_release <-
#'   load_vegvault_database_version(vegvault_version = "2.0.0")
#'
#' validate_vegvault_release(
#'   path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
#'   data_vegvault_release = data_vegvault_release
#' )
#' }
#' @export
validate_vegvault_release <- function(
    path_to_vegvault,
    data_vegvault_release) {
  vec_release_fields <-
    base::c("vegvault_version", "git_commit", "manifest_sha256")

  assertthat::assert_that(
    base::is.data.frame(data_vegvault_release),
    base::nrow(data_vegvault_release) == 1L,
    base::all(vec_release_fields %in% base::names(data_vegvault_release)),
    msg = stringr::str_c(
      "'data_vegvault_release' must be a one-row data frame with columns ",
      "'vegvault_version', 'git_commit' and 'manifest_sha256'."
    )
  )

  sel_vegvault_version <-
    data_vegvault_release |>
    dplyr::pull(vegvault_version)

  assertthat::assert_that(
    base::is.character(sel_vegvault_version),
    !base::is.na(sel_vegvault_version),
    msg = stringr::str_c(
      "'data_vegvault_release' must hold a non-missing character ",
      "'vegvault_version'."
    )
  )

  data_release_in_file <-
    load_vegvault_database_version(
      path_to_vegvault = path_to_vegvault,
      vegvault_version = sel_vegvault_version
    )

  # NA equals only NA: a field present on one side and missing on the
  #   other is a different release
  vec_fields_differing <-
    vec_release_fields |>
    purrr::discard(
      .p = ~ base::identical(
        base::as.character(dplyr::pull(data_vegvault_release, .x)),
        base::as.character(dplyr::pull(data_release_in_file, .x))
      )
    )

  if (
    base::length(vec_fields_differing) > 0L
  ) {
    cli::cli_abort(
      c(
        stringr::str_c(
          "The VegVault file is not the release recorded in ",
          "{.field config_vegvault_release}."
        ),
        "x" = "Differing field{?s}: {.field {vec_fields_differing}}.",
        "i" = "File: {.file {path_to_vegvault}}",
        "i" = stringr::str_c(
          "Rebuild {.field config_vegvault_release}, or restore the ",
          "recorded file."
        )
      ),
      class = "biodynamics_vegvault_release_mismatch"
    )
  }

  return(base::invisible(TRUE))
}
