#' @title Resolve Functional-Type Classification Path
#' @description
#' Finds the latest dated functional-type classification `.qs` file
#' path for one continent and optional source prefix.
#' @param continent_id
#' A single non-empty character string identifying the continent.
#' @param classification_source_prefix
#' Optional single non-empty character string identifying a
#' source-specific FT classification family, such as `"modern"`.
#' Use `NULL` for historical paleo/global classification files.
#' @param path_classification_directory
#' A single character string giving the directory that contains the
#' FT classification `.qs` files. Defaults to
#' `here::here("Data/Processed/Traits")`.
#' @return
#' A single character string with the full path to the latest matching
#' `.qs` file.
#' @export
resolve_functional_type_classification_path <- function(
    continent_id,
    classification_source_prefix = NULL,
    path_classification_directory = here::here("Data/Processed/Traits")) {
  assertthat::assert_that(
    base::is.character(continent_id) &&
      base::length(continent_id) == 1L &&
      base::nchar(continent_id) > 0L,
    msg = "`continent_id` must be a single non-empty string."
  )

  if (
    !base::is.null(classification_source_prefix)
  ) {
    assertthat::assert_that(
      base::is.character(classification_source_prefix) &&
        base::length(classification_source_prefix) == 1L &&
        base::nchar(classification_source_prefix) > 0L,
      msg = base::paste0(
        "`classification_source_prefix` must be NULL or a non-empty string."
      )
    )
  }

  assertthat::assert_that(
    base::is.character(path_classification_directory) &&
      base::length(path_classification_directory) == 1L &&
      base::dir.exists(path_classification_directory),
    msg = base::paste0(
      "`path_classification_directory` must be a single existing directory."
    )
  )

  classification_file_prefix <-
    if (
      base::is.null(classification_source_prefix)
    ) {
      ""
    } else {
      stringr::str_glue("{classification_source_prefix}_")
    }

  classification_file_stem <-
    stringr::str_glue(
      "data_ft_classification_{classification_file_prefix}{continent_id}"
    )

  path_classification_file <-
    base::tryCatch(
      expr = get_latest_dated_file_path(
        file_name_base = classification_file_stem,
        path_directory = path_classification_directory,
        file_extension = "qs"
      ),
      error = function(condition) {
        if (
          !base::inherits(
            x = condition,
            what = "biodynamics_error_no_latest_dated_file"
          )
        ) {
          base::stop(condition)
        }

        if (
          base::is.null(classification_source_prefix)
        ) {
          cli::cli_abort(
            stringr::str_glue(
              "No FT classification file found for continent ",
              "'{continent_id}' in '{path_classification_directory}'."
            )
          )
        }

        cli::cli_abort(
          stringr::str_glue(
            "No FT classification file found for ",
            "'{classification_file_prefix}{continent_id}' in ",
            "'{path_classification_directory}'."
          )
        )
      }
    )

  return(path_classification_file)
}
