#' @title Validate the sjsdm cv tuning Payload
#' @description
#' Applies the artifact-specific registered payload contract.
#' @param payload Named artifact payload.
#' @return Invisible `TRUE`; invalid payloads abort.
#' @export
validate_sjsdm_cv_tuning_payload <- function(payload = NULL) {
  res <-
    validate_sjsdm_artifact_payload(
      artifact_type = "sjsdm_cv_tuning",
      payload = payload
    )

  return(res)
}

