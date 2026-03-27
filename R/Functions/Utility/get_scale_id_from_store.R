#' @title Get Scale ID from Current Targets Store Path
#' @description
#' Determines whether the currently active targets store corresponds
#' to a spatial unit by inspecting the store path and checking it
#' against the project's spatial grid CSV catalogue. Returns the
#' `scale_id` string for spatial pipelines, or `NULL` for
#' non-spatial (named-project) pipelines.
#' @param store
#' A single character string giving the path to the targets data
#' store. Default: `targets::tar_path_store()`, which resolves
#' correctly both inside target commands (including callr worker
#' processes) and when called interactively.
#' @param file
#' Path to the spatial grid CSV catalogue file.
#' Default: `here::here("Data/Input/spatial_grid.csv")`.
#' @return
#' A single character string with the `scale_id` when the store
#' path corresponds to a spatial unit in the CSV catalogue, or
#' `NULL` otherwise.
#' @details
#' The store path convention for spatial pipelines is:
#' `{target_store}/{scale_id}/{pipeline_name}/`. The function
#' extracts the second-to-last path component via
#' `basename(dirname(store))` and checks whether it appears in the
#' `scale_id` column of the spatial grid CSV. For non-spatial
#' pipelines (e.g. `Data/targets/project_cz/pipeline_basic/`) the
#' candidate (`"project_cz"`) is not in the CSV, so `NULL` is
#' returned. When the CSV file does not exist the function returns
#' `NULL` gracefully.
#' @seealso get_spatial_window, get_spatial_model_params
#' @export
get_scale_id_from_store <- function(
    store = targets::tar_path_store(),
    file = here::here("Data/Input/spatial_grid.csv")) {
  assertthat::assert_that(
    is.character(store) && length(store) == 1,
    msg = paste0(
      "`store` must be a single character string.",
      " Got class: ", class(store),
      ", length: ", length(store)
    )
  )

  # Graceful NULL when the catalogue is absent (e.g. isolated test env)
  if (!file.exists(file)) {
    return(NULL)
  }

  # Spatial store convention: {target_store}/{scale_id}/{pipeline_name}
  # so basename(dirname(store)) is the scale_id for spatial pipelines
  #   and the project key (e.g. "project_cz") for non-spatial ones.
  potential_id <-
    basename(dirname(store))

  data_grid <-
    readr::read_csv(
      file = file,
      show_col_types = FALSE
    )

  if (potential_id %in% data_grid$scale_id) {
    return(potential_id)
  }

  res <- NULL

  return(res)
}
