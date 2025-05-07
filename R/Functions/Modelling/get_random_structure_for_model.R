get_random_structure_for_model <- function(
    data = NULL,
    type = c("age", "space"),
    min_knots_distance = NULL) {
  `%>%` <- magrittr::`%>%`

  list_random <- list()

  data_study_design <-
    data %>%
    purrr::chuck("data_community_to_fit") %>%
    add_dataset_name_column_from_rownames() %>%
    dplyr::mutate(
      dataset_name_factor = as.factor(dataset_name)
    ) %>%
    dplyr::select(
      "dataset_name" = "dataset_name_factor"
    )

  if (
    "age" %in% type
  ) {
    data_study_design <-
      data %>%
      purrr::chuck("data_community_to_fit") %>%
      add_age_column_from_rownames() %>%
      add_dataset_name_column_from_rownames() %>%
      dplyr::mutate(
        age_factor = factor(
          x = age,
          levels = sort(unique(as.numeric(age))),
          ordered = TRUE
        ),
        dataset_name_factor = as.factor(dataset_name)
      ) %>%
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

    list_random <-
      c(
        list_random,
        list("age" = random_level_age)
      )
  }


  if (
    "space" %in% type
  ) {
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
      c(
        list_random,
        list("dataset_name" = random_level_coords)
      )
  }

  list(
    random_levels = list_random,
    study_design = data_study_design
  ) %>%
    return()
}
