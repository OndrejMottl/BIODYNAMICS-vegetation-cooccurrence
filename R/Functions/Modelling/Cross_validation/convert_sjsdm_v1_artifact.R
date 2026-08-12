#' @title Convert a Frozen v1 sjSDM Artifact Bundle
#' @description
#' Converts one strictly identified v1 target bundle into the common v2
#' envelope without modifying its source store.
#' @param artifact_type Registered v2 artifact type.
#' @param payload Named v2 payload assembled from validated v1 targets.
#' @param v1_schema_hash Frozen v1 schema-fixture hash.
#' @param pipeline_id Source pipeline identifier.
#' @param configuration_profile Source configuration profile.
#' @param migration_function Explicit converter name.
#' @param created_at Conversion time.
#' @return Validated migrated v2 artifact envelope.
#' @export
convert_sjsdm_v1_artifact <- function(
    artifact_type = NULL,
    payload = NULL,
    v1_schema_hash = NULL,
    pipeline_id = NULL,
    configuration_profile = NULL,
    migration_function = NULL,
    created_at = base::Sys.time()) {
  assertthat::assert_that(
    base::identical(
      v1_schema_hash,
      "2d727fd54623501e0ac384e0674c17f3"
    ),
    base::is.character(migration_function),
    base::length(migration_function) == 1L,
    !base::is.na(migration_function),
    base::nzchar(migration_function),
    msg = "The v1 artifact fixture or converter is not recognized."
  )

  provenance <-
    build_sjsdm_artifact_provenance(
      pipeline_id = pipeline_id,
      configuration_profile = configuration_profile,
      created_at = created_at,
      source_schema_version = "1.0.0",
      migration_applied = TRUE,
      migration_function = migration_function,
      stable_provenance = base::list(
        v1_schema_hash = v1_schema_hash
      )
    )

  res <-
    build_sjsdm_artifact_envelope(
      artifact_type = artifact_type,
      payload = payload,
      provenance = provenance
    )

  return(res)
}
