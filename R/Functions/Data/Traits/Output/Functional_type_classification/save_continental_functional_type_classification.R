#' @title Save Functional-Type Classification for One Continental Unit
#' @description
#' Saves a pre-computed functional-type classification tibble as a
#' dated `.qs` file in `path_processed`. The classification is
#' produced upstream by `assign_functional_type_clusters()` via the
#' `ft_result_continent` pipeline target.
#' @param continent_id
#' A single non-empty character string identifying the continental
#' unit (e.g. `"europe"`, `"america"`, `"asia"`). Used only for
#' naming the output file.
#' @param data_functional_type_classification
#' A data frame containing the functional-type classification, as
#' returned in the `classification` element of
#' `assign_functional_type_clusters()`. Typically has columns
#' `taxon_name`, `functional_type`, and `silhouette_width`.
#' @param path_classification_directory
#' A single character string giving the directory where the `.qs`
#' output file will be written. Default:
#' `here::here("Data/Processed/Traits")`.
#' @param classification_source_prefix
#' Optional single non-empty character string to prepend to the
#' `continent_id` portion of the file name. Use `NULL` (default)
#' for the historical paleo/global naming convention, or `"modern"`
#' for modern-data functional-type classifications.
#' @param verbose
#' Logical. If `TRUE` (default), progress messages are printed
#' to the console via `cli`.
#' @return
#' A single character string: the absolute path to the `.qs` file
#' that was written. The file is saved via
#' `RUtilpol::save_latest_file()` using the name stem
#' `data_ft_classification_{continent_id}`
#' when `classification_source_prefix = NULL`, or
#' `data_ft_classification_{classification_source_prefix}_{continent_id}`
#' otherwise. The final file name includes a date stamp and
#' content hash appended by `RUtilpol` (e.g.
#' `data_ft_classification_europe_2026-05-07__abc123__.qs`).
#' @details
#' **Steps performed**:
#' \enumerate{
#'   \item Validate arguments.
#'   \item Save `data_functional_type_classification` with
#'     `RUtilpol::save_latest_file()` as a dated `.qs` file in
#'     `path_classification_directory`. The file is only overwritten when the
#'     content has changed since the previous version.
#'   \item Resolve the path of the just-saved file via
#'     `RUtilpol::get_latest_file_name()`.
#'   \item Return the file path as a character string.
#' }
#' Data filtering, distance computation, hierarchical clustering,
#' ft-groups selection are all handled upstream by
#' `select_continental_trait_table()`, `compute_trait_dissimilarity()`,
#' `fit_hierarchical_clustering()`, and `assign_functional_type_clusters()` respectively.
#' @seealso [select_continental_trait_table()],
#'   [compute_trait_dissimilarity()], [fit_hierarchical_clustering()],
#'   [assign_functional_type_clusters()]
#' @export
save_continental_functional_type_classification <- function(
    continent_id,
    data_functional_type_classification,
    path_classification_directory = here::here("Data/Processed/Traits"),
    classification_source_prefix = NULL,
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.character(continent_id),
    base::length(continent_id) == 1L,
    base::nchar(continent_id) > 0L,
    msg = "`continent_id` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.data.frame(data_functional_type_classification),
    msg = "`data_functional_type_classification` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(path_classification_directory),
    base::length(path_classification_directory) == 1L,
    msg = "`path_classification_directory` must be a character string."
  )

  if (
    !base::is.null(classification_source_prefix)
  ) {
    assertthat::assert_that(
      base::is.character(classification_source_prefix),
      base::length(classification_source_prefix) == 1L,
      base::nchar(classification_source_prefix) > 0L,
      msg = stringr::str_c(
        "`classification_source_prefix` must be NULL or a single ",
        "non-empty character string."
      )
    )
  }

  assertthat::assert_that(
    base::is.logical(verbose),
    base::length(verbose) == 1L,
    msg = "`verbose` must be a single logical value."
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
      "data_ft_classification_",
      "{classification_file_prefix}{continent_id}"
    )

  # RUtilpol verbosity is suppressed here: our own `verbose` argument
  #   controls all console output via cli::cli_inform() below.
  RUtilpol::save_latest_file(
    object_to_save = data_functional_type_classification,
    file_name = classification_file_stem,
    dir = path_classification_directory,
    prefered_format = "qs",
    verbose = FALSE
  )

  path_classification_file <-
    base::file.path(
      path_classification_directory,
      RUtilpol::get_latest_file_name(
        file_name = classification_file_stem,
        dir = path_classification_directory,
        verbose = FALSE
      )
    )

  if (
    base::isTRUE(verbose)
  ) {
    cli::cli_inform(
      c(
        "i" = stringr::str_glue(
          "Saved FT classification for {continent_id} to:"
        ),
        " " = path_classification_file
      )
    )
  }

  return(path_classification_file)
}
