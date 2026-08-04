#' @title Resolve the sjSDM Fitting Device
#' @description
#' Internal helper that validates GPU runtime requirements and resolves the
#' CPU-parallelism setting for the selected fitting device.
#' @param device Selected sjSDM device.
#' @param parallel Requested CPU parallelism.
#' @param gpu_runtime_validator Injectable strict GPU runtime validator.
#' @return Named list containing `device` and `parallel`.
#' @keywords internal
#' @noRd
.resolve_sjsdm_device <- function(
    device = c("cpu", "gpu"),
    parallel = 0L,
    gpu_runtime_validator = validate_sjsdm_gpu_runtime) {
  device <- base::match.arg(device)

  if (
    device == "gpu"
  ) {
    gpu_runtime_validator(verbose = FALSE)
  }

  if (
    device == "gpu" &&
      base::is.numeric(parallel) &&
      base::length(parallel) == 1L &&
      !base::is.na(parallel) &&
      parallel > 0L
  ) {
    base::message(
      stringr::str_c(
        "Parallel processing is not supported when device = 'gpu'.",
        " Setting parallel to 0L."
      )
    )
    parallel <- 0L
  }

  return(
    base::list(
      device = device,
      parallel = parallel
    )
  )
}
