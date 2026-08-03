#' @title Load Latest Functional-Type Classification
#' @description
#' Loads the most recent FT classification file for a given
#' continental unit from `Data/Processed/Traits/`. The file is
#' produced by `pipe_segment_traits_ft_clustering` in
#' `pipeline_traits_reference.R` and named
#' `data_ft_classification_{continent_id}_{YYYY-MM-DD}.qs`.
#' @param continent_id
#' A single non-empty character string identifying the continental
#' unit (e.g. `"europe"`, `"america"`, `"asia"`). Must match exactly
#' with the `scale_id` used when the FT classification was saved.
#' @param path_classification_directory
#' A single character string giving the directory that contains the
#' FT classification `.qs` files. Default:
#' `here::here("Data/Processed/Traits")`.
#' @return
#' A tibble with two columns:
#' \describe{
#'   \item{taxon_name}{Character. Taxon names resolved to finest
#'     available rank, matching the `taxon_name` column in the
#'     global trait table.}
#'   \item{functional_type}{Integer. Cluster label
#'     (1..`functional_type_group_count`) assigned for this
#'     continental unit.}
#' }
#' @details
#' The function delegates path selection to
#' [resolve_functional_type_classification_path()] and file loading to
#' [load_functional_type_classification()].
#' @seealso [assign_functional_type_clusters()],
#'   [resolve_functional_type_classification_path()],
#'   [load_functional_type_classification()]
#' @export
load_latest_functional_type_classification <- function(
    continent_id,
    path_classification_directory = here::here("Data/Processed/Traits")) {
  assertthat::assert_that(
    base::is.character(continent_id) &&
      base::length(continent_id) == 1L &&
      base::nchar(continent_id) > 0L,
    msg = "'continent_id' must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(path_classification_directory) &&
      base::length(path_classification_directory) == 1L &&
      base::dir.exists(path_classification_directory),
    msg = "'path_classification_directory' must be an existing directory."
  )

  path_classification_file <-
    resolve_functional_type_classification_path(
      continent_id = continent_id,
      path_classification_directory = path_classification_directory
    )

  data_functional_type_classification <-
    load_functional_type_classification(
      path_classification_file = path_classification_file
    )

  return(data_functional_type_classification)
}
