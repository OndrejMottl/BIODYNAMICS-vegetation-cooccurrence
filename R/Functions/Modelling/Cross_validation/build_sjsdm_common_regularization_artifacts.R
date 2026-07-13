#' @title Build Compatible Common sjSDM Regularization Artifacts
#' @description
#' Splits cross-tier tuning summaries by compatible response context and
#' builds one common regularization artifact for each context.
#' @param data_tuning_summary
#' Non-empty tuning-summary table spanning spatial tiers and model contexts.
#' @param created_at
#' Single POSIX date-time passed to
#' [build_sjsdm_common_regularization_artifact()].
#' @return
#' Named list containing bound artifact, tier-loss, and candidate-aggregation
#' tibbles.
#' @export
build_sjsdm_common_regularization_artifacts <- function(
    data_tuning_summary = NULL,
    created_at = NULL) {
  vec_context_columns <-
    base::c(
      "taxonomic_resolution",
      "response_family",
      "candidate_table_hash"
    )

  assertthat::assert_that(
    base::is.data.frame(data_tuning_summary),
    base::nrow(data_tuning_summary) > 0L,
    base::all(
      vec_context_columns %in% base::colnames(data_tuning_summary)
    ),
    msg = "data_tuning_summary must contain common model contexts."
  )

  list_artifacts <-
    data_tuning_summary |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(vec_context_columns))
    ) |>
    dplyr::group_split() |>
    purrr::map(
      ~ build_sjsdm_common_regularization_artifact(
        data_tuning_summary = .x,
        created_at = created_at
      )
    )

  res <-
    base::list(
      data_artifacts = list_artifacts |>
        purrr::map("artifact") |>
        purrr::list_rbind(),
      data_tier_candidate_loss = list_artifacts |>
        purrr::map("tier_candidate_loss") |>
        purrr::list_rbind(),
      data_candidate_aggregation = list_artifacts |>
        purrr::map("candidate_aggregation") |>
        purrr::list_rbind()
    )

  return(res)
}
