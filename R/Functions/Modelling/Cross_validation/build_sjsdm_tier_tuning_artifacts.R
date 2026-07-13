#' @title Build sjSDM Tier Tuning Artifacts
#' @description
#' Splits collected tuning summaries by compatible model context and builds
#' one tier-level selected-regularization artifact per context.
#' @param data_tuning_summary
#' Bound unit tuning summaries accepted by
#' [aggregate_sjsdm_tuning_by_tier()].
#' @param created_at
#' Single finite POSIX date-time recorded in every artifact.
#' @param include_sample_weighted
#' Logical passed to [build_sjsdm_tier_tuning_artifact()].
#' @return
#' Named list of bound artifact, source-loss, candidate-aggregation, and
#' selection-sensitivity tibbles.
#' @examples
#' \dontrun{
#' build_sjsdm_tier_tuning_artifacts(
#'   data_tuning_summary = data_tuning_summary,
#'   created_at = base::Sys.time()
#' )
#' }
#' @export
build_sjsdm_tier_tuning_artifacts <- function(
    data_tuning_summary = NULL,
    created_at = NULL,
    include_sample_weighted = TRUE) {
  vec_context_columns <-
    base::c(
      "tier_id",
      "taxonomic_resolution",
      "response_family",
      "predictor_structure",
      "candidate_table_hash"
    )

  assertthat::assert_that(
    base::is.data.frame(data_tuning_summary),
    base::nrow(data_tuning_summary) > 0L,
    base::all(
      vec_context_columns %in%
        base::colnames(data_tuning_summary)
    ),
    msg = "data_tuning_summary is missing model context columns."
  )

  list_context_summaries <-
    data_tuning_summary |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(vec_context_columns))
    ) |>
    dplyr::group_split(.keep = TRUE)

  list_artifacts <-
    list_context_summaries |>
    purrr::map(
      .f = ~ build_sjsdm_tier_tuning_artifact(
        data_tuning_summary = .x,
        created_at = created_at,
        include_sample_weighted = include_sample_weighted
      )
    )

  res <-
    base::list(
      data_artifacts = list_artifacts |>
        purrr::map("artifact") |>
        purrr::list_rbind(),
      data_source_candidate_loss = list_artifacts |>
        purrr::map("source_candidate_loss") |>
        purrr::list_rbind(),
      data_candidate_aggregation = list_artifacts |>
        purrr::map("candidate_aggregation") |>
        purrr::list_rbind(),
      data_selection_sensitivity = list_artifacts |>
        purrr::map("selection_sensitivity") |>
        purrr::list_rbind()
    )

  return(res)
}
