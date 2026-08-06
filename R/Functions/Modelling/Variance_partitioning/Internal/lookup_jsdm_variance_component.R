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
