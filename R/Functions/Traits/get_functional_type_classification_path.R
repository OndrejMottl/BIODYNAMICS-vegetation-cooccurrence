#' @title Get Functional-Type Classification Path
#' @description
#' Finds the latest dated functional-type classification `.qs` file
#' path for one continent and optional source prefix.
#' @param continent_id
#' A single non-empty character string identifying the continent.
#' @param data_source_prefix
#' Optional single non-empty character string identifying a
#' source-specific FT classification family, such as `"modern"`.
#' Use `NULL` for historical paleo/global classification files.
#' @param path_processed
#' A single character string giving the directory that contains the
#' FT classification `.qs` files. Defaults to
#' `here::here("Data/Processed/Traits")`.
#' @return
#' A single character string with the full path to the latest matching
#' `.qs` file.
#' @export
get_functional_type_classification_path <- function(
    continent_id,
    data_source_prefix = NULL,
    path_processed = here::here("Data/Processed/Traits")) {
  assertthat::assert_that(
    base::is.character(continent_id) &&
      base::length(continent_id) == 1L &&
      base::nchar(continent_id) > 0L,
    msg = "`continent_id` must be a single non-empty string."
  )

  if (
    !base::is.null(data_source_prefix)
  ) {
    assertthat::assert_that(
      base::is.character(data_source_prefix) &&
        base::length(data_source_prefix) == 1L &&
        base::nchar(data_source_prefix) > 0L,
      msg = "`data_source_prefix` must be NULL or a non-empty string."
    )
  }

  assertthat::assert_that(
    base::is.character(path_processed) &&
      base::length(path_processed) == 1L &&
      base::dir.exists(path_processed),
    msg = "`path_processed` must be a single existing directory."
  )

  file_source_prefix <-
    if (
      base::is.null(data_source_prefix)
    ) {
      ""
    } else {
      stringr::str_glue("{data_source_prefix}_")
    }

  file_name_base <-
    stringr::str_glue(
      "data_ft_classification_{file_source_prefix}{continent_id}"
    )

  res <-
    tryCatch(
      expr = get_latest_dated_file_path(
        file_name_base = file_name_base,
        path_directory = path_processed,
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
          base::is.null(data_source_prefix)
        ) {
          cli::cli_abort(
            stringr::str_glue(
              "No FT classification file found for continent ",
              "'{continent_id}' in '{path_processed}'."
            )
          )
        }

        cli::cli_abort(
          stringr::str_glue(
            "No FT classification file found for ",
            "'{file_source_prefix}{continent_id}' in ",
            "'{path_processed}'."
          )
        )
      }
    )

  return(res)
}
