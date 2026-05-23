#' @title Get Functional-Type Classification for a Continental Unit
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
#'   \item{functional_type}{Integer. Cluster label
#'     (1..`number_of_ft_groups`) assigned for this
#'     continental unit.}
#' }
#' @details
#' The function delegates path selection to
#' [get_functional_type_classification_path()] and file loading to
#' [read_functional_type_classification()].
#' @seealso [cluster_functional_types()],
#'   [get_functional_type_classification_path()],
#'   [read_functional_type_classification()]
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
      base::length(path_processed) == 1L &&
      base::dir.exists(path_processed),
    msg = "'path_processed' must be a single existing directory."
  )

  path_to_file <-
    get_functional_type_classification_path(
      continent_id = continent_id,
      path_processed = path_processed
    )

  res <-
    read_functional_type_classification(
      file = path_to_file
    )

  return(res)
}
