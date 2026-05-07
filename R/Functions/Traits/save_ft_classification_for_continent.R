#' @title Save Functional-Type Classification for One Continental Unit
#' @description
#' Saves a pre-computed functional-type classification tibble as a
#' dated `.qs` file in `path_processed`. The classification is
#' produced upstream by `cluster_functional_types()` via the
#' `ft_result_continent` pipeline target.
#' @param continent_id
#' A single non-empty character string identifying the continental
#' unit (e.g. `"europe"`, `"america"`, `"asia"`). Used only for
#' naming the output file.
#' @param data_classification
#' A data frame containing the functional-type classification, as
#' returned in the `classification` element of
#' `cluster_functional_types()`. Typically has columns
#' `taxon_name`, `functional_type`, and `silhouette_width`.
#' @param path_processed
#' A single character string giving the directory where the `.qs`
#' output file will be written. Default:
#' `here::here("Data/Processed/Traits")`.
#' @param data_source_prefix
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
#' when `data_source_prefix = NULL`, or
#' `data_ft_classification_{data_source_prefix}_{continent_id}`
#' otherwise. The final file name includes a date stamp and
#' content hash appended by `RUtilpol` (e.g.
#' `data_ft_classification_europe_2026-05-07__abc123__.qs`).
#' @details
#' **Steps performed**:
#' \enumerate{
#'   \item Validate arguments.
#'   \item Save `data_classification` with
#'     `RUtilpol::save_latest_file()` as a dated `.qs` file in
#'     `path_processed`. The file is only overwritten when the
#'     content has changed since the previous version.
#'   \item Resolve the path of the just-saved file via
#'     `RUtilpol::get_latest_file_name()`.
#'   \item Return the file path as a character string.
#' }
#' Data filtering, distance computation, hierarchical clustering,
#' ft-groups selection are all handled upstream by
#' `prepare_continent_trait_data()`, `compute_dissimilarity_matrix()`,
#' `fit_hclust()`, and `cluster_functional_types()` respectively.
#' @seealso [prepare_continent_trait_data()],
#'   [compute_dissimilarity_matrix()], [fit_hclust()],
#'   [cluster_functional_types()]
#' @export
save_ft_classification_for_continent <- function(
    continent_id,
    data_classification,
    path_processed = here::here("Data/Processed/Traits"),
    data_source_prefix = NULL,
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.character(continent_id),
    base::length(continent_id) == 1L,
    base::nchar(continent_id) > 0L,
    msg = "`continent_id` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.data.frame(data_classification),
    msg = "`data_classification` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(path_processed),
    base::length(path_processed) == 1L,
    msg = "`path_processed` must be a single character string."
  )

  if (
    !base::is.null(data_source_prefix)
  ) {
    assertthat::assert_that(
      base::is.character(data_source_prefix),
      base::length(data_source_prefix) == 1L,
      base::nchar(data_source_prefix) > 0L,
      msg = stringr::str_c(
        "`data_source_prefix` must be NULL or a single ",
        "non-empty character string."
      )
    )
  }

  assertthat::assert_that(
    base::is.logical(verbose),
    base::length(verbose) == 1L,
    msg = "`verbose` must be a single logical value."
  )

  file_source_prefix <-
    if (base::is.null(data_source_prefix)) {
      ""
    } else {
      stringr::str_glue("{data_source_prefix}_")
    }

  file_name_base <-
    stringr::str_glue(
      "data_ft_classification_",
      "{file_source_prefix}{continent_id}"
    )

  # RUtilpol verbosity is suppressed here: our own `verbose` argument
  #   controls all console output via cli::cli_inform() below.
  RUtilpol::save_latest_file(
    object_to_save = data_classification,
    file_name = file_name_base,
    dir = path_processed,
    prefered_format = "qs",
    verbose = FALSE
  )

  file_path <-
    base::file.path(
      path_processed,
      RUtilpol::get_latest_file_name(
        file_name = file_name_base,
        dir = path_processed,
        verbose = FALSE
      )
    )

  if (base::isTRUE(verbose)) {
    cli::cli_inform(
      c(
        "i" = stringr::str_glue(
          "Saved FT classification for {continent_id} to:"
        ),
        " " = file_path
      )
    )
  }

  res <-
    file_path

  return(res)
}
