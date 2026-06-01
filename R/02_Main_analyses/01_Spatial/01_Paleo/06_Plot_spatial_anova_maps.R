#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Plot spatial ANOVA association maps
#              - one figure per continent (Europe,
#                Americas, Asia)
#              - 3x3 grid per figure:
#                rows = spatial scale (continental,
#                regional, local)
#                columns = taxonomic resolution
#                (genus, family, functional type)
#              - rectangles coloured by % Associations
#              - fossil cores overlaid as points
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Loads ANOVA results from all spatial pipeline stores and
#   produces one output figure per continent. Each figure
#   is a 3 x 3 grid where rows are spatial scale
#   (continental / regional / local) and columns are
#   taxonomic resolution (genus / family / functional
#   type). Rectangles are coloured by the Shapley-adjusted
#   % variance explained by Associations (viridis
#   gradient, grey when no results). Fossil core locations
#   are overlaid as points extracted from per-unit
#   data_coords targets.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

base::source(
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

tag_date <-
  base::format(base::Sys.Date(), "%Y-%m-%d")


#----------------------------------------------------------#
# 1. Load spatial grid and stores -----
#----------------------------------------------------------#

data_store_index <-
  build_spatial_model_store_index(
    data_source = "paleo",
    path_spatial_grid = here::here("Data/Input/spatial_grid.csv")
  )

data_spatial_grid <-
  data_store_index |>
  dplyr::left_join(
    y = readr::read_csv(
      file = here::here("Data/Input/spatial_grid.csv"),
      show_col_types = FALSE
    ) |>
      dplyr::select(
        scale_id,
        continent_id,
        x_min,
        x_max,
        y_min,
        y_max
      ),
    by = dplyr::join_by(scale_id),
    multiple = "error"
  ) |>
  dplyr::mutate(
    continent = .data$continent_id
  )


#----------------------------------------------------------#
# 2. Extract recalculated ANOVA % Associations -----
#----------------------------------------------------------#

vec_tax_res <-
  c("genus", "family", "functional_type") |>
  rlang::set_names()

data_assoc_pct <-
  read_spatial_model_results(
    store_index = data_store_index,
    resolution_ids = vec_tax_res
  ) |>
  dplyr::filter(
    .data$component == "Associations"
  ) |>
  dplyr::mutate(
    continent = get_continent_id_from_scale_id(
      scale_id = .data$scale_id,
      file = here::here("Data/Input/spatial_grid.csv")
    )
  ) |>
  dplyr::select(
    scale_id,
    continent,
    taxonomic_resolution = resolution_id,
    assoc_pct = R2_Nagelkerke_percentage
  )

data_grid_with_results <-
  data_spatial_grid |>
  dplyr::left_join(
    data_assoc_pct,
    by = dplyr::join_by(scale_id, continent)
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

vec_res_labels <-
  c(
    "genus" = "Genus",
    "family" = "Family",
    "functional_type" = "Functional type"
  )

vec_continents <-
  c("europe", "america", "asia")

vec_scales <-
  c("continental", "regional", "local")

vec_resolutions <-
  c("genus", "family", "functional_type")


#----------------------------------------------------------#
# 6. Build panel list -----
#----------------------------------------------------------#

# Build nested list:
#   list_panels[[continent]][[scale]][[resolution]]
list_panels <-
  vec_continents |>
  rlang::set_names() |>
  purrr::map(
    .f = ~ {
      sel_continent <- .x

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

      vec_scales |>
        rlang::set_names() |>
        purrr::map(
          .f = ~ {
            sel_scale <- .x
            vec_resolutions |>
              rlang::set_names() |>
              purrr::map(
                .f = ~ {
                  build_map_panel(
                    sel_continent = sel_continent,
                    sel_scale = sel_scale,
                    sel_resolution = .x,
                    xlim_val = xlim_val,
                    ylim_val = ylim_val,
                    data_grid_with_results = data_grid_with_results,
                    data_coords_per_unit = data_coords_per_unit,
                    sf_world = sf_world,
                    graphical_options = graphical_options,
                    show_x_axis = (sel_scale == "local"),
                    show_y_axis = (.x == "genus"),
                    col_label = if (sel_scale == "continental") {
                      vec_res_labels[[.x]]
                    } else {
                      NULL
                    },
                    row_label = if (.x == "genus") {
                      vec_scale_labels[[sel_scale]]
                    } else {
                      NULL
                    }
                  )
                }
              )
          }
        )
    }
  )


#----------------------------------------------------------#
# 7. Assemble and save continent figures (3 x 3 grid) -----
#----------------------------------------------------------#

# Layout: rows = scale (continental/regional/local)
#         columns = resolution (genus/family/functional type)
# One shared legend, one figure per continent.

list_panels |>
  purrr::iwalk(
    .f = ~ {
      panels_continent <- .x
      sel_continent <- .y

      # Extract shared colour legend from one panel
      #   (all panels share the same fill scale 0-100%)
      legend_shared <-
        cowplot::get_legend(
          panels_continent[["continental"]][["genus"]] +
            ggplot2::theme(
              legend.direction = "horizontal",
              legend.title = ggplot2::element_text(vjust = 0.8)
            ) +
            ggplot2::guides(
              fill = ggplot2::guide_colorbar(
                title.position = "top",
                barwidth = 20,
                barheight = 2
              )
            )
        )

      # Build flat list of 9 panels (row-major: scale outer,
      #   resolution inner) with legend stripped
      list_panels_flat <-
        vec_scales |>
        purrr::map(
          .f = ~ {
            sel_scale <- .x
            vec_resolutions |>
              purrr::map(
                .f = ~ {
                  panels_continent[[sel_scale]][[.x]] +
                    ggplot2::theme(legend.position = "none")
                }
              )
          }
        ) |>
        purrr::list_flatten()

      # 3 x 3 grid of map panels
      grid_panels <-
        cowplot::plot_grid(
          plotlist = list_panels_flat,
          nrow = 3,
          ncol = 3,
          align = "hv",
          axis = "tblr"
        )

      # Column and row labels are embedded in the panels;
      # attach legend on top.
      fig_continent <-
        cowplot::plot_grid(
          legend_shared,
          grid_panels,
          ncol = 1,
          rel_heights = c(0.06, 1)
        )

      ggview::save_ggplot(
        plot = fig_continent,
        file = base::file.path(
          path_output,
          stringr::str_glue(
            "Map_anova_associations_{sel_continent}_{tag_date}.png"
          )
        ),
        width = graphical_options[["width"]] *
          graphical_options[["panel_scale"]],
        height = graphical_options[["height"]] *
          graphical_options[["panel_scale"]],
        units = graphical_options[["units"]],
        dpi = graphical_options[["dpi"]],
        bg = graphical_options[["bg"]]
      )
    }
  )
