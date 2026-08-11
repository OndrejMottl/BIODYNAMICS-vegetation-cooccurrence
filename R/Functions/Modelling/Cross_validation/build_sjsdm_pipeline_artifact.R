#' @title Build an sjSDM Pipeline Artifact
#' @description
#' Builds common provenance and a validated v2 envelope at a pipeline stage
#' boundary.
#' @param artifact_type Registered artifact type.
#' @param payload Exact named payload list.
#' @param pipeline_id Pipeline identifier.
#' @param configuration_profile Active configuration profile.
#' @param created_at Finite creation time.
#' @param stable_provenance Optional stable scientific provenance.
#' @return Validated v2 artifact envelope.
#' @export
build_sjsdm_pipeline_artifact <- function(
    artifact_type = NULL,
    payload = NULL,
    pipeline_id = NULL,
    configuration_profile = NULL,
    created_at = base::Sys.time(),
    stable_provenance = base::list()) {
  provenance <-
    build_sjsdm_artifact_provenance(
      pipeline_id = pipeline_id,
      configuration_profile = configuration_profile,
      created_at = created_at,
      stable_provenance = stable_provenance
    )

  res <-
    build_sjsdm_artifact_envelope(
      artifact_type = artifact_type,
      payload = payload,
      provenance = provenance
    )

  return(res)
}
