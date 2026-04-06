#' @title Get Taxa Classification
#' @description
#' Retrieves taxonomic classification for a vector of taxa using the
#' taxospace package. Filters results to include only plant taxa.
#' Results are cached on disk so that repeated calls for the same
#' taxa avoid redundant HTTP requests.
#' @param data
#' A character vector of taxon names to classify.
#' @param cache_dir
#' Character scalar. Path to the directory where per-taxon
#' classification results are cached as `.qs` files (using the
#' qs2 package). The directory is created automatically if it
#' does not exist. The default is `here::here("Data/Temp/taxospace")`.
#' @return
#' A data frame with columns `sel_name`, `name`, `rank`, and `id`.
#' Returns an empty tibble with those columns when no plant taxa
#' are found or the taxospace service returns no classification.
#' @details
#' Uses `taxospace::get_classification()` to retrieve classification.
#' Flags and filters for plant taxa (kingdom Plantae). Before calling
#' the taxospace service, checks for a cached `.qs` file in
#' `cache_dir`. A successful result is saved to cache; the empty
#' dummy tibble returned on failure is never cached.
#' @seealso [taxospace::get_classification()], [qs2::qs_read()],
#'   [qs2::qs_save()]
#' @export
get_taxa_classification <- function(
    data = NULL,
    cache_dir = here::here("Data/Temp/taxospace")) {
  assertthat::assert_that(
    base::is.character(data) && base::length(data) > 0,
    msg = "data must be a non-empty character vector"
  )

  assertthat::assert_that(
    assertthat::is.string(cache_dir),
    msg = "cache_dir must be a single character string"
  )

  # Create cache directory if it does not exist -----
  if (
    !base::dir.exists(cache_dir)
  ) {
    base::dir.create(
      cache_dir,
      recursive = TRUE,
      showWarnings = FALSE
    )
  }

  # Build per-taxon cache file path -----
  # Single taxon: sanitized name for human-readability.
  # Multiple taxa: a deterministic hash of the sorted set.
  vec_cache_file_name <-
    if (
      base::length(data) == 1L
    ) {
      stringr::str_replace_all(
        data,
        "[^[:alnum:]_]",
        "_"
      )
    } else {
      rlang::hash(base::sort(data))
    }

  vec_cache_file <-
    base::file.path(
      cache_dir,
      base::paste0(vec_cache_file_name, ".qs")
    )

  # Return from cache if a previous successful result exists -----
  if (base::file.exists(vec_cache_file)) {
    res_cached <-
      qs2::qs_read(vec_cache_file)
    return(res_cached)
  }

  res_classification <-
    taxospace::get_classification(
      taxa_vec = data,
      # This is done so that the best match is returned
      #   even if the result is not flagged as "exact"
      use_only_exact_match = FALSE
    )

  # Failure branch: no classification column returned - do not cache -----
  if (
    !"classification" %in% base::names(res_classification)
  ) {
    res_empty <-
      tibble::tibble(
        sel_name = data,
        name = base::character(),
        rank = base::character(),
        id = base::integer(),
      )
    return(res_empty)
  }

  res_plant <-
    res_classification |>
    # Flag taxa that are plants
    dplyr::mutate(
      is_plant = purrr::map_lgl(
        .x = classification,
        .f = ~ .x |>
          dplyr::filter(rank == "kingdom") |>
          dplyr::pull(name) |>
          stringr::str_detect("Plantae") |>
          base::any()
      )
    ) |>
    # Filter only plant taxa
    dplyr::filter(is_plant)

  # Failure branch: no plant taxa found - do not cache -----
  if (
    base::isTRUE(base::nrow(res_plant) == 0)
  ) {
    res_empty <-
      tibble::tibble(
        sel_name = data,
        name = base::character(),
        rank = base::character(),
        id = base::integer(),
      )
    return(res_empty)
  }

  res_final <-
    res_plant |>
    dplyr::select(sel_name, classification) |>
    tidyr::unnest(classification)

  # Save successful classification to cache -----
  qs2::qs_save(res_final, vec_cache_file)

  return(res_final)
}
