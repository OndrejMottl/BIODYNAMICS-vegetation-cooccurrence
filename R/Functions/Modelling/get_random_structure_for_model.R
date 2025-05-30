#' @title Get Random Structure for Model
#' @description
#' Constructs the random structure for HMSC models based on age and/or space.
#' @param data
#' A list containing data for model fitting from the function
#' [check_and_prepare_data_for_fit()].
#' @param type
#' Character vector specifying random effect types ("age", "space").
#' @param min_knots_distance
#' Minimum distance between knots for spatial random effect (optional).
#' Only used if "space" is in `type`.
#' @return
#' A list describing the random structure for the model.
#' @export
get_random_structure_for_model <- function(
    data = NULL,
    type = c("age", "space"),
    min_knots_distance = NULL) {
  `%>%` <- magrittr::`%>%`

  assertthat::assert_that(
    class(data) == "list",
    msg = "data must be a list"
  )

  assertthat::assert_that(
    length(data) == 4,
    msg = "data must contain four elements"
  )

  assertthat::assert_that(
    all(
      names(data) %in% c(
        "data_community_to_fit",
        "data_abiotic_to_fit",
        "data_ages_to_fit",
        "data_coords_to_fit"
      )
    ),
    msg = "data must contain the elements: data_community_to_fit, data_abiotic_to_fit, data_ages_to_fit, data_coords_to_fit"
  )


  assertthat::assert_that(
    is.character(type),
    msg = "type must be a character vector"
  )

  assertthat::assert_that(
    length(type) > 0,
    msg = "type must be a non-empty character vector"
  )

  assertthat::assert_that(
    all(type %in% c("age", "space")),
    msg = "type must be one of 'age' or 'space'"
  )

  assertthat::assert_that(
    is.null(min_knots_distance) || is.numeric(min_knots_distance),
    msg = "min_knots_distance must be NULL or a numeric value"
  )

  assertthat::assert_that(
    is.null(min_knots_distance) || min_knots_distance > 0,
    msg = "min_knots_distance must be NULL or a positive numeric value"
  )

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
