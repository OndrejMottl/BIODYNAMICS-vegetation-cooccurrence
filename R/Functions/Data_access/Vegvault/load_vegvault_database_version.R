#' @title Load the VegVault Database Version Record
#' @description
#' Reads the current release record from the `version_control` table of a
#' VegVault SQLite file, opened read-only, and stops with an error unless
#' its version equals the configured VegVault version.
#' @param path_to_vegvault
#' A character string with the path to the VegVault SQLite database
#' (default: `here::here("Data/Input/VegVault.sqlite")`).
#' @param vegvault_version
#' A single non-empty character string, the VegVault version the project
#' is configured for (`vegvault_data.vegvault_version` in `config.yml`),
#' for example `"2.0.0"`.
#' @return
#' A one-row tibble with three character columns:
#' \itemize{
#'   \item `vegvault_version`: the version of the current release, equal
#'     to `vegvault_version`.
#'   \item `git_commit`: the VegVault commit the file was built from.
#'   \item `manifest_sha256`: the SHA-256 of the build manifest.
#' }
#' `git_commit` and `manifest_sha256` are `NA` when the table has no such
#' column (VegVault before 2.0.0) or no value in the current row.
#' @details
#' The current release is the row with the highest `id` among the rows
#' that have a version, as in `vaultkeepr::open_vault()`. The id decides,
#' not the text order of the version, in which `"2.10.0"` comes before
#' `"2.9.0"`.
#'
#' Unlike vaultkeepr, which reads such a file as VegVault 1.0.0, a file
#' without a `version_control` table or without any version row stops
#' with an error: the release record is provenance and must come from the
#' file itself.
#'
#' A version that differs from `vegvault_version` stops with an error of
#' class `biodynamics_vegvault_version_mismatch`.
#'
#' The connection is opened with `RSQLite::SQLITE_RO`, so the file is
#' never written. The record holds no path and no time stamp, so it is the
#' same in every checkout of the same file. An always-cued target built
#' from it changes only when the database release changes.
#' @seealso [build_vegvault_plan()]
#' @examples
#' \dontrun{
#' load_vegvault_database_version(
#'   path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
#'   vegvault_version = "2.0.0"
#' )
#' }
#' @export
load_vegvault_database_version <- function(
    path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
    vegvault_version) {
  assertthat::assert_that(
    base::is.character(path_to_vegvault),
    base::length(path_to_vegvault) == 1L,
    msg = "'path_to_vegvault' must be a single character string."
  )

  assertthat::assert_that(
    base::file.exists(path_to_vegvault),
    msg = stringr::str_glue(
      "'path_to_vegvault' does not exist: {path_to_vegvault}"
    )
  )

  assertthat::assert_that(
    base::is.character(vegvault_version),
    base::length(vegvault_version) == 1L,
    !base::is.na(vegvault_version),
    base::nzchar(vegvault_version),
    msg = "'vegvault_version' must be a single non-empty character string."
  )

  # Read-only, so that no query can change the database file
  connection_vault <-
    DBI::dbConnect(
      drv = RSQLite::SQLite(),
      dbname = path_to_vegvault,
      flags = RSQLite::SQLITE_RO
    )

  base::on.exit(
    DBI::dbDisconnect(connection_vault),
    add = TRUE
  )

  if (
    !"version_control" %in% DBI::dbListTables(connection_vault)
  ) {
    cli::cli_abort(
      c(
        "The VegVault file has no {.field version_control} table.",
        "i" = "File: {.file {path_to_vegvault}}"
      )
    )
  }

  vec_version_fields <-
    DBI::dbListFields(
      conn = connection_vault,
      name = "version_control"
    )

  # The build fields exist from VegVault 2.0.0 on; older files read as NA
  vec_build_fields <-
    base::c("git_commit", "manifest_sha256")

  vec_select_build_fields <-
    dplyr::if_else(
      condition = vec_build_fields %in% vec_version_fields,
      true = stringr::str_c(
        "CAST(", vec_build_fields, " AS TEXT) AS ", vec_build_fields
      ),
      false = stringr::str_c("NULL AS ", vec_build_fields)
    )

  # The id decides, not the text order of the version, in which "2.10.0"
  #   comes before "2.9.0"
  sql_current_release <-
    stringr::str_c(
      "SELECT version, ",
      stringr::str_c(vec_select_build_fields, collapse = ", "),
      " FROM version_control WHERE version IS NOT NULL",
      " ORDER BY id DESC LIMIT 1"
    )

  data_current_release <-
    DBI::dbGetQuery(
      conn = connection_vault,
      statement = sql_current_release
    )

  if (
    base::nrow(data_current_release) == 0L
  ) {
    cli::cli_abort(
      c(
        "The {.field version_control} table has no row with a version.",
        "i" = "File: {.file {path_to_vegvault}}"
      )
    )
  }

  database_version <-
    data_current_release |>
    dplyr::pull(version) |>
    base::as.character()

  if (
    !base::identical(database_version, vegvault_version)
  ) {
    cli::cli_abort(
      c(
        stringr::str_c(
          "The VegVault file is version {.val {database_version}}, ",
          "but the configuration expects {.val {vegvault_version}}."
        ),
        "i" = "File: {.file {path_to_vegvault}}",
        "i" = stringr::str_c(
          "Replace the file or update ",
          "{.field vegvault_data.vegvault_version}."
        )
      ),
      class = "biodynamics_vegvault_version_mismatch"
    )
  }

  res_release <-
    tibble::tibble(
      vegvault_version = database_version,
      git_commit = data_current_release |>
        dplyr::pull(git_commit) |>
        base::as.character(),
      manifest_sha256 = data_current_release |>
        dplyr::pull(manifest_sha256) |>
        base::as.character()
    )

  return(res_release)
}
