#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Plot spatial ANOVA association maps
#              - one figure per continent (Europe,
#                Americas, Asia)
#              - three panels per figure (continental,
#                regional, local scale)
#              - rectangles coloured by % Associations
#              - fossil cores overlaid as points
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Loads ANOVA results from all spatial pipeline stores and
#   produces one output figure per continent. Each figure
#   combines three panels (continental/regional/local
#   scale), where rectangles are coloured by the
#   Shapley-adjusted % variance explained by Associations
#   (viridis gradient, grey when no results). Fossil core
#   locations are overlaid as points extracted from
#   per-unit data_coords targets.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

path_output <-
  here::here("Outputs/Figures/Spatial")

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)

# Graphical options shared across all plots in this script.
graphical_options <-
  get_active_config("graphical")

tag_date <- format(base::Sys.Date(), "%Y-%m-%d")


#----------------------------------------------------------#
# 1. Load spatial grid -----
#----------------------------------------------------------#

data_spatial_grid <-
  readr::read_csv(
    here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  ) |>
  dplyr::mutate(
    continent = dplyr::case_when(
      scale == "continental" ~ scale_id,
      stringr::str_starts(scale_id, "eu_") ~ "europe",
      stringr::str_starts(scale_id, "am_") ~ "america",
      stringr::str_starts(scale_id, "as_") ~ "asia"
    ),
    store_path = here::here(
      paste0("Data/targets/spatial_", scale),
      scale_id,
      "pipeline_basic"
    ),
    store_exists = fs::dir_exists(store_path)
  )


#----------------------------------------------------------#
# 2. Extract ANOVA % Associations per unit -----
#----------------------------------------------------------#

data_anova_raw <-
  data_spatial_grid |>
  dplyr::mutate(
    model_anova = purrr::map(
      .x = store_path,
      .f = purrr::possibly(
        ~ targets::tar_read(
          "model_anova",
          store = .x
        ),
        otherwise = NA
      )
    )
  )

data_assoc_pct <-
  data_anova_raw |>
  dplyr::filter(!is.na(model_anova)) |>
  dplyr::mutate(
    assoc_pct = purrr::map_dbl(
      .x = model_anova,
      .f = ~ extract_anova_fractions(
          anova_object = .x,
          clamp_negative = TRUE
        ) |>
        dplyr::mutate(age = 0) |>
        recalculate_anova_components() |>
        dplyr::filter(component == "Associations") |>
        dplyr::pull(R2_Nagelkerke_percentage)
    )
  ) |>
  dplyr::select(scale_id, assoc_pct)

data_grid_with_results <-
  data_spatial_grid |>
  dplyr::left_join(
    data_assoc_pct,
    by = dplyr::join_by(scale_id)
  )


#----------------------------------------------------------#
# 3. Extract core coordinates per unit -----
#----------------------------------------------------------#

data_coords_per_unit <-
  data_spatial_grid |>
  dplyr::filter(store_exists) |>
  dplyr::mutate(
    coords = purrr::map(
      .x = store_path,
      .f = purrr::possibly(
        ~ targets::tar_read(
          "data_coords",
          store = .x
        ) |>
          tibble::rownames_to_column("dataset_name"),
        otherwise = NULL
      )
    )
  ) |>
  dplyr::filter(
    !purrr::map_lgl(coords, base::is.null)
  ) |>
  dplyr::select(scale_id, scale, continent, coords)


#----------------------------------------------------------#
# 4. Load world basemap -----
#----------------------------------------------------------#

sf_world <-
  rnaturalearth::ne_countries(
    scale = "medium",
    returnclass = "sf"
  )


#----------------------------------------------------------#
# 5. Get continent extents -----
#----------------------------------------------------------#

data_continent_extents <-
  data_spatial_grid |>
  dplyr::filter(scale == "continental") |>
  dplyr::select(continent, x_min, x_max, y_min, y_max)


#----------------------------------------------------------#
# 6. Build panels -----
#----------------------------------------------------------#

vec_scale_labels <-
  c(
    "continental" = "Continental",
    "regional" = "Regional",
    "local" = "Local"
  )

vec_continents <- c("europe", "america", "asia")

vec_scales <- c("continental", "regional", "local")

# Build nested list: list_panels[[continent]][[scale]]
list_panels <-
  purrr::map(
    .x = vec_continents,
    .f = \(sel_continent) {

      # Get bounding box for this continent
      extents <-
        data_continent_extents |>
        dplyr::filter(continent == sel_continent)

      xlim_val <-
        c(
          dplyr::pull(extents, x_min),
          dplyr::pull(extents, x_max)
        )

      ylim_val <-
        c(
          dplyr::pull(extents, y_min),
          dplyr::pull(extents, y_max)
        )

      # Build one panel per scale level for this continent
      purrr::map(
        .x = vec_scales,
        .f = \(sel_scale) {

          # Rectangle data for this continent × scale
          data_rects <-
            data_grid_with_results |>
            dplyr::filter(
              continent == sel_continent,
              scale == sel_scale
            )

          # Combined cores for this continent × scale
          data_cores <-
            data_coords_per_unit |>
            dplyr::filter(
              continent == sel_continent,
              scale == sel_scale
            ) |>
            dplyr::pull(coords) |>
            purrr::list_rbind()

          has_cores <- base::nrow(data_cores) > 0

          panel <-
            ggplot2::ggplot() +
            ggplot2::scale_fill_viridis_c(
              option = "viridis",
              name = "Associations (%)",
              limits = c(0, 100),
              na.value = "grey80",
              guide = ggplot2::guide_colorbar(
                barwidth = 0.8,
                barheight = 8
              )
            ) +
            ggplot2::labs(
              title = vec_scale_labels[[sel_scale]],
              x = NULL,
              y = NULL
            ) +
            ggplot2::theme_classic() +
            ggplot2::theme(
              plot.title = ggplot2::element_text(
                hjust = 0.5,
                size = 10
              ),
              axis.text = ggplot2::element_text(size = 6),
              axis.title = ggplot2::element_blank(),
              axis.ticks = ggplot2::element_line(
                linewidth = 0.3
              ),
              panel.border = ggplot2::element_rect(
                fill = NA,
                colour = "grey50",
                linewidth = 0.3
              ),
              legend.title = ggplot2::element_text(size = 8),
              legend.text = ggplot2::element_text(size = 7)
            ) +
            ggview::canvas(
              width = graphical_options[["width"]],
              height = graphical_options[["height"]],
              units = graphical_options[["units"]],
              dpi = graphical_options[["dpi"]],
              bg = graphical_options[["bg"]]
            ) +
            ggplot2::geom_sf(
              data = sf_world,
              fill = "grey90",
              colour = "white",
              linewidth = 0.2,
              inherit.aes = FALSE
            ) +
            ggplot2::geom_rect(
              data = data_rects,
              mapping = ggplot2::aes(
                xmin = x_min,
                xmax = x_max,
                ymin = y_min,
                ymax = y_max,
                fill = assoc_pct
              ),
              alpha = 0.75,
              colour = "white",
              linewidth = 0.2
            )

          # Add cores if available for this scale × continent
          if (has_cores) {
            panel <-
              panel +
              ggplot2::geom_point(
                data = data_cores,
                mapping = ggplot2::aes(
                  x = coord_long,
                  y = coord_lat
                ),
                size = 0.4,
                colour = "black",
                alpha = 0.5,
                inherit.aes = FALSE
              )
          }

          # coord_sf must be the final layer: geom_sf() adds its
          #   own coord_sf automatically, and ggplot2 applies the
          #   last added coord. Placing coord_sf here ensures the
          #   continent-specific xlim/ylim wins.
          panel <-
            panel +
            ggplot2::coord_sf(
              xlim = xlim_val,
              ylim = ylim_val,
              default_crs = sf::st_crs(4326),
              expand = FALSE
            )

          panel
        }
      ) |>
        rlang::set_names(vec_scales)
    }
  ) |>
  rlang::set_names(vec_continents)


#----------------------------------------------------------#
# 7. Assemble and save continent figures -----
#----------------------------------------------------------#

purrr::iwalk(
  .x = list_panels,
  .f = \(panels, sel_continent) {

    # Extract shared colour legend from the continental panel
    #   (all three panels share the same fill scale 0-100%)
    legend_shared <-
      cowplot::get_legend(
        panels[["continental"]]
      )

    # Remove legend from all individual panels before
    #   combining — legend is shown once at the right
    panels_no_legend <-
      purrr::map(
        .x = panels,
        .f = ~ .x +
          ggplot2::theme(legend.position = "none")
      )

    # Combine three scale panels + shared legend in one row
    fig_continent <-
      cowplot::plot_grid(
        panels_no_legend[["continental"]],
        panels_no_legend[["regional"]],
        panels_no_legend[["local"]],
        legend_shared,
        nrow = 1,
        rel_widths = c(1, 1, 1, 0.3),
        align = "hv",
        axis = "tb"
      )

    ggview::save_ggplot(
      plot = fig_continent,
      file = base::file.path(
        path_output,
        paste0(
          "Map_anova_associations_",
          sel_continent, "_",
          tag_date, ".png"
        )
      ),
      width = graphical_options[["width"]] * 3.3,
      height = graphical_options[["height"]],
      units = graphical_options[["units"]],
      dpi = graphical_options[["dpi"]],
      bg = graphical_options[["bg"]]
    )
  }
)
