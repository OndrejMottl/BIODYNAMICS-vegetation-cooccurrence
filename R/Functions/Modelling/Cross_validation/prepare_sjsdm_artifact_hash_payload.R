#' @title Prepare an sjSDM Artifact Payload for Stable Hashing
#' @description
#' Recursively removes materialization and migration-trace fields before an
#' artifact payload contributes to its stable scientific content hash.
#' @param value Artifact payload value or nested component.
#' @return Payload value with unstable trace fields removed.
#' @export
prepare_sjsdm_artifact_hash_payload <- function(value = NULL) {
  vec_trace_fields <-
    base::c(
      "created_at",
      "source_schema_version",
      "migration_applied",
      "migration_function"
    )

  if (
    base::is.data.frame(value)
  ) {
    res_table <-
      value |>
      dplyr::select(-dplyr::any_of(vec_trace_fields))

    return(res_table)
  }

  if (
    base::is.list(value)
  ) {
    res_list <-
      value |>
      purrr::map(prepare_sjsdm_artifact_hash_payload)

    return(res_list)
  }

  return(value)
}
