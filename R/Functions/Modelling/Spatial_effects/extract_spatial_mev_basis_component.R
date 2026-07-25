#' @title Extract an Optional Spatial MEM Basis Component
#' @description
#' Extracts one explicit component from a reusable spatial MEM basis while
#' preserving `NULL` when the basis is disabled.
#' @param list_spatial_mev_basis
#' Reusable spatial MEM basis list or `NULL`.
#' @param component_name
#' Character scalar naming the component to extract.
#' @return
#' Selected component or `NULL`.
#' @export
extract_spatial_mev_basis_component <- function(
    list_spatial_mev_basis,
    component_name) {
  if (
    base::is.null(list_spatial_mev_basis)
  ) {
    return(NULL)
  }

  assertthat::assert_that(
    base::is.list(list_spatial_mev_basis),
    msg = "`list_spatial_mev_basis` must be a list or NULL."
  )

  assertthat::assert_that(
    base::is.character(component_name),
    base::length(component_name) == 1L,
    !base::is.na(component_name),
    base::nchar(component_name) > 0L,
    msg = "`component_name` must be one non-empty string."
  )

  res <-
    list_spatial_mev_basis |>
    purrr::chuck(component_name)

  return(res)
}
