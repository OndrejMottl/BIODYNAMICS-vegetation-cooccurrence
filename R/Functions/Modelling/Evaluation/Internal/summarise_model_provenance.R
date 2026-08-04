#' @title Summarise Model Provenance
#' @description
#' Selects the first provenance row and fills absent fields with typed values.
#' @param data_provenance
#' Model-provenance data frame, or `NULL`.
#' @return
#' A one-row provenance tibble.
#' @noRd
.summarise_model_provenance <- function(data_provenance) {
  data_defaults <-
    tibble::tibble(
      cv_strategy = NA_character_,
      effective_folds = NA_integer_,
      cv_feasibility_status = NA_character_,
      n_locations = NA_integer_,
      n_samples = NA_integer_,
      n_taxa = NA_integer_,
      n_effective_mev = NA_integer_,
      regularization_source = NA_character_,
      source_tier = NA_character_,
      candidate_id = NA_character_
    )

  data_provenance_first <-
    if (
      base::is.data.frame(data_provenance) &&
        base::nrow(data_provenance) > 0L
    ) {
      data_provenance |>
        dplyr::slice_head(n = 1L)
    } else {
      tibble::tibble()
    }

  res <-
    dplyr::bind_rows(
      data_provenance_first,
      data_defaults
    ) |>
    dplyr::slice_head(n = 1L)

  return(res)
}
