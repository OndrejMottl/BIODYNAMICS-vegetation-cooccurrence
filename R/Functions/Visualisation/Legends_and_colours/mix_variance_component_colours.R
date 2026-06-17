#' @title Mix Variance Component Colours
#' @description
#' Mixes component colours per observation using weighted colour-space
#' coordinates.
#' @param data_component_shares
#' Data frame with observation identifiers, component IDs, and
#' component shares.
#' @param vec_component_colours
#' Named character vector mapping canonical component IDs to HEX base
#' colours.
#' @param vec_required_components
#' Character vector of required canonical component IDs. Defaults to
#' `c("Abiotic", "Spatial", "Associations")`.
#' @param observation_id_column
#' Single character string naming the observation ID column.
#' @param component_column
#' Single character string naming the component ID column.
#' @param share_column
#' Single character string naming the numeric share column.
#' @param method
#' Character string selecting the colour-mixing method. `"HCL"` keeps the
#' historical weighted polar LUV/HCL blend. `"perc_avg"` averages weighted
#' CIE LAB coordinates for a perceptual-average blend.
#' @return
#' Tibble with one row per observation and columns `observation_id`
#' and `tile_fill_colour`.
#' @examples
#' data_component_shares <-
#'   tibble::tibble(
#'     observation_id = base::c(
#'       "obs_1",
#'       "obs_1",
#'       "obs_1",
#'       "obs_2",
#'       "obs_2",
#'       "obs_2"
#'     ),
#'     component = base::c(
#'       "Abiotic",
#'       "Spatial",
#'       "Associations",
#'       "Abiotic",
#'       "Spatial",
#'       "Associations"
#'     ),
#'     component_share = base::c(50, 30, 20, 30, 30, 40)
#'   )
#'
#' mix_variance_component_colours(
#'   data_component_shares = data_component_shares,
#'   vec_component_colours = base::c(
#'     "Abiotic" = "#D95F02",
#'     "Spatial" = "#7570B3",
#'     "Associations" = "#1B9E77"
#'   )
#' )
#' @export
mix_variance_component_colours <- function(
    data_component_shares,
    vec_component_colours,
    vec_required_components = base::c(
      "Abiotic",
      "Spatial",
      "Associations"
    ),
    observation_id_column = "observation_id",
    component_column = "component",
    share_column = "component_share",
    method = base::c("HCL", "perc_avg")) {
  assertthat::assert_that(
    base::is.data.frame(data_component_shares),
    msg = "`data_component_shares` must be a data frame."
  )

  assertthat::assert_that(
    base::is.character(vec_component_colours) &&
      !base::is.null(base::names(vec_component_colours)) &&
      base::length(vec_component_colours) > 0L,
    msg = "`vec_component_colours` must be a named character vector."
  )

  assertthat::assert_that(
    base::is.character(vec_required_components) &&
      base::length(vec_required_components) > 0L,
    msg = "`vec_required_components` must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.character(observation_id_column) &&
      base::length(observation_id_column) == 1L,
    msg = "`observation_id_column` must be a single character string."
  )

  assertthat::assert_that(
    base::is.character(component_column) &&
      base::length(component_column) == 1L,
    msg = "`component_column` must be a single character string."
  )

  assertthat::assert_that(
    base::is.character(share_column) &&
      base::length(share_column) == 1L,
    msg = "`share_column` must be a single character string."
  )

  vec_allowed_methods <-
    base::c("HCL", "perc_avg")

  if (
    base::identical(method, vec_allowed_methods)
  ) {
    method <- "HCL"
  }

  assertthat::assert_that(
    base::is.character(method) &&
      base::length(method) == 1L &&
      method %in% vec_allowed_methods,
    msg = "`method` must be one of 'HCL' or 'perc_avg'."
  )

  vec_required_columns <-
    base::c(
      observation_id_column,
      component_column,
      share_column
    )

  assertthat::assert_that(
    base::all(vec_required_columns %in% base::colnames(data_component_shares)),
    msg = stringr::str_glue(
      "`data_component_shares` must contain columns: ",
      "{stringr::str_c(vec_required_columns, collapse = ', ')}."
    )
  )

  vec_missing_colours <-
    base::setdiff(vec_required_components, base::names(vec_component_colours))

  if (
    base::length(vec_missing_colours) > 0L
  ) {
    cli::cli_abort(
      c(
        "Missing component colours for required components.",
        "i" = stringr::str_glue(
          "Missing: {stringr::str_c(vec_missing_colours, collapse = ', ')}"
        )
      )
    )
  }

  data_components <-
    data_component_shares |>
    dplyr::mutate(
      observation_id = base::as.character(
        .data[[observation_id_column]]
      ),
      component = base::as.character(
        .data[[component_column]]
      ),
      component_share = base::as.numeric(
        .data[[share_column]]
      )
    ) |>
    dplyr::select(
      "observation_id",
      "component",
      "component_share"
    ) |>
    dplyr::filter(
      .data$component %in% vec_required_components
    )

  if (
    base::nrow(data_components) == 0L
  ) {
    cli::cli_abort(
      "Input collapses to empty after filtering required components."
    )
  }

  if (
    base::any(base::is.na(data_components$observation_id))
  ) {
    cli::cli_abort("Observation IDs must not contain missing values.")
  }

  if (
    base::any(base::is.na(data_components$component))
  ) {
    cli::cli_abort("Component IDs must not contain missing values.")
  }

  if (
    base::any(
      !base::is.finite(data_components$component_share) |
        data_components$component_share < 0
    )
  ) {
    cli::cli_abort(
      "Component shares must be finite and non-negative for all rows."
    )
  }

  data_duplicate_components <-
    data_components |>
    dplyr::count(
      .data$observation_id,
      .data$component,
      name = "n_rows"
    ) |>
    dplyr::filter(
      .data$n_rows > 1L
    )

  if (
    base::nrow(data_duplicate_components) > 0L
  ) {
    cli::cli_abort(
      c(
        "Each observation must contain each component at most once.",
        "i" = "Duplicate component rows detected in input."
      )
    )
  }

  data_composition_check <-
    data_components |>
    dplyr::group_by(
      .data$observation_id
    ) |>
    dplyr::summarise(
      n_components = dplyr::n_distinct(.data$component),
      component_share_sum = base::sum(.data$component_share),
      missing_components = list(
        base::setdiff(
          vec_required_components,
          base::unique(.data$component)
        )
      ),
      .groups = "drop"
    )

  data_missing_components <-
    data_composition_check |>
    dplyr::filter(
      .data$n_components != base::length(vec_required_components)
    )

  if (
    base::nrow(data_missing_components) > 0L
  ) {
    vec_problem_ids <-
      data_missing_components |>
      dplyr::slice_head(n = 3L) |>
      dplyr::pull(.data$observation_id)

    message_example_ids <-
      stringr::str_glue(
        "Example IDs: {stringr::str_c(vec_problem_ids, collapse = ', ')}"
      )

    cli::cli_abort(
      c(
        "Required components are missing for one or more observations.",
        "i" = message_example_ids
      )
    )
  }

  data_bad_sums <-
    data_composition_check |>
    dplyr::filter(
      base::abs(.data$component_share_sum - 100) > 1e-4
    )

  if (
    base::nrow(data_bad_sums) > 0L
  ) {
    vec_problem_ids <-
      data_bad_sums |>
      dplyr::slice_head(n = 3L) |>
      dplyr::pull(.data$observation_id)

    message_example_ids <-
      stringr::str_glue(
        "Example IDs: {stringr::str_c(vec_problem_ids, collapse = ', ')}"
      )

    cli::cli_abort(
      c(
        "Malformed compositions detected for one or more observations.",
        "i" = "Required components must sum to 100 for each observation.",
        "i" = message_example_ids
      )
    )
  }

  data_component_colours <-
    tibble::tibble(
      component = vec_required_components,
      base_colour = base::unname(vec_component_colours[vec_required_components])
    ) |>
    dplyr::mutate(
      data_coords = purrr::map(
        .data$base_colour,
        ~ {
          if (
            method == "HCL"
          ) {
            data_coordinates <-
              colorspace::coords(
                methods::as(
                  colorspace::hex2RGB(.x),
                  "polarLUV"
                )
              )

            res_coordinates <-
              tibble::tibble(
                luminance = data_coordinates[1, "L"],
                chroma = data_coordinates[1, "C"],
                hue = data_coordinates[1, "H"]
              )
          } else {
            data_coordinates <-
              colorspace::coords(
                methods::as(
                  colorspace::hex2RGB(.x),
                  "LAB"
                )
              )

            res_coordinates <-
              tibble::tibble(
                luminance = data_coordinates[1, "L"],
                value_a = data_coordinates[1, "A"],
                value_b = data_coordinates[1, "B"]
              )
          }

          return(res_coordinates)
        }
      )
    ) |>
    tidyr::unnest(
      cols = "data_coords"
    )

  data_components_ready <-
    data_components |>
    dplyr::left_join(
      y = data_component_colours,
      by = "component"
    )

  if (
    base::any(base::is.na(data_components_ready$luminance))
  ) {
    cli::cli_abort(
      "Could not resolve colour coordinates for one or more component colours."
    )
  }

  if (
    method == "HCL"
  ) {
    res_data <-
      data_components_ready |>
      dplyr::arrange(
        .data$observation_id,
        .data$component
      ) |>
      dplyr::group_by(
        .data$observation_id
      ) |>
      dplyr::summarise(
        tile_fill_colour = {
          vec_weights <-
            .data$component_share /
            base::sum(.data$component_share)

          value_luminance <-
            base::sum(vec_weights * .data$luminance)

          value_chroma <-
            base::sum(vec_weights * .data$chroma)

          vec_hue_weights <-
            vec_weights * .data$chroma

          if (
            base::sum(vec_hue_weights) <= base::.Machine$double.eps
          ) {
            value_hue <- 0
          } else {
            vec_hue_radians <-
              .data$hue * base::pi / 180

            vec_hue_radians[
              !base::is.finite(vec_hue_radians)
            ] <- 0

            value_hue_x <-
              base::sum(vec_hue_weights * base::cos(vec_hue_radians))

            value_hue_y <-
              base::sum(vec_hue_weights * base::sin(vec_hue_radians))

            if (
              base::abs(value_hue_x) <= base::.Machine$double.eps &&
                base::abs(value_hue_y) <= base::.Machine$double.eps
            ) {
              value_hue <- 0
            } else {
              value_hue <-
                (base::atan2(value_hue_y, value_hue_x) * 180 / base::pi +
                  360) %% 360
            }
          }

          grDevices::hcl(
            h = value_hue,
            c = value_chroma,
            l = value_luminance,
            fixup = TRUE
          )
        },
        .groups = "drop"
      )

    return(res_data)
  }

  res_data <-
    data_components_ready |>
    dplyr::arrange(
      .data$observation_id,
      .data$component
    ) |>
    dplyr::group_by(
      .data$observation_id
    ) |>
    dplyr::summarise(
      tile_fill_colour = {
        vec_weights <-
          .data$component_share /
          base::sum(.data$component_share)

        value_luminance <-
          base::sum(vec_weights * .data$luminance)

        value_a <-
          base::sum(vec_weights * .data$value_a)

        value_b <-
          base::sum(vec_weights * .data$value_b)

        colorspace::hex(
          colorspace::LAB(
            L = value_luminance,
            A = value_a,
            B = value_b
          ),
          fixup = TRUE
        )
      },
      .groups = "drop"
    )

  return(res_data)
}

