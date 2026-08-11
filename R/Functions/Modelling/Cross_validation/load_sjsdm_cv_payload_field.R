#' @title Load an sjSDM CV Payload Field
#' @description
#' Reads and validates one canonical v2 artifact before falling back to one
#' documented frozen v1 target. The source store is never modified.
#' @param store_path Targets store path.
#' @param v2_target_name Canonical v2 target name.
#' @param artifact_type Expected v2 artifact type.
#' @param payload_name Payload field to return.
#' @param v1_target_name Frozen v1 fallback target name.
#' @param read_target_function Injectable target reader.
#' @return The requested v2 payload field or validated v1 target value.
#' @export
load_sjsdm_cv_payload_field <- function(
    store_path = NULL,
    v2_target_name = NULL,
    artifact_type = NULL,
    payload_name = NULL,
    v1_target_name = NULL,
    read_target_function = targets::tar_read_raw) {
  list_v2 <-
    tryCatch(
      read_target_function(
        name = v2_target_name,
        store = store_path
      ),
      error = function(error_condition) NULL
    )

  if (
    !base::is.null(list_v2)
  ) {
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

  res <-
    read_target_function(
      name = v1_target_name,
      store = store_path
    )

  if (
    !base::is.list(res) && !base::is.data.frame(res)
  ) {
    cli::cli_abort("The frozen v1 target has an invalid container type.")
  }

  return(res)
}
