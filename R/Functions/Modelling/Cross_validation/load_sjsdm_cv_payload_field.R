#' @title Load an sjSDM CV Payload Field
#' @description
#' Reads and validates one canonical native-v2 artifact.
#' @param store_path Targets store path.
#' @param v2_target_name Canonical v2 target name.
#' @param artifact_type Expected v2 artifact type.
#' @param payload_name Payload field to return.
#' @param read_target_function Injectable target reader.
#' @return The requested v2 payload field.
#' @export
load_sjsdm_cv_payload_field <- function(
    store_path = NULL,
    v2_target_name = NULL,
    artifact_type = NULL,
    payload_name = NULL,
    read_target_function = targets::tar_read_raw) {
  list_v2 <-
    read_target_function(
      name = v2_target_name,
      store = store_path
    )

  validate_sjsdm_artifact_envelope(
    list_artifact = list_v2,
    expected_artifact_type = artifact_type
  )
  if (
    !payload_name %in% base::names(list_v2[["payload"]])
  ) {
    cli::cli_abort("The requested v2 payload field is unavailable.")
  }

  return(list_v2[["payload"]][[payload_name]])
}
