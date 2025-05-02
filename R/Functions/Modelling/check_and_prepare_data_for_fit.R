check_and_prepare_data_for_fit <- function(
    data_community = NULL,
    data_abiotic = NULL,
    data_coords = NULL) {
  data_community_no_na <-
    tidyr::drop_na(data_community)

  data_abiotic_no_na <-
    tidyr::drop_na(data_abiotic)

  data_coords_no_na <-
    tidyr::drop_na(data_coords) %>%
    dplyr::distinct()

  data_community_rownames <-
    data_community_no_na %>%
    tibble::rownames_to_column("row_names") %>%
    dplyr::mutate(
      dataset_name = get_dataset_name_from_rownames(row.names(data_community_no_na)),
      age = get_age_from_rownames(row.names(data_community_no_na))
    ) %>%
    dplyr::select(row_names, dataset_name, age)

  data_abiotic_rownames <-
    data_abiotic_no_na %>%
    tibble::rownames_to_column("row_names") %>%
    dplyr::mutate(
      dataset_name = get_dataset_name_from_rownames(row.names(data_abiotic_no_na)),
      age = get_age_from_rownames(row.names(data_abiotic_no_na))
    ) %>%
    dplyr::select(row_names, dataset_name, age)

  data_coords_rownames <-
    data_coords_no_na %>%
    tibble::rownames_to_column("dataset_name") %>%
    dplyr::select(dataset_name)

  data_intersect <-
    dplyr::inner_join(
      data_community_rownames,
      data_abiotic_rownames,
      by = dplyr::join_by(row_names, dataset_name, age)
    ) %>%
    dplyr::inner_join(
      data_coords_rownames,
      by = dplyr::join_by(dataset_name)
    ) %>%
    dplyr::distinct()

  vec_age <-
    data_intersect %>%
    dplyr::distinct(age) %>%
    purrr::chuck("age") %>%
    as.numeric() %>%
    sort() %>%
    as.character()

  vec_shared_rownames <-
    data_intersect %>%
    dplyr::distinct(row_names) %>%
    purrr::chuck("row_names") %>%
    as.character()

  vec_shared_dataset_names <-
    data_intersect %>%
    dplyr::distinct(dataset_name) %>%
    purrr::chuck("dataset_name") %>%
    as.character()

  data_ages_to_fit <-
    tibble::tibble(
      age = vec_age,
      row_names = vec_age
    ) %>%
    tibble::column_to_rownames("row_names")

  data_community_to_fit <-
    data_community_no_na %>%
    as.data.frame() %>%
    tibble::rownames_to_column("row_names") %>%
    dplyr::filter(row_names %in% vec_shared_rownames) %>%
    tibble::column_to_rownames("row_names")

  data_abiotic_to_fit <-
    data_abiotic_no_na %>%
    as.data.frame() %>%
    tibble::rownames_to_column("row_names") %>%
    dplyr::filter(row_names %in% vec_shared_rownames) %>%
    tibble::column_to_rownames("row_names")

  data_coords_to_fit <-
    data_coords_no_na %>%
    as.data.frame() %>%
    tibble::rownames_to_column("row_names") %>%
    dplyr::filter(row_names %in% vec_shared_dataset_names) %>%
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
