#' @title Check and Prepare Data for Model Fitting
#' @description
#' Cleans and prepares community, abiotic, and coordinate data for HMSC model
#' fitting, with optional age subsetting.
#' @param data_community
#' A data frame of community data in wide format, with sample names as row
#' names in the format "dataset_name__age".
#' @param data_abiotic
#' A data frame of abiotic data with sample names as row names in the format
#' "dataset_name__age", and abiotic variables as columns.
#' @param data_coords
#' A data frame of spatial coordinates with dataset names as row names and
#' columns for longitude and latitude.
#' @param subset_age
#' Optional numeric value specifying a single age to subset the data.
#' If NULL (default), all ages are included.
#' @return
#' A list with four elements: `data_community_to_fit`, `data_abiotic_to_fit`,
#' `data_ages_to_fit`, and `data_coords_to_fit`, all aligned to the
#' intersecting set of datasets and ages.
#' @details
#' Drops NA values, optionally subsets by age, and finds the intersection
#' of samples across community, abiotic, and coordinate data to ensure
#' all inputs are aligned before model fitting.
#' @seealso [make_hmsc_model()]
#' @export
check_and_prepare_data_for_fit <- function(
    data_community = NULL,
    data_abiotic = NULL,
    data_coords = NULL,
    subset_age = NULL) {
  data_community_no_na <-
    tidyr::drop_na(data_community)

  data_abiotic_no_na <-
    tidyr::drop_na(data_abiotic)

  data_coords_no_na <-
    tidyr::drop_na(data_coords) |>
    dplyr::distinct()

  if (
    !is.null(subset_age)
  ) {
    data_community_no_na <-
      data_community_no_na |>
      add_age_column_from_rownames() |>
      dplyr::filter(age == subset_age) |>
      dplyr::select(-age)

    data_abiotic_no_na <-
      data_abiotic_no_na |>
      dplyr::filter(age == subset_age) 
  }

  data_community_rownames <-
    data_community_no_na |>
    add_age_column_from_rownames() |>
    add_dataset_name_column_from_rownames() |>
    dplyr::distinct(dataset_name, age) |>
    dplyr::arrange(dataset_name, age)

  data_abiotic_rownames <-
    data_abiotic_no_na |>
    add_age_column_from_rownames() |>
    add_dataset_name_column_from_rownames() |>
    dplyr::distinct(dataset_name, age) |>
    dplyr::arrange(dataset_name, age)

  data_coords_rownames <-
    data_coords_no_na |>
    tibble::rownames_to_column("dataset_name") |>
    dplyr::distinct(dataset_name) |>
    dplyr::arrange(dataset_name)

  data_intersect <-
    dplyr::inner_join(
      data_community_rownames,
      data_abiotic_rownames,
      by = dplyr::join_by(dataset_name, age)
    ) |>
    dplyr::inner_join(
      data_coords_rownames,
      by = dplyr::join_by(dataset_name)
    ) |>
    dplyr::distinct() |>
    dplyr::arrange(dataset_name, age)


  data_community_to_fit <-
    data_community_no_na |>
    add_age_column_from_rownames() |>
    add_dataset_name_column_from_rownames() |>
    tibble::rownames_to_column("row_names") |>
    dplyr::inner_join(
      data_intersect,
      by = dplyr::join_by(dataset_name, age)
    ) |>
    dplyr::arrange(dataset_name, age) |>
    dplyr::select(-dataset_name, -age) |>
    tibble::column_to_rownames("row_names")


  data_abiotic_to_fit <-
    data_abiotic_no_na |>
    add_age_column_from_rownames() |>
    add_dataset_name_column_from_rownames() |>
    tibble::rownames_to_column("row_names") |>
    dplyr::inner_join(
      data_intersect,
      by = dplyr::join_by(dataset_name, age)
    ) |>
    dplyr::arrange(dataset_name, age) |>
    dplyr::select(-dataset_name) |>
    tibble::column_to_rownames("row_names")


  data_coords_to_fit <-
    data_intersect |>
    dplyr:::left_join(
      data_coords_no_na |>
        tibble::rownames_to_column("dataset_name"),
      by = dplyr::join_by("dataset_name")
    ) |>
    tidyr::drop_na(coord_long, coord_lat) |>
    dplyr::mutate(
      row_names = paste0(dataset_name, "__", age)
    ) |>
    dplyr::arrange(dataset_name, age) |>
    dplyr::select(-dataset_name, -age) |>
    tibble::column_to_rownames("row_names")

  assertthat::assert_that(
    nrow(data_community_to_fit) == nrow(data_abiotic_to_fit),
    nrow(data_community_to_fit) == nrow(data_coords_to_fit),
    nrow(data_abiotic_to_fit) == nrow(data_coords_to_fit),
    all(rownames(data_community_to_fit) == rownames(data_abiotic_to_fit)),
    all(rownames(data_community_to_fit) == rownames(data_coords_to_fit)),
    all(rownames(data_abiotic_to_fit) == rownames(data_coords_to_fit)),
    msg = "The number of rows and row names of data_community_to_fit, data_abiotic_to_fit, and data_coords_to_fit must be the same and in the same order."
  )

  res <-
    list(
      data_community_to_fit = as.matrix(data_community_to_fit),
      data_abiotic_to_fit = data_abiotic_to_fit,
      data_coords_to_fit = data_coords_to_fit
    )

  return(res)
}
