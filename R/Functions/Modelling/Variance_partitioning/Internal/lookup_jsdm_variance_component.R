#' @title Look Up a JSDM Variance Component
#' @description
#' Returns the first clamped variance value for a named component, or zero
#' when the component is absent.
#' @param data_slice
#' Data frame containing `component` and `R2_clamped` columns.
#' @param component_name
#' Character scalar naming the requested component.
#' @return
#' Numeric scalar containing the first matching value or zero.
#' @keywords internal
.lookup_jsdm_variance_component <- function(
    data_slice,
    component_name) {
  component_values <-
    data_slice |>
    dplyr::filter(
      .data[["component"]] == component_name
    ) |>
    dplyr::pull("R2_clamped")

  if (base::length(component_values) == 0L) {
    return(0)
  }

  return(component_values[[1L]])
}
