#' @title Validate an sjSDM Artifact Envelope
#' @description
#' Validates the common v2 envelope, registered payload names, provenance,
#' and deterministic content hash.
#' @param list_artifact
#' Named list containing one persisted v2 artifact.
#' @param expected_artifact_type
#' Optional character scalar required artifact type.
#' @return
#' Invisible `TRUE`. Invalid artifacts abort.
#' @examples
#' \dontrun{
#' validate_sjsdm_artifact_envelope(
#'   list_artifact = list_sjsdm_cv_prediction_artifact,
#'   expected_artifact_type = "sjsdm_cv_predictions"
#' )
#' }
#' @export
validate_sjsdm_artifact_envelope <- function(
    list_artifact = NULL,
    expected_artifact_type = NULL) {
  vec_envelope_names <-
    base::c(
      "schema_version",
      "artifact_type",
      "payload",
      "provenance",
      "content_hash"
    )

  assertthat::assert_that(
    base::is.list(list_artifact),
    base::identical(base::names(list_artifact), vec_envelope_names),
    msg = "list_artifact must use the exact v2 envelope."
  )

  schema_version <-
    list_artifact[["schema_version"]]

  artifact_type <-
    list_artifact[["artifact_type"]]

  payload <-
    list_artifact[["payload"]]

  provenance <-
    list_artifact[["provenance"]]

  content_hash <-
    list_artifact[["content_hash"]]

  assertthat::assert_that(
    base::is.character(schema_version),
    base::identical(schema_version, "2.0.0"),
    msg = "Only sjSDM artifact schema version 2.0.0 is supported."
  )

  list_registry <-
    build_sjsdm_artifact_registry()

  assertthat::assert_that(
    base::is.character(artifact_type),
    base::length(artifact_type) == 1L,
    !base::is.na(artifact_type),
    artifact_type %in% base::names(list_registry),
    msg = "artifact_type is not registered."
  )

  if (
    !base::is.null(expected_artifact_type)
  ) {
    assertthat::assert_that(
      base::is.character(expected_artifact_type),
      base::length(expected_artifact_type) == 1L,
      !base::is.na(expected_artifact_type),
      base::nzchar(expected_artifact_type),
      msg = "expected_artifact_type must be one non-empty string."
    )

    if (
      !base::identical(artifact_type, expected_artifact_type)
    ) {
      cli::cli_abort(
        "The artifact type does not match the expected contract."
      )
    }
  }

  vec_expected_payload_names <-
    list_registry[[artifact_type]]

  if (
    !base::is.list(payload) ||
      !base::identical(
        base::names(payload),
        vec_expected_payload_names
      )
  ) {
    cli::cli_abort(
      "The artifact payload does not match its registered contract."
    )
  }

  list_payload_validators <-
    base::list(
      cross_validation_shared_design =
        validate_cross_validation_shared_design_payload,
      cross_validation_design =
        validate_cross_validation_design_payload,
      sjsdm_cv_tuning = validate_sjsdm_cv_tuning_payload,
      sjsdm_regularization_selection =
        validate_sjsdm_regularization_selection_payload,
      sjsdm_cv_predictions = validate_sjsdm_cv_prediction_payload,
      sjsdm_cv_evaluation = validate_sjsdm_cv_evaluation_payload,
      sjsdm_tier_tuning = validate_sjsdm_tier_tuning_payload,
      sjsdm_common_regularization =
        validate_sjsdm_common_regularization_payload
    )

  rlang::exec(
    .fn = list_payload_validators[[artifact_type]],
    payload = payload
  )

  vec_common_provenance <-
    base::c(
      "created_at",
      "pipeline_id",
      "configuration_profile",
      "source_schema_version",
      "migration_applied",
      "migration_function"
    )

  assertthat::assert_that(
    base::is.data.frame(provenance),
    base::nrow(provenance) == 1L,
    base::all(
      vec_common_provenance %in% base::colnames(provenance)
    ),
    msg = "Artifact provenance is incomplete."
  )

  created_at <-
    provenance[["created_at"]]

  pipeline_id <-
    provenance[["pipeline_id"]]

  configuration_profile <-
    provenance[["configuration_profile"]]

  source_schema_version <-
    provenance[["source_schema_version"]]

  migration_applied <-
    provenance[["migration_applied"]]

  migration_function <-
    provenance[["migration_function"]]

  flag_valid_created_at <-
    base::inherits(created_at, "POSIXt") &&
    base::length(created_at) == 1L &&
    !base::is.na(created_at) &&
    base::is.finite(base::as.numeric(created_at))

  flag_valid_character_provenance <-
    purrr::every(
      base::list(
        pipeline_id,
        configuration_profile,
        source_schema_version
      ),
      ~ base::is.character(.x) &&
        base::length(.x) == 1L &&
        !base::is.na(.x) &&
        base::nzchar(.x)
    )

  flag_valid_migration <-
    base::is.logical(migration_applied) &&
    base::length(migration_applied) == 1L &&
    !base::is.na(migration_applied) &&
    base::is.character(migration_function) &&
    base::length(migration_function) == 1L &&
    (
      (
        !migration_applied &&
          base::is.na(migration_function)
      ) ||
      (
        migration_applied &&
          !base::is.na(migration_function) &&
          base::nzchar(migration_function)
      )
    )

  flag_valid_source_version <-
    if (
      base::identical(migration_applied, TRUE)
    ) {
      base::identical(source_schema_version, "1.0.0")
    } else {
      base::identical(migration_applied, FALSE) &&
        base::identical(source_schema_version, "2.0.0") &&
        base::is.na(migration_function)
    }

  assertthat::assert_that(
    flag_valid_created_at,
    flag_valid_character_provenance,
    flag_valid_migration,
    flag_valid_source_version,
    msg = "Artifact provenance values are invalid."
  )

  assertthat::assert_that(
    base::is.character(content_hash),
    base::length(content_hash) == 1L,
    !base::is.na(content_hash),
    stringr::str_detect(content_hash, "^[0-9a-f]{16}$"),
    msg = "content_hash must be one xxHash64 string."
  )

  expected_content_hash <-
    compute_sjsdm_artifact_content_hash(
      schema_version = schema_version,
      artifact_type = artifact_type,
      payload = payload,
      provenance = provenance
    )

  if (
    !base::identical(content_hash, expected_content_hash)
  ) {
    cli::cli_abort("The artifact content hash does not match its content.")
  }

  return(base::invisible(TRUE))
}
