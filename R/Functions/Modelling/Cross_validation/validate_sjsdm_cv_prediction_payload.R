#' @title Validate the sjsdm cv predictions Payload
#' @description
#' Applies the artifact-specific registered payload contract.
#' @param payload Named artifact payload.
#' @return Invisible `TRUE`; invalid payloads abort.
#' @export
validate_sjsdm_cv_prediction_payload <- function(payload = NULL) {
  res <-
    validate_sjsdm_artifact_payload(
      artifact_type = "sjsdm_cv_predictions",
      payload = payload
    )

  return(res)
}

