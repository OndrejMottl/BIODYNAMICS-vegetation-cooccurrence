#' @title Build an sjSDM Artifact Envelope
#' @description
#' Builds and validates one native cross-validation v2 artifact.
#' @param artifact_type
#' Registered non-empty character scalar artifact type.
#' @param payload
#' Named list with the exact payload names registered for the artifact type.
#' @param provenance
#' One-row data frame with common and artifact-specific provenance.
#' @return
#' Validated named v2 artifact list with deterministic content hash.
#' @examples
#' build_sjsdm_artifact_envelope(
#'   artifact_type = "sjsdm_cv_predictions",
#'   payload = list(
#'     data_predictions = tibble::tibble(),
#'     data_fold_diagnostics = tibble::tibble()
#'   ),
#'   provenance = tibble::tibble(
#'     created_at = as.POSIXct("2026-08-11", tz = "UTC"),
#'     pipeline_id = "pipeline_paleo_core",
#'     configuration_profile = "project_cz_paleo",
#'     source_schema_version = "2.0.0",
#'     migration_applied = FALSE,
#'     migration_function = NA_character_
#'   )
#' )
#' @export
build_sjsdm_artifact_envelope <- function(
    artifact_type = NULL,
    payload = NULL,
    provenance = NULL) {
  content_hash <-
    compute_sjsdm_artifact_content_hash(
      schema_version = "2.0.0",
      artifact_type = artifact_type,
      payload = payload,
      provenance = provenance
    )

  list_artifact <-
    base::list(
      schema_version = "2.0.0",
      artifact_type = artifact_type,
      payload = payload,
      provenance = provenance,
      content_hash = content_hash
    )

  validate_sjsdm_artifact_envelope(
    list_artifact = list_artifact,
    expected_artifact_type = artifact_type
  )

  return(list_artifact)
}
