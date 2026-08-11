#' @title Validate the sjsdm regularization selection Payload
#' @description
#' Applies the artifact-specific registered payload contract.
#' @param payload Named artifact payload.
#' @return Invisible `TRUE`; invalid payloads abort.
#' @export
validate_sjsdm_regularization_selection_payload <- function(payload = NULL) {
  res <-
    validate_sjsdm_artifact_payload(
      artifact_type = "sjsdm_regularization_selection",
      payload = payload
    )

  return(res)
}

