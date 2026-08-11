#' @title Convert a v1 sjsdm common regularization Artifact
#' @description
#' Applies the frozen v1 fixture contract and upgrades an assembled payload to
#' the canonical `sjsdm_common_regularization` v2 envelope.
#' @param payload Exact named v2 payload assembled from frozen v1 targets.
#' @param pipeline_id Source pipeline identifier.
#' @param configuration_profile Source configuration profile.
#' @param created_at Conversion time.
#' @param v1_schema_hash Frozen v1 schema-fixture hash.
#' @return Validated migrated v2 artifact envelope.
#' @export
convert_v1_sjsdm_common_regularization_artifact <- function(
    payload = NULL,
    pipeline_id = NULL,
    configuration_profile = NULL,
    created_at = base::Sys.time(),
    v1_schema_hash = "2d727fd54623501e0ac384e0674c17f3") {
  data_selection <-
    payload[["data_regularization_selection"]]

  if (
    !base::is.data.frame(data_selection) ||
      !"artifact_schema_version" %in%
        base::colnames(data_selection) ||
      !base::all(
        data_selection[["artifact_schema_version"]] == "1.0.0"
      )
  ) {
    cli::cli_abort(
      "The v1 common selection does not match its frozen schema."
    )
  }

  payload[["data_regularization_selection"]][[
    "artifact_schema_version"
  ]] <-
    base::rep("2.0.0", base::nrow(data_selection))

  res <-
    convert_sjsdm_v1_artifact(
      artifact_type = "sjsdm_common_regularization",
      payload = payload,
      v1_schema_hash = v1_schema_hash,
      pipeline_id = pipeline_id,
      configuration_profile = configuration_profile,
      migration_function = "convert_v1_sjsdm_common_regularization_artifact",
      created_at = created_at
    )

  return(res)
}
