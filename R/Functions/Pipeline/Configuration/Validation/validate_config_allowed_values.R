#' @title Validate Allowed Configuration Values
#' @description
#' Validates a non-empty, unique character vector against supported values.
#' @param vec_values
#' Character vector supplied by a configuration caller.
#' @param argument_name
#' Single character string naming the validated argument.
#' @param vec_supported_values
#' Non-empty character vector of supported values.
#' @return
#' `NULL`, invisibly. The function aborts when validation fails.
#' @export
validate_config_allowed_values <- function(
    vec_values,
    argument_name,
    vec_supported_values) {
  flag_valid_values <-
    base::is.character(vec_values) &&
    base::length(vec_values) > 0L &&
    base::all(!base::is.na(vec_values)) &&
    base::all(base::nzchar(vec_values)) &&
    !base::any(base::duplicated(vec_values)) &&
    base::all(vec_values %in% vec_supported_values)

  assertthat::assert_that(
    flag_valid_values,
    msg = stringr::str_glue(
      "`{argument_name}` must contain unique values from: ",
      "{stringr::str_c(vec_supported_values, collapse = ', ')}."
    )
  )

  return(base::invisible(NULL))
}
