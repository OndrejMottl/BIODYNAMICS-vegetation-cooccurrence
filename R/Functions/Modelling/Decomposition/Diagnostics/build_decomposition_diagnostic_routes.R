#' @title Make Decomposition Diagnostic Routes
#' @description
#' Returns the controlled CZ decomposition diagnostic route table.
#' @return
#' A tibble with route identifiers and route settings.
#' @export
build_decomposition_diagnostic_routes <- function() {
  res <-
    tibble::tibble(
      route_id = base::c(
        "pooled_spatiotemporal_age",
        "pooled_spatiotemporal_no_age",
        "pooled_spatial_age",
        "temporal_best_slice"
      ),
      sample_mode = base::c(
        "pooled",
        "pooled",
        "pooled",
        "temporal_best_slice"
      ),
      spatial_mode = base::c(
        "spatiotemporal",
        "spatiotemporal",
        "spatial",
        "spatial"
      ),
      use_age = base::c(TRUE, FALSE, TRUE, FALSE),
      age_formula_mode = base::c(
        "interaction",
        "none",
        "interaction",
        "none"
      )
    )

  return(res)
}
