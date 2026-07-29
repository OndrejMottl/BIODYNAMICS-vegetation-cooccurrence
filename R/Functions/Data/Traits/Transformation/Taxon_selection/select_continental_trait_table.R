#' @title Select a Continental Trait Table
#' @description
#' Filters and subsets the wide trait table to taxa present in a
#' single continental unit. Removes taxa where all trait values are
#' `NA`.
#' @param scale_id
#' A single non-empty character string identifying the continental
#' unit (e.g. `"europe"`, `"america"`, `"asia"`). Must match a
#' value in the `scale_id` column of
#' `data_trait_records_classified`.
#' @param data_trait_table
#' A wide tibble (rows = taxa, columns = `taxon_name` + trait
#' domain columns) as produced by `make_trait_table()`. Must
#' contain a `taxon_name` column.
#' @param data_trait_records_classified
#' A tibble with at least columns `scale_id` (character) and
#' `taxon_resolved` (character), used to identify which taxa
#' belong to `scale_id`.
#' @return
#' A tibble with the same column structure as `data_trait_table`
#' (i.e. `taxon_name` + trait domain columns) but restricted to
#' taxa present in `scale_id` and with at least one non-`NA`
#' trait value.
#' @details
#' **Steps**:
#' \enumerate{
#'   \item Filter `data_trait_records_classified` to rows where
#'     `scale_id` matches the requested continental unit and collect
#'     `distinct(taxon_resolved)`.
#'   \item Use `dplyr::semi_join()` to subset `data_trait_table`
#'     to those taxa (`taxon_name == taxon_resolved`).
#'   \item Remove rows where all trait columns (i.e. all columns
#'     except `taxon_name`) are `NA`.
#' }
#' @seealso [save_ft_classification_for_continent()],
#'   [cluster_functional_types()]
#' @export
select_continental_trait_table <- function(
    scale_id,
    data_trait_table,
    data_trait_records_classified) {
  assertthat::assert_that(
    base::is.character(scale_id),
    msg = "`scale_id` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::length(scale_id) == 1L,
    msg = "`scale_id` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::nchar(scale_id) > 0L,
    msg = "`scale_id` must be a single non-empty character string."
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
    base::is.data.frame(data_trait_records_classified),
    msg = "`data_trait_records_classified` must be a data frame."
  )

  assertthat::assert_that(
    "scale_id" %in% base::colnames(data_trait_records_classified),
    msg = stringr::str_glue(
      "`data_trait_records_classified` must contain ",
      "a `scale_id` column."
    )
  )

  assertthat::assert_that(
    "taxon_resolved" %in% base::colnames(data_trait_records_classified),
    msg = stringr::str_glue(
      "`data_trait_records_classified` must contain ",
      "a `taxon_resolved` column."
    )
  )

  data_continental_taxa <-
    dplyr::filter(
      data_trait_records_classified,
      .data[["scale_id"]] == .env[["scale_id"]]
    ) |>
    dplyr::distinct(.data[["taxon_resolved"]])

  data_trait_table_continental <-
    dplyr::semi_join(
      data_trait_table,
      data_continental_taxa,
      by = dplyr::join_by(taxon_name == taxon_resolved)
    )

  vec_trait_columns <-
    base::setdiff(
      base::colnames(data_trait_table_continental),
      "taxon_name"
    )

  data_trait_table_selected <-
    dplyr::filter(
      data_trait_table_continental,
      base::rowSums(
        base::is.na(
          dplyr::select(
            data_trait_table_continental,
            dplyr::all_of(vec_trait_columns)
          )
        )
      ) < base::length(vec_trait_columns)
    )

  return(data_trait_table_selected)
}
