#' @title Build Temporal Trajectory Frame
#' @description
#' Builds one animation frame for the temporal ANOVA component trajectory
#' stacked-area plot, optionally overlaying a modularity Q line.
#' @param data_plot
#' Tibble with columns `age`, `component`, and `component_percentage`.
#' @param data_modularity
#' Tibble with columns `age` and `modularity_q`.
#' @param current_age
#' Numeric scalar. Age at which to draw the vertical marker line.
#' @param continent_label
#' Character scalar. Continent name used as the plot title.
#' @param vec_component_colours
#' Named character vector mapping component names to fill colours.
#' @param colour_modularity
#' Character scalar. Colour for the modularity Q overlay line.
#' @param vec_palette
#' Optional named character vector of ORACLE colours. If `NULL`,
#' colours are read with `get_oracle_palette_values()`.
#' @param font_family
#' Character scalar. Font family for all text elements.
#' @return
#' A `ggplot` object ready for one animation frame.
#' @export
build_temporal_trajectory_frame <- function(
    data_plot,
    data_modularity,
    current_age,
    continent_label,
    vec_component_colours,
    colour_modularity,
    vec_palette = NULL,
    font_family = "VT323") {
  assertthat::assert_that(
    base::is.data.frame(data_plot),
    base::all(
      base::c("age", "component", "component_percentage") %in%
        base::colnames(data_plot)
    ),
    msg = paste(
      "'data_plot' must contain columns",
      "'age', 'component', and 'component_percentage'."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_modularity),
    base::all(
      base::c("age", "modularity_q") %in%
        base::colnames(data_modularity)
    ),
    msg = paste(
      "'data_modularity' must contain columns 'age' and 'modularity_q'."
    )
  )

  assertthat::assert_that(
    base::is.numeric(current_age),
    base::length(current_age) == 1L,
    base::is.finite(current_age),
    msg = "'current_age' must be one finite numeric value."
  )

  assertthat::assert_that(
    base::is.character(continent_label),
    base::length(continent_label) == 1L,
    msg = "'continent_label' must be a single character value."
  )

  assertthat::assert_that(
    base::is.character(vec_component_colours),
    base::length(vec_component_colours) >= 1L,
    msg = "'vec_component_colours' must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.character(colour_modularity),
    base::length(colour_modularity) == 1L,
    msg = "'colour_modularity' must be a single character value."
  )

  assertthat::assert_that(
    base::is.character(font_family),
    base::length(font_family) == 1L,
    msg = "'font_family' must be a single character value."
  )

  if (
    base::is.null(vec_palette)
  ) {
    vec_palette <-
      get_oracle_palette_values()
  }

  data_visible <-
    data_plot |>
    dplyr::filter(
      .data$age >= current_age
    ) |>
    dplyr::mutate(
      age = base::as.numeric(.data$age),
      fill_colour = base::unname(
        vec_component_colours[
          base::as.character(.data$component)
        ]
      )
    )

  data_modularity_visible <-
    data_modularity |>
    dplyr::filter(
      .data$age >= current_age
    )

  continent_title <-
    dplyr::case_when(
      continent_label == "America" ~ "America",
      TRUE ~ continent_label
    )

  res_plot <-
    data_visible |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = .data$age,
        y = .data$component_percentage / 100,
        fill = .data$fill_colour,
        group = .data$component
      )
    ) +
    ggplot2::scale_x_reverse(
      limits = base::c(20000, 0),
      breaks = base::c(20000, 15000, 10000, 5000, 0),
      labels = base::c("20k", "15k", "10k", "5k", "0"),
      expand = ggplot2::expansion(mult = base::c(0, 0))
    ) +
    ggplot2::scale_y_continuous(
      limits = base::c(0, 1.02),
      breaks = base::seq(0, 1, by = 0.25),
      labels = function(x) base::format(x, trim = TRUE),
      expand = ggplot2::expansion(mult = base::c(0, 0.03))
    ) +
    ggplot2::scale_fill_identity() +
    ggplot2::labs(
      title = stringr::str_to_upper(continent_title),
      x = "Age (cal yr BP)",
      y = "Proportion",
      fill = NULL
    ) +
    create_oracle_theme(
      base_family = font_family,
      base_size = 10
    ) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(
        fill = vec_palette[["background"]],
        colour = NA
      ),
      panel.background = ggplot2::element_rect(
        fill = vec_palette[["background"]],
        colour = NA
      ),
      panel.border = ggplot2::element_rect(
        fill = NA,
        colour = vec_palette[["border"]],
        linewidth = 0.35
      ),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(
        colour = vec_palette[["border"]],
        linewidth = 0.14,
        linetype = "dotted"
      ),
      panel.grid.major.y = ggplot2::element_line(
        colour = vec_palette[["border"]],
        linewidth = 0.18,
        linetype = "dotted"
      ),
      plot.title = ggplot2::element_text(
        colour = vec_palette[["text"]],
        face = "bold",
        size = 14,
        margin = ggplot2::margin(b = 10)
      ),
      axis.title = ggplot2::element_text(
        colour = vec_palette[["muted"]],
        size = 9
      ),
      axis.text = ggplot2::element_text(
        colour = vec_palette[["text"]],
        size = 8
      ),
      axis.ticks = ggplot2::element_line(
        colour = vec_palette[["border"]],
        linewidth = 0.2
      ),
      legend.position = "none",
      plot.margin = ggplot2::margin(8, 8, 8, 8)
    ) +
    ggview::canvas(
      width = 530,
      height = 800,
      units = "px",
      dpi = 300,
      bg = vec_palette[["background"]]
    ) +
    ggplot2::geom_area(
      alpha = 0.88,
      colour = vec_palette[["muted"]],
      linewidth = 0.12,
      position = "stack"
    ) +
    ggplot2::geom_vline(
      xintercept = current_age,
      colour = vec_palette[["muted"]],
      linewidth = 0.42,
      linetype = "solid",
      alpha = 0.82
    )

  if (
    base::nrow(data_modularity_visible) > 1L
  ) {
    res_plot <-
      res_plot +
      ggplot2::geom_line(
        data = data_modularity_visible,
        mapping = ggplot2::aes(
          x = .data$age,
          y = .data$modularity_q
        ),
        inherit.aes = FALSE,
        linetype = "solid",
        colour = colour_modularity,
        linewidth = 0.7,
        alpha = 0.95
      )
  }

  return(res_plot)
}
