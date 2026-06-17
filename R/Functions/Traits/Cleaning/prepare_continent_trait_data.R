#' @title Prepare Trait Data for One Continental Unit
#' @description
#' Filters and subsets the wide trait table to taxa present in a
#' single continental unit. Removes taxa where all trait values are
#' `NA`.
#' @param continent_id
#' A single non-empty character string identifying the continental
#' unit (e.g. `"europe"`, `"america"`, `"asia"`). Must match a
#' value in the `scale_id` column of
#' `data_traits_classified_corrected`.
#' @param data_trait_table
#' A wide tibble (rows = taxa, columns = `taxon_name` + trait
#' domain columns) as produced by `make_trait_table()`. Must
#' contain a `taxon_name` column.
#' @param data_traits_classified_corrected
#' A tibble with at least columns `scale_id` (character) and
#' `taxon_resolved` (character), used to identify which taxa
#' belong to `continent_id`.
#' @return
#' A tibble with the same column structure as `data_trait_table`
#' (i.e. `taxon_name` + trait domain columns) but restricted to
#' taxa present in `continent_id` and with at least one non-`NA`
#' trait value.
#' @details
#' **Steps**:
#' \enumerate{
#'   \item Filter `data_traits_classified_corrected` to rows where
#'     `scale_id == continent_id` and collect
#'     `distinct(taxon_resolved)`.
#'   \item Use `dplyr::semi_join()` to subset `data_trait_table`
#'     to those taxa (`taxon_name == taxon_resolved`).
#'   \item Remove rows where all trait columns (i.e. all columns
#'     except `taxon_name`) are `NA`.
#' }
#' @seealso [save_ft_classification_for_continent()],
#'   [cluster_functional_types()]
#' @export
prepare_continent_trait_data <- function(
    continent_id,
    data_trait_table,
    data_traits_classified_corrected) {
  assertthat::assert_that(
    base::is.character(continent_id),
    msg = "`continent_id` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::length(continent_id) == 1L,
    msg = "`continent_id` must be a single non-empty character string."
  )

  assertthat::assert_that(
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
    msg = stringr::str_glue(
      "`data_traits_classified_corrected` must contain ",
      "a `scale_id` column."
    )
  )

  assertthat::assert_that(
    "taxon_resolved" %in% base::colnames(data_traits_classified_corrected),
    msg = stringr::str_glue(
      "`data_traits_classified_corrected` must contain ",
      "a `taxon_resolved` column."
    )
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

  res <-
    dplyr::filter(
      data_continent,
      base::rowSums(
        base::is.na(
          dplyr::select(data_continent, dplyr::all_of(vec_trait_cols))
        )
      ) < base::length(vec_trait_cols)
    )

  return(res)
}
