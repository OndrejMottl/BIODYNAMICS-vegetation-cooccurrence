#' @title Get Preprocessing Controller
#' @description
#' Creates a local `{crew}` controller for paleo preprocessing prebuilds
#' when the `crew_mori` backend is requested through environment
#' variables.
#' @return
#' A `{crew}` local controller when
#' `BIODYNAMICS_PREPROCESSING_BACKEND = "crew_mori"`, otherwise `NULL`.
#' @details
#' The worker count is read from
#' `BIODYNAMICS_PREPROCESSING_WORKERS`. This helper is intentionally
#' environment-driven so normal full-pipeline runs keep the default
#' sequential scheduler.
#' @examples
#' get_preprocessing_controller()
#' @seealso [crew::crew_controller_local()]
#' @export
get_preprocessing_controller <- function() {
  preprocessing_backend <-
    base::Sys.getenv("BIODYNAMICS_PREPROCESSING_BACKEND")

  if (
    !base::identical(preprocessing_backend, "crew_mori")
  ) {
    return(NULL)
  }

  preprocessing_workers <-
    base::Sys.getenv("BIODYNAMICS_PREPROCESSING_WORKERS")

  assertthat::assert_that(
    base::nzchar(preprocessing_workers),
    msg = stringr::str_c(
      "BIODYNAMICS_PREPROCESSING_WORKERS must be set when",
      "BIODYNAMICS_PREPROCESSING_BACKEND is 'crew_mori'.",
      sep = " "
    )
  )

  assertthat::assert_that(
    stringr::str_detect(
      string = preprocessing_workers,
      pattern = "^[1-9][0-9]*$"
    ),
    msg = "BIODYNAMICS_PREPROCESSING_WORKERS must be a positive integer."
  )

  preprocessing_workers <-
    base::as.integer(preprocessing_workers)

  if (
    !base::requireNamespace("crew", quietly = TRUE)
  ) {
    base::stop(
      "Package 'crew' is required for the crew_mori backend.",
      call. = FALSE
    )
  }

  res_controller <-
    crew::crew_controller_local(
      workers = preprocessing_workers,
      seconds_idle = 30,
      garbage_collection = TRUE
    )

  base::return(res_controller)
}
