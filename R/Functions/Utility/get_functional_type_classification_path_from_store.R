#' @title Get Functional-Type Classification Path from Store
#' @description
#' Resolves the newest functional-type classification `.qs` file
#' for the spatial unit encoded in a `{targets}` store path.
#' @param store
#' A single character string giving the targets store path.
#' Default: `targets::tar_path_store()`.
#' @param path_spatial_grid
#' Path to the spatial grid CSV catalogue file.
#' Default: `here::here("Data/Input/spatial_grid.csv")`.
#' @param path_processed
#' A single character string giving the directory that contains
#' dated FT classification `.qs` files.
#' Default: `here::here("Data/Processed/Traits")`.
#' @param data_source_prefix
#' Optional single non-empty character string identifying a
#' source-specific FT classification family. Use `NULL` (default)
#' for historical paleo/global files, or `"modern"` for modern
#' files.
#' @return
#' A single character string: the path to the newest matching FT
#' classification file for the continent that owns the spatial unit.
#' @details
#' The function extracts `scale_id` from `store`, resolves the owning
#' `continent_id` from the spatial grid, finds matching FT
#' classification files in `path_processed`, and returns the most
#' recent file based on the ISO date suffix in the file name. The
#' function errors when `store` is not a spatial store, when no
#' matching FT classification file exists, or when required inputs
#' are invalid.
#' @examples
#' get_functional_type_classification_path_from_store(
#'   store = here::here(
#'     "Data/targets/spatial_regional/eu_r005/",
#'     "pipeline_spatial_resolution"
#'   )
#' )
#' @seealso
#' get_scale_id_from_store, get_continent_id_from_scale_id,
#' get_functional_type_classification
#' @export
get_functional_type_classification_path_from_store <- function(
    store = targets::tar_path_store(),
    path_spatial_grid = here::here("Data/Input/spatial_grid.csv"),
    path_processed = here::here("Data/Processed/Traits"),
    data_source_prefix = NULL) {
  assertthat::assert_that(
    base::is.character(store) &&
      base::length(store) == 1L,
    msg = "`store` must be a single character string."
  )

  assertthat::assert_that(
    base::is.character(path_spatial_grid) &&
      base::length(path_spatial_grid) == 1L &&
      assertthat::is.readable(path_spatial_grid) &&
      assertthat::has_extension(path_spatial_grid, "csv"),
    msg = "`path_spatial_grid` must be a readable CSV file."
  )

  assertthat::assert_that(
    base::is.character(path_processed) &&
      base::length(path_processed) == 1L &&
      base::dir.exists(path_processed),
    msg = "`path_processed` must be an existing directory."
  )

  if (
    !base::is.null(data_source_prefix)
  ) {
    assertthat::assert_that(
      base::is.character(data_source_prefix) &&
        base::length(data_source_prefix) == 1L &&
        base::nchar(data_source_prefix) > 0L,
      msg = stringr::str_c(
        "`data_source_prefix` must be NULL or a single ",
        "non-empty character string."
      )
    )
  }

  scale_id <-
    get_scale_id_from_store(
      store = store,
      file = path_spatial_grid
    )

  assertthat::assert_that(
    !base::is.null(scale_id),
    msg = stringr::str_glue(
      "get_functional_type_classification_path_from_store() ",
      "requires a spatial store path (scale_id encoded in ",
      "store). Got NULL from get_scale_id_from_store(). ",
      "Check the store path convention: ",
      "Data/targets/{{tier}}/{{scale_id}}/",
      "pipeline_spatial_resolution/"
    )
  )

  continent_id <-
    get_continent_id_from_scale_id(
      scale_id = scale_id,
      file = path_spatial_grid
    )

  file_source_prefix <-
    if (base::is.null(data_source_prefix)) {
      ""
    } else {
      stringr::str_glue("{data_source_prefix}_")
    }

  file_name_base <-
    stringr::str_glue(
      "data_ft_classification_",
      "{file_source_prefix}{continent_id}"
    )

  # RUtilpol verbosity is suppressed: this function has no verbose
  #   argument and any console output here would be unexpected.
  latest_file_name <-
    RUtilpol::get_latest_file_name(
      file_name = file_name_base,
      dir = path_processed,
      verbose = FALSE
    )

  if (
    base::is.na(latest_file_name)
  ) {
    cli::cli_abort(
      stringr::str_glue(
        "No FT classification file found for continent ",
        "'{continent_id}' in '{path_processed}'."
      )
    )
  }

  res_path <-
    base::file.path(path_processed, latest_file_name)

  return(res_path)
}
