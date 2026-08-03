#' @title Load taxa classification
#' @description
#' Retrieves taxonomic classification for a vector of taxa using the
#' taxospace package. Filters results to include only plant taxa.
#' Results are cached on disk so that repeated calls for the same
#' taxa avoid redundant HTTP requests.
#' @param vec_taxa
#' A character vector of taxon names to classify.
#' @param dir_taxa_classification_cache
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
#' `dir_taxa_classification_cache`. A successful result is saved to cache;
#' the empty
#' dummy tibble returned on failure is never cached.
#' @seealso [taxospace::get_classification()], [qs2::qs_read()],
#'   [qs2::qs_save()]
#' @export
load_taxa_classification <- function(
    vec_taxa = NULL,
    dir_taxa_classification_cache = here::here(
      "Data/Temp/taxospace"
    )) {
  assertthat::assert_that(
    base::is.character(vec_taxa) &&
      base::length(vec_taxa) > 0,
    msg = "vec_taxa must be a non-empty character vector"
  )

  assertthat::assert_that(
    assertthat::is.string(dir_taxa_classification_cache),
    msg = stringr::str_c(
      "dir_taxa_classification_cache must be a single ",
      "character string"
    )
  )

  # Create cache directory if it does not exist -----
  if (
    !base::dir.exists(dir_taxa_classification_cache)
  ) {
    base::dir.create(
      dir_taxa_classification_cache,
      recursive = TRUE,
      showWarnings = FALSE
    )
  }

  # Build per-taxon cache file path -----
  # Single taxon: sanitized name for human-readability.
  # Multiple taxa: a deterministic hash of the sorted set.
  vec_cache_file_name <-
    if (
      base::length(vec_taxa) == 1L
    ) {
      stringr::str_replace_all(
        vec_taxa,
        "[^[:alnum:]_]",
        "_"
      )
    } else {
      rlang::hash(base::sort(vec_taxa))
    }

  file_taxa_classification_cache <-
    base::file.path(
      dir_taxa_classification_cache,
      stringr::str_glue("{vec_cache_file_name}.qs")
    )

  # Return from cache if a previous successful result exists -----
  if (
    base::file.exists(file_taxa_classification_cache)
  ) {
    res_taxa_classification_cached <-
      qs2::qs_read(file_taxa_classification_cache)
    return(res_taxa_classification_cached)
  }

  data_taxa_classification_raw <-
    taxospace::get_classification(
      taxa_vec = vec_taxa,
      # This is done so that the best match is returned
      #   even if the result is not flagged as "exact"
      use_only_exact_match = FALSE
    )

  # Failure branch: no classification column returned - do not cache -----
  if (
    !"classification" %in%
      base::names(data_taxa_classification_raw)
  ) {
    res_taxa_classification_empty <-
      tibble::tibble(
        sel_name = vec_taxa,
        name = base::character(),
        rank = base::character(),
        id = base::integer(),
      )
    return(res_taxa_classification_empty)
  }

  data_taxa_classification_plants <-
    data_taxa_classification_raw |>
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
    base::isTRUE(
      base::nrow(data_taxa_classification_plants) == 0
    )
  ) {
    res_taxa_classification_empty <-
      tibble::tibble(
        sel_name = vec_taxa,
        name = base::character(),
        rank = base::character(),
        id = base::integer(),
      )
    return(res_taxa_classification_empty)
  }

  res_taxa_classification <-
    data_taxa_classification_plants |>
    dplyr::select(sel_name, classification) |>
    tidyr::unnest(classification)

  # Save successful classification to cache -----
  qs2::qs_save(
    res_taxa_classification,
    file_taxa_classification_cache
  )

  return(res_taxa_classification)
}
