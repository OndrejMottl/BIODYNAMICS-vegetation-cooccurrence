get_random_structure_for_model <- function(data_coords = NULL, age_lim = NULL, time_step = NULL, min_knots_distance = NULL) {
  data_age <-
    tibble::tibble(
      age = seq(
        from = min(age_lim),
        to = max(age_lim),
        by = time_step
      )
    )

  data_full_random <-
    tidyr::expand_grid(
      data_coords,
      data_age
    ) %>%
    dplyr::mutate(
      age_factor = as.factor(age),
      dataset_name_factor = as.factor(dataset_name)
    )

  data_study_design <-
    data_full_random %>%
    dplyr::mutate(
      row_names = paste0(
        dataset_name,
        "__",
        age
      )
    ) %>%
    tibble::column_to_rownames(var = "row_names") %>%
    dplyr::select(
      "dataset_name" = "dataset_name_factor",
      "age" = "age_factor"
    )

  data_coords_clean <-
    data_coords %>%
    tibble::column_to_rownames(var = "dataset_name") %>%
    dplyr::distinct()

  data_random_age <-
    data_full_random %>%
    dplyr::distinct(age) %>%
    dplyr::mutate(
      row_names = age
    ) %>%
    tibble::column_to_rownames(var = "row_names")

  random_level_age <-
    Hmsc::HmscRandomLevel(
      sData = data_random_age
    )

  vec_random_plots <-
    data_full_random %>%
    dplyr::distinct(dataset_name) %>%
    purrr::chuck("dataset_name")

  random_level_plots <-
    Hmsc::HmscRandomLevel(
      units = vec_random_plots
    )


  random_coors_knots <-
    Hmsc::constructKnots(
      sData = data_coords_clean,
      minKnotDist = min_knots_distance
    )

  random_level_coords <-
    Hmsc::HmscRandomLevel(
      sData = data_coords_clean,
      sMethod = "GPP",
      sKnot = random_coors_knots
    )

  list_random <-
    list(
      "age" = random_level_age,
      "plots" = random_level_plots,
      "coords" = random_level_coords
    )

  list(
    random_levels = list_random,
    study_design = data_study_design
  ) %>%
    return()
}
