#' @title Prepare an Ordered Fold Partition
#' @description
#' Filters a data frame to requested fold identifiers and restores the exact
#' deterministic identifier order. Missing-value handling remains caller-owned.
#' @param data_partition_source
#' Data frame containing the complete sample universe.
#' @param partition_ids
#' Unique ordered identifiers requested for one fold partition.
#' @param id_column
#' Character scalar naming the identifier column.
#' @return
#' Filtered data frame in `partition_ids` order with source columns unchanged.
#' @export
#' @examples
#' prepare_ordered_fold_partition(
#'   data_partition_source = tibble::tibble(
#'     sample_id = base::c("b", "a"),
#'     value = 1:2
#'   ),
#'   partition_ids = base::c("a", "b"),
#'   id_column = "sample_id"
#' )
prepare_ordered_fold_partition <- function(
    data_partition_source = NULL,
    partition_ids = NULL,
    id_column = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_partition_source),
    base::is.character(id_column),
    base::length(id_column) == 1L,
    !base::is.na(id_column),
    id_column %in% base::colnames(data_partition_source),
    msg = "The partition source and identifier column are invalid."
  )

  vec_source_ids <-
    data_partition_source[[id_column]]

  assertthat::assert_that(
    base::is.atomic(partition_ids),
    base::length(partition_ids) > 0L,
    !base::any(base::is.na(partition_ids)),
    !base::any(base::duplicated(partition_ids)),
    !base::any(base::is.na(vec_source_ids)),
    !base::any(base::duplicated(vec_source_ids)),
    msg = "Fold and source identifiers must be non-missing and unique."
  )

  vec_partition_indices <-
    base::match(partition_ids, vec_source_ids)

  if (
    base::any(base::is.na(vec_partition_indices))
  ) {
    cli::cli_abort("One or more requested fold identifiers are missing.")
  }

  res <-
    data_partition_source[
      vec_partition_indices,
      ,
      drop = FALSE
    ]

  return(res)
}
