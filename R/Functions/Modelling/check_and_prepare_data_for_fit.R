#' @title Check and Prepare Data for Model Fitting
#' @description
#' Cleans and prepares community, abiotic, and coordinate data for HMSC model
#' fitting, with optional age subsetting.
#' @param data_community
#' Data frame of community data.
#' @param data_abiotic
#' Data frame of abiotic data.
#' @param data_coords
#' Data frame of coordinates.
#' @param subset_age
#' Optional age value to subset data.
#' @seealso [make_hmsc_model()]
#' @return
#' A list of cleaned and prepared data frames for model fitting.
#' @export
check_and_prepare_data_for_fit <- function(
    data_community = NULL,
    data_abiotic = NULL,
    data_coords = NULL,
    subset_age = NULL) {
  `%>%` <- magrittr::`%>%`

  data_community_no_na <-
    tidyr::drop_na(data_community)

  data_abiotic_no_na <-
    tidyr::drop_na(data_abiotic)

  data_coords_no_na <-
    tidyr::drop_na(data_coords) %>%
    dplyr::distinct()

  if (
    !is.null(subset_age)
  ) {
    data_community_no_na <-
      data_community_no_na %>%
      add_age_column_from_rownames() %>%
      dplyr::filter(age == subset_age) %>%
      dplyr::select(-age)

    data_abiotic_no_na <-
      data_abiotic_no_na %>%
      add_age_column_from_rownames() %>%
      dplyr::filter(age == subset_age) %>%
      dplyr::select(-age)
  }

  data_community_rownames <-
    data_community_no_na %>%
    add_age_column_from_rownames() %>%
    add_dataset_name_column_from_rownames() %>%
    dplyr::distinct(dataset_name, age)

  data_abiotic_rownames <-
    data_abiotic_no_na %>%
    add_age_column_from_rownames() %>%
    add_dataset_name_column_from_rownames() %>%
    dplyr::distinct(dataset_name, age)

  data_coords_rownames <-
    data_coords_no_na %>%
    tibble::rownames_to_column("dataset_name") %>%
    dplyr::distinct(dataset_name)

  data_intersect <-
    dplyr::inner_join(
      data_community_rownames,
      data_abiotic_rownames,
      by = dplyr::join_by(dataset_name, age)
    ) %>%
    dplyr::inner_join(
      data_coords_rownames,
      by = dplyr::join_by(dataset_name)
    ) %>%
    dplyr::distinct()

  data_community_to_fit <-
    data_community_no_na %>%
    add_age_column_from_rownames() %>%
    add_dataset_name_column_from_rownames() %>%
    tibble::rownames_to_column("row_names") %>%
    dplyr::inner_join(
      data_intersect,
      by = dplyr::join_by(dataset_name, age)
    ) %>%
    dplyr::select(-dataset_name, -age) %>%
    tibble::column_to_rownames("row_names")


  data_abiotic_to_fit <-
    data_abiotic_no_na %>%
    add_age_column_from_rownames() %>%
    add_dataset_name_column_from_rownames() %>%
    tibble::rownames_to_column("row_names") %>%
    dplyr::inner_join(
      data_intersect,
      by = dplyr::join_by(dataset_name, age)
    ) %>%
    dplyr::select(-dataset_name, -age) %>%
    tibble::column_to_rownames("row_names")

  vec_shared_dataset_names <-
    data_intersect %>%
    dplyr::distinct(dataset_name) %>%
    purrr::chuck("dataset_name") %>%
    as.character()

  data_coords_to_fit <-
    data_coords_no_na %>%
    as.data.frame() %>%
    tibble::rownames_to_column("row_names") %>%
    dplyr::filter(row_names %in% vec_shared_dataset_names) %>%
    tibble::column_to_rownames("row_names")

  vec_age <-
    data_intersect %>%
    dplyr::distinct(age) %>%
    purrr::chuck("age") %>%
    as.numeric() %>%
    sort() %>%
    as.character()

  data_ages_to_fit <-
    tibble::tibble(
      age = vec_age,
      row_names = age
    ) %>%
    tibble::column_to_rownames("row_names")

  res <-
    list(
      data_community_to_fit = data_community_to_fit,
      data_abiotic_to_fit = data_abiotic_to_fit,
      data_ages_to_fit = data_ages_to_fit,
      data_coords_to_fit = data_coords_to_fit
    )

  return(res)
}
