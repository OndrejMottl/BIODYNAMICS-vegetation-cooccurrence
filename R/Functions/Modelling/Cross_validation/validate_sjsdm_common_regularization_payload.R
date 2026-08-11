#' @title Validate the sjsdm common regularization Payload
#' @description
#' Applies the artifact-specific registered payload contract.
#' @param payload Named artifact payload.
#' @return Invisible `TRUE`; invalid payloads abort.
#' @export
validate_sjsdm_common_regularization_payload <- function(payload = NULL) {
  res <-
    validate_sjsdm_artifact_payload(
      artifact_type = "sjsdm_common_regularization",
      payload = payload
    )

  return(res)
}

