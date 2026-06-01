#' @title Get Latest Dated File Path
#' @description
#' Finds the latest dated file for a file-name prefix.
#' @param file_name_base
#' A single non-empty character string giving the file prefix,
#' without the date suffix or extension.
#' @param path_directory
#' A single character string giving the directory to search.
#' @param file_extension
#' A single non-empty character string giving the extension without
#' a leading dot.
#' @return
#' A single character string with the full path to the latest matching
#' file.
#' @details
#' Matching files must follow the project convention
#' `<file_name_base>_YYYY-MM-DD*.<file_extension>`. ISO dates sort
#' lexicographically, so sorting matching paths selects the latest file.
#' @export
get_latest_dated_file_path <- function(
    file_name_base,
    path_directory,
    file_extension) {
  assertthat::assert_that(
    base::is.character(file_name_base) &&
      base::length(file_name_base) == 1L &&
      base::nchar(file_name_base) > 0L,
    msg = "`file_name_base` must be a single non-empty string."
  )

  assertthat::assert_that(
    base::is.character(path_directory) &&
      base::length(path_directory) == 1L &&
      base::dir.exists(path_directory),
    msg = "`path_directory` must be a single existing directory."
  )

  assertthat::assert_that(
    base::is.character(file_extension) &&
      base::length(file_extension) == 1L &&
      base::nchar(file_extension) > 0L,
    msg = "`file_extension` must be a single non-empty string."
  )

  vec_files <-
    base::list.files(
      path = path_directory,
      full.names = TRUE
    )

  vec_file_names <-
    base::basename(vec_files)

  vec_file_suffixes <-
    base::substring(
      text = vec_file_names,
      first = base::nchar(file_name_base) + 2L
    )

  idx_match <-
    base::startsWith(
      x = vec_file_names,
      prefix = base::paste0(file_name_base, "_")
    ) &
    stringr::str_detect(
      string = vec_file_suffixes,
      pattern = "^[0-9]{4}-[0-9]{2}-[0-9]{2}"
    ) &
    tools::file_ext(vec_file_names) == file_extension

  vec_files <-
    vec_files[idx_match]

  if (
    base::length(vec_files) == 0L
  ) {
    cli::cli_abort(
      message = stringr::str_glue(
        "No `{file_extension}` file found for prefix ",
        "`{file_name_base}` in `{path_directory}`."
      ),
      class = "biodynamics_error_no_latest_dated_file"
    )
  }

  res <-
    base::sort(vec_files)[base::length(vec_files)]

  return(res)
}
