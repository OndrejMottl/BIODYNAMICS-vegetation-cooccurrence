#' @title Make Decomposition Diagnostic Routes
#' @description
#' Returns the controlled CZ decomposition diagnostic route table.
#' @return
#' A tibble with route identifiers and route settings.
#' @export
make_decomposition_diagnostic_routes <- function() {
  res <-
    tibble::tibble(
      route_id = c(
        "pooled_spatiotemporal_age",
        "pooled_spatiotemporal_no_age",
        "pooled_spatial_age",
        "temporal_best_slice"
      ),
      sample_mode = c(
        "pooled",
        "pooled",
        "pooled",
        "temporal_best_slice"
      ),
      spatial_mode = c(
        "spatiotemporal",
        "spatiotemporal",
        "spatial",
        "spatial"
      ),
      use_age = c(TRUE, FALSE, TRUE, FALSE),
      age_formula_mode = c(
        "interaction",
        "none",
        "interaction",
        "none"
      )
    )

  return(res)
}
