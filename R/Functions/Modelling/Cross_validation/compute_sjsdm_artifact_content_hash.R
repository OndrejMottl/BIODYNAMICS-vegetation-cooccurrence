#' @title Compute an sjSDM Artifact Content Hash
#' @description
#' Computes the stable xxHash64 identity of one v2 artifact while excluding
#' materialization and migration-trace provenance.
#' @param schema_version
#' Non-empty character scalar schema version.
#' @param artifact_type
#' Registered non-empty character scalar artifact type.
#' @param payload
#' Non-empty named list containing the artifact payload.
#' @param provenance
#' One-row provenance data frame containing the common provenance fields.
#' @return
#' Character scalar xxHash64 content digest.
#' @examples
#' compute_sjsdm_artifact_content_hash(
#'   schema_version = "2.0.0",
#'   artifact_type = "sjsdm_cv_predictions",
#'   payload = list(data_predictions = tibble::tibble()),
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
compute_sjsdm_artifact_content_hash <- function(
    schema_version = NULL,
    artifact_type = NULL,
    payload = NULL,
    provenance = NULL) {
  assertthat::assert_that(
    base::is.character(schema_version),
    base::length(schema_version) == 1L,
    !base::is.na(schema_version),
    base::nzchar(schema_version),
    msg = "schema_version must be one non-empty string."
  )

  assertthat::assert_that(
    base::is.character(artifact_type),
    base::length(artifact_type) == 1L,
    !base::is.na(artifact_type),
    base::nzchar(artifact_type),
    msg = "artifact_type must be one non-empty string."
  )

  vec_payload_names <-
    base::names(payload)

  assertthat::assert_that(
    base::is.list(payload),
    base::length(payload) > 0L,
    base::is.character(vec_payload_names),
    base::length(vec_payload_names) == base::length(payload),
    base::all(!base::is.na(vec_payload_names)),
    base::all(base::nzchar(vec_payload_names)),
    !base::any(base::duplicated(vec_payload_names)),
    msg = "payload must be a non-empty uniquely named list."
  )

  vec_excluded_provenance <-
    base::c(
      "created_at",
      "source_schema_version",
      "migration_applied",
      "migration_function"
    )

  assertthat::assert_that(
    base::is.data.frame(provenance),
    base::nrow(provenance) == 1L,
    base::all(
      vec_excluded_provenance %in% base::colnames(provenance)
    ),
    msg = "provenance must contain one complete provenance row."
  )

  data_stable_provenance <-
    provenance |>
    dplyr::select(
      -dplyr::all_of(vec_excluded_provenance)
    )

  list_hash_content <-
    base::list(
      schema_version = schema_version,
      artifact_type = artifact_type,
      payload = payload,
      provenance = data_stable_provenance
    )

  content_hash <-
    digest::digest(
      object = list_hash_content,
      algo = "xxhash64"
    )

  return(content_hash)
}
