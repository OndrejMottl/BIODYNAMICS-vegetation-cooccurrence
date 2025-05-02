get_random_structure_for_model <- function(data = NULL, min_knots_distance = NULL) {
  `%>%` <- magrittr::`%>%`

  data_study_design <-
    data %>%
    purrr::chuck("data_community_to_fit") %>%
    tibble::rownames_to_column(var = "row_names") %>%
    dplyr::mutate(
      age = get_age_from_rownames(row_names),
      dataset_name = get_dataset_name_from_rownames(row_names),
      age_factor = factor(
        x = age,
        levels = sort(unique(as.numeric(age))),
        ordered = TRUE
      ),
      dataset_name_factor = as.factor(dataset_name)
    ) %>%
    tibble::column_to_rownames(var = "row_names") %>%
    dplyr::select(
      "dataset_name" = "dataset_name_factor",
      "age" = "age_factor"
    )

  data_age <-
    data %>%
    purrr::chuck("data_ages_to_fit") %>%
    dplyr::mutate(
      age = as.numeric(age),
    )

  vec_age <-
    data_age %>%
    dplyr::distinct(age) %>%
    dplyr::pull(age) %>%
    as.character()

  random_level_age <-
    Hmsc::HmscRandomLevel(
      sData = data_age
    )

  data_coords <-
    data %>%
    purrr::chuck("data_coords_to_fit")

  random_coors_knots <-
    Hmsc::constructKnots(
      sData = data_coords,
      minKnotDist = min_knots_distance
    )

  random_level_coords <-
    Hmsc::HmscRandomLevel(
      sData = data_coords,
      sMethod = "GPP",
      sKnot = random_coors_knots
    )

  list_random <-
    list(
      "age" = random_level_age,
      "dataset_name" = random_level_coords
    )

  list(
    random_levels = list_random,
    study_design = data_study_design
  ) %>%
    return()
}
