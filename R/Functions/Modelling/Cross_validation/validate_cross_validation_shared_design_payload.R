#' @title Validate the cross validation shared design Payload
#' @description
#' Applies the artifact-specific registered payload contract.
#' @param payload Named artifact payload.
#' @return Invisible `TRUE`; invalid payloads abort.
#' @export
validate_cross_validation_shared_design_payload <- function(payload = NULL) {
  res <-
    validate_sjsdm_artifact_payload(
      artifact_type = "cross_validation_shared_design",
      payload = payload
    )

  return(res)
}

