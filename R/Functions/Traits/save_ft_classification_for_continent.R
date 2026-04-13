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
#' @param verbose
#' A single logical. If `TRUE` (default), a progress message
#' reporting the saved file path is printed via `cli`.
#' @return
#' A single character string: the absolute path to the `.qs` file
#' that was written. The file is named
#' `data_ft_classification_{continent_id}_{YYYY-MM-DD}.qs`.
#' @details
#' **Steps performed**:
#' \enumerate{
#'   \item Validate arguments.
#'   \item Save `data_classification` with `qs2::qs_save()` to a
#'     dated `.qs` file in `path_processed`.
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

  assertthat::assert_that(
    base::is.logical(verbose),
    base::length(verbose) == 1L,
    msg = "`verbose` must be a single logical value."
  )

  date_str <-
    base::format(base::Sys.Date(), "%Y-%m-%d")

  file_path <-
    base::file.path(
      path_processed,
      stringr::str_glue(
        "data_ft_classification_{continent_id}_{date_str}.qs"
      )
    )

  qs2::qs_save(
    object = data_classification,
    file = file_path
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

  res <- file_path

  return(res)
}
