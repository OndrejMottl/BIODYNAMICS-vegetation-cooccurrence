#' @title Get Functional-Type Classification for a Continental Unit
#' @description
#' Loads the most recent FT classification file for a given
#' continental unit from `Data/Processed/Traits/`. The file is
#' produced by `pipe_segment_trait_ft_clustering` in
#' `pipeline_traits.R` and named
#' `data_ft_classification_{continent_id}_{YYYY-MM-DD}.qs`.
#' @param continent_id
#' A single non-empty character string identifying the continental
#' unit (e.g. `"europe"`, `"america"`, `"asia"`). Must match exactly
#' with the `scale_id` used when the FT classification was saved.
#' @param path_processed
#' A single character string giving the directory that contains the
#' FT classification `.qs` files. Default:
#' `here::here("Data/Processed/Traits")`.
#' @return
#' A tibble with two columns:
#' \describe{
#'   \item{taxon_name}{Character. Taxon names resolved to finest
#'     available rank, matching the `taxon_name` column in the
#'     global trait table.}
#'   \item{functional_type}{Integer. Cluster label (1..k) from the
#'     FT clustering solution chosen for this continental unit.}
#' }
#' @details
#' The function lists all `.qs` files in `path_processed` matching
#' the pattern `data_ft_classification_{continent_id}_*.qs`,
#' selects the file with the most recent date suffix (ISO 8601:
#' YYYY-MM-DD), and reads it via `qs2::qs_read()`. If no matching
#' file is found the function aborts with an informative error.
#' @seealso [cluster_functional_types()]
#' @export
get_functional_type_classification <- function(
    continent_id,
    path_processed = here::here("Data/Processed/Traits")) {
  assertthat::assert_that(
    base::is.character(continent_id) &&
      base::length(continent_id) == 1L &&
      base::nchar(continent_id) > 0L,
    msg = "'continent_id' must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(path_processed) &&
      base::length(path_processed) == 1L,
    msg = "'path_processed' must be a single character string."
  )

  pattern_str <-
    stringr::str_glue(
      "^data_ft_classification_{continent_id}_",
      "[0-9]{{4}}-[0-9]{{2}}-[0-9]{{2}}\\.qs$"
    )

  vec_files <-
    base::list.files(
      path = path_processed,
      pattern = pattern_str,
      full.names = FALSE
    )

  assertthat::assert_that(
    base::length(vec_files) > 0L,
    msg = stringr::str_glue(
      "No FT classification file found for continent ",
      "'{continent_id}' in '{path_processed}'."
    )
  )

  # YYYY-MM-DD suffix sorts lexicographically = chronologically
  vec_files_sorted <-
    base::sort(vec_files)

  file_latest <-
    vec_files_sorted[base::length(vec_files_sorted)]

  path_to_file <-
    base::file.path(path_processed, file_latest)

  data_ft <-
    qs2::qs_read(file = path_to_file)

  res <-
    dplyr::select(
      data_ft,
      dplyr::all_of(
        base::c("taxon_name", "functional_type")
      )
    )

  return(res)
}
