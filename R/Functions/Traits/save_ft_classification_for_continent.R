#' @title Save Functional-Type Classification for One Continental Unit
#' @description
#' Clusters taxa present in one continental unit into functional
#' types (FTs) and saves the result as a dated `.qs` file in
#' `path_processed`. This function encapsulates the per-continent
#' body of `pipe_segment_trait_ft_clustering` so that the pipe
#' target stays concise and the logic is independently testable.
#' @param continent_id
#' A single non-empty character string identifying the continental
#' unit (e.g. `"europe"`, `"america"`, `"asia"`). Must match
#' a value in the `scale_id` column of
#' `data_traits_classified_corrected`.
#' @param data_trait_table
#' A wide tibble (rows = taxa, columns = trait domains + a
#' `taxon_name` character column) as produced by
#' `make_trait_table()`. Must contain a `taxon_name` column.
#' @param data_traits_classified_corrected
#' A tibble with at least columns `scale_id` (character) and
#' `taxon_resolved` (character), used to identify which taxa
#' belong to `continent_id`.
#' @param k_max
#' A single integer giving the maximum number of functional-type
#' clusters to evaluate. Must be >= 2. The effective k_max is
#' silently capped to `nrow(data_continent) - 1` if the taxon
#' count for the continent is small. Default: `10L`.
#' @param path_processed
#' A single character string giving the directory where the `.qs`
#' output file will be written. Default:
#' `here::here("Data/Processed/Traits")`.
#' @param verbose
#' A single logical. If `TRUE` (default), progress messages are
#' printed to the console via `cli`.
#' @return
#' A single character string: the absolute path to the `.qs` file
#' that was written. The file is named
#' `data_ft_classification_{continent_id}_{YYYY-MM-DD}.qs`.
#' @details
#' **Steps performed**:
#' \enumerate{
#'   \item Filter `data_traits_classified_corrected` to rows where
#'     `scale_id == continent_id` and collect distinct
#'     `taxon_resolved` names.
#'   \item Use `dplyr::semi_join()` to subset `data_trait_table`
#'     to those taxa.
#'   \item Remove any taxa where all trait values are `NA`.
#'   \item Cap `k_max` to `nrow(data_continent) - 1` and call
#'     `cluster_functional_types()`.
#'   \item Save the resulting tibble with `qs2::qs_save()` to a
#'     dated `.qs` file in `path_processed`.
#'   \item Return the file path invisibly as a character string.
#' }
#' @seealso [cluster_functional_types()],
#'   [get_functional_type_classification()]
#' @export
save_ft_classification_for_continent <- function(
    continent_id,
    data_trait_table,
    data_traits_classified_corrected,
    k_max = 10L,
    path_processed = here::here("Data/Processed/Traits"),
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.character(continent_id),
    base::length(continent_id) == 1L,
    base::nchar(continent_id) > 0L,
    msg = "`continent_id` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.data.frame(data_trait_table),
    msg = "`data_trait_table` must be a data frame."
  )

  assertthat::assert_that(
    "taxon_name" %in% base::colnames(data_trait_table),
    msg = "`data_trait_table` must contain a `taxon_name` column."
  )

  assertthat::assert_that(
    base::is.data.frame(data_traits_classified_corrected),
    msg = "`data_traits_classified_corrected` must be a data frame."
  )

  assertthat::assert_that(
    "scale_id" %in% base::colnames(data_traits_classified_corrected),
    msg = "`data_traits_classified_corrected` must contain a `scale_id` column."
  )

  assertthat::assert_that(
    "taxon_resolved" %in% base::colnames(data_traits_classified_corrected),
    msg = stringr::str_c(
      "`data_traits_classified_corrected` must contain a ",
      "`taxon_resolved` column."
    )
  )

  assertthat::assert_that(
    base::is.numeric(k_max) || base::is.integer(k_max),
    base::length(k_max) == 1L,
    base::as.integer(k_max) >= 2L,
    msg = "`k_max` must be a single integer >= 2."
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

  data_taxa_continent <-
    dplyr::filter(
      data_traits_classified_corrected,
      .data[["scale_id"]] == continent_id
    ) |>
    dplyr::distinct(.data[["taxon_resolved"]])

  data_continent <-
    dplyr::semi_join(
      data_trait_table,
      data_taxa_continent,
      by = dplyr::join_by(taxon_name == taxon_resolved)
    )

  vec_trait_cols <-
    base::setdiff(base::colnames(data_continent), "taxon_name")

  data_continent <-
    dplyr::filter(
      data_continent,
      base::rowSums(base::is.na(
        dplyr::select(data_continent, dplyr::all_of(vec_trait_cols))
      )) < base::length(vec_trait_cols)
    )

  k_max_use <-
    base::min(
      base::as.integer(k_max),
      base::nrow(data_continent) - 1L
    )

  data_ft <-
    cluster_functional_types(
      data = data_continent,
      k_max = k_max_use,
      verbose = verbose
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
    object = data_ft,
    file = file_path
  )

  res <- file_path

  return(res)
}
