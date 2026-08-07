#' @title Collapse a Spatial Variance Observation ID
#' @description
#' Combines the identifying values for one spatial-variance observation.
#' @param ...
#' Scalar values comprising one observation identifier.
#' @return
#' Single character string with values separated by `"__"`.
#' @export
collapse_spatial_variance_observation_id <- function(...) {
  vec_observation_values <-
    base::c(...)

  res <-
    stringr::str_c(vec_observation_values, collapse = "__")

  return(res)
}
