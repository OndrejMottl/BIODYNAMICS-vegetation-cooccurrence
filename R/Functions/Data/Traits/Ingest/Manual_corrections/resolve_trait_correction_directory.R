#' @title Resolve Trait Correction Directory
#' @description
#' Returns the folder of reviewed trait-correction files that belongs to one
#' VegVault release, for example `VegVault_2_0_0/` for VegVault 2.0.0.
#' @param vegvault_version
#' A single character string with the VegVault release in the form
#' `<major>.<minor>.<patch>` (the `vegvault_version` of the
#' `config_vegvault_release` target).
#' @param dir_trait_corrections
#' A single character string with the folder that holds one subfolder per
#' VegVault release (default: `here::here("Data/Input/Trait_corrections")`).
#' @return
#' A character string with the path of the release folder.
#' @details
#' The folder name is `VegVault_` followed by the version with its dots
#' replaced by underscores. The function stops with an error of class
#' `biodynamics_trait_correction_directory_missing`, naming the missing
#' folder, when the release has none. Decisions reviewed for one release are
#' therefore never applied to another by accident.
#' @seealso [load_trait_source_scale_rules()],
#'   [load_trait_review_decisions()]
#' @export
resolve_trait_correction_directory <- function(
    vegvault_version,
    dir_trait_corrections = here::here("Data/Input/Trait_corrections")) {
  assertthat::assert_that(
    base::is.character(vegvault_version) &&
      base::length(vegvault_version) == 1L &&
      !base::is.na(vegvault_version) &&
      stringr::str_detect(
        vegvault_version,
        "^[0-9]+[.][0-9]+[.][0-9]+$"
      ),
    msg = stringr::str_c(
      "'vegvault_version' must be a single version string of the form ",
      "'<major>.<minor>.<patch>'."
    )
  )
  assertthat::assert_that(
    base::is.character(dir_trait_corrections) &&
      base::length(dir_trait_corrections) == 1L &&
      !base::is.na(dir_trait_corrections) &&
      base::dir.exists(dir_trait_corrections),
    msg = "'dir_trait_corrections' must be a single existing folder."
  )

  name_release_directory <-
    stringr::str_c(
      "VegVault_",
      stringr::str_replace_all(vegvault_version, "[.]", "_")
    )

  dir_release <-
    base::file.path(dir_trait_corrections, name_release_directory)

  if (
    !base::dir.exists(dir_release)
  ) {
    cli::cli_abort(
      c(
        "VegVault {vegvault_version} has no trait-correction folder.",
        "x" = "Folder not found: {.path {dir_release}}.",
        "i" = stringr::str_c(
          "Create it with the reviewed correction files for this release; ",
          "decisions of another release do not carry over."
        )
      ),
      class = "biodynamics_trait_correction_directory_missing"
    )
  }

  return(dir_release)
}
