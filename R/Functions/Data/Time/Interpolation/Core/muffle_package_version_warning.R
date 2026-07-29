#' @title Muffle Package-Version Warnings
#' @description
#' Suppresses package build-version warnings replayed by future workers.
#' @param condition_captured
#' A warning condition passed by [base::withCallingHandlers()].
#' @return
#' `NULL`, invisibly. Matching package-version warnings are muffled through the
#' active warning restart.
#' @keywords internal
.muffle_package_version_warning <- function(condition_captured) {
  warning_message <-
    base::conditionMessage(condition_captured)

  if (
    base::startsWith(warning_message, "package '") &&
      base::grepl(
        pattern = "built under R version",
        x = warning_message,
        fixed = TRUE
      )
  ) {
    base::invokeRestart("muffleWarning")
  }

  base::return(base::invisible(NULL))
}
