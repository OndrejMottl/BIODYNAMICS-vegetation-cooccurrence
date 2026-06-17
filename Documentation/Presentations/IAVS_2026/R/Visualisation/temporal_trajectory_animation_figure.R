#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Slide 11 temporal trajectory animation helper
#
#----------------------------------------------------------#

library(here)

base::source(
  here::here("R", "___setup_project___.R")
)


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

list_oracle_design <-
  load_design_config(
    path = here::here(
      "Documentation",
      "Presentations",
      "IAVS_2026",
      "design_config.json"
    )
  )

vec_oracle_palette <-
  list_oracle_design |>
  purrr::chuck(
    "config",
    "palette"
  )

vec_font_match <-
  stringr::str_match(
    string = purrr::chuck(
      list_oracle_design,
      "config",
      "typography",
      "body_family"
    ),
    pattern = "'([^']+)'"
  )

font_family <-
  vec_font_match[1, 2]

path_font <-
  here::here(
    "Documentation",
    "Presentations",
    "IAVS_2026",
    "fonts",
    "VT323-Regular.ttf"
  )

if (
  !base::file.exists(path_font)
) {
  cli::cli_abort(
    c(
      "The VT323 font file is missing.",
      "i" = "Expected path: {.path {path_font}}."
    )
  )
}

try(
  systemfonts::register_font(
    name = font_family,
    plain = path_font
  ),
  silent = TRUE
)

path_output <-
  here::here(
    "Documentation",
    "Presentations",
    "IAVS_2026",
    "figures",
    "results"
  )

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)

vec_required_components <-
  base::c(
    "Spatial",
    "Abiotic",
    "Associations"
  )

vec_component_labels <-
  base::c(
    "Spatial" = "Space",
    "Abiotic" = "Abiotic",
    "Associations" = "Associations"
  )

vec_component_colours <-
  base::c(
    "Spatial" = base::unname(vec_oracle_palette[["cyan"]]),
    "Abiotic" = base::unname(vec_oracle_palette[["amber"]]),
    "Associations" = base::unname(vec_oracle_palette[["purple"]])
  )

colour_modularity <-
  base::unname(vec_oracle_palette[["phosphor"]])


#----------------------------------------------------------#
# 1. Load temporal results -----
#----------------------------------------------------------#

load_slide_temporal_inventory <- function() {
  data_continents <-
    load_continental_rows(
      path_spatial_grid = here::here("Data/Input/spatial_grid.csv")
    ) |>
    dplyr::select(scale_id) |>
    dplyr::mutate(
      store_path = here::here(
        stringr::str_glue(
          "Data/targets/paleo_temporal_",
          "{scale_id}/pipeline_paleo_temporal/"
        )
      ),
      store_exists = fs::dir_exists(.data$store_path),
      continent_label = stringr::str_to_title(.data$scale_id)
    )

  res_inventory <-
    data_continents |>
    dplyr::filter(.data$store_exists) |>
    dplyr::select(
      "scale_id",
      "continent_label",
      "store_path"
    )

  if (
    base::nrow(res_inventory) == 0L
  ) {
    cli::cli_abort(
      c(
        "No temporal target stores found.",
        "i" = "Run at least one 0*_Run_temporal_*.R script first."
      )
    )
  }

  return(res_inventory)
}

load_slide_temporal_components <- function(data_inventory) {
  data_anova_all <-
    data_inventory |>
    purrr::pmap(
      .f = function(scale_id, continent_label, store_path) {
        targets::tar_read(
          name = "data_anova_components_by_age_percentage",
          store = store_path
        ) |>
          dplyr::mutate(continent = continent_label)
      }
    ) |>
    purrr::list_rbind()

  vec_expected_columns <-
    base::c(
      "age",
      "continent",
      "component",
      "R2_Nagelkerke_percentage"
    )

  assertthat::assert_that(
    base::all(vec_expected_columns %in% base::colnames(data_anova_all)),
    msg = stringr::str_c(
      "The temporal ANOVA target must contain columns: ",
      stringr::str_c(vec_expected_columns, collapse = ", "),
      "."
    )
  )

  vec_continent_order <-
    base::c(
      "America",
      "Europe",
      "Asia"
    )

  res_components <-
    data_anova_all |>
    dplyr::filter(
      .data$component %in% vec_required_components,
      base::is.finite(.data$R2_Nagelkerke_percentage)
    ) |>
    dplyr::mutate(
      age = base::as.numeric(.data$age),
      continent = base::factor(
        .data$continent,
        levels = vec_continent_order
      ),
      component = base::factor(
        .data$component,
        levels = vec_required_components
      ),
      component_percentage = base::pmax(
        .data$R2_Nagelkerke_percentage,
        0
      )
    ) |>
    dplyr::select(
      "age",
      "continent",
      "component",
      "component_percentage"
    ) |>
    dplyr::arrange(
      .data$continent,
      dplyr::desc(.data$age),
      .data$component
    )

  if (
    base::nrow(res_components) == 0L
  ) {
    cli::cli_abort(
      "No finite temporal variance components were found."
    )
  }

  return(res_components)
}

load_slide_temporal_modularity <- function(data_inventory) {
  data_network_all <-
    data_inventory |>
    purrr::pmap(
      .f = function(scale_id, continent_label, store_path) {
        targets::tar_read(
          name = "data_network_metrics_by_age",
          store = store_path
        ) |>
          dplyr::mutate(
            age = stringr::str_extract(
              string = .data$age,
              pattern = "\\d+$"
            ) |>
              base::as.numeric(),
            continent = continent_label
          )
      }
    ) |>
    purrr::list_rbind()

  vec_continent_order <-
    base::c(
      "America",
      "Europe",
      "Asia"
    )

  res_modularity <-
    data_network_all |>
    dplyr::filter(
      .data$metric == "modularity Q",
      base::is.finite(.data$value)
    ) |>
    dplyr::mutate(
      continent = base::factor(
        .data$continent,
        levels = vec_continent_order
      ),
      modularity_q = base::pmin(base::pmax(.data$value, 0), 1)
    ) |>
    dplyr::select(
      "age",
      "continent",
      "modularity_q"
    ) |>
    dplyr::arrange(
      .data$continent,
      dplyr::desc(.data$age)
    )

  if (
    base::nrow(res_modularity) == 0L
  ) {
    cli::cli_abort(
      "No finite modularity Q values were found."
    )
  }

  return(res_modularity)
}

if (
  !base::exists("data_slide_11_temporal_inventory")
) {
  data_slide_11_temporal_inventory <-
    load_slide_temporal_inventory()
}

if (
  !base::exists("data_slide_11_temporal_components")
) {
  data_slide_11_temporal_components <-
    load_slide_temporal_components(
      data_inventory = data_slide_11_temporal_inventory
    )
}

if (
  !base::exists("data_slide_11_temporal_modularity")
) {
  data_slide_11_temporal_modularity <-
    load_slide_temporal_modularity(
      data_inventory = data_slide_11_temporal_inventory
    )
}

get_temporal_components_for_continent <- function(continent_label) {
  res_components <-
    data_slide_11_temporal_components |>
    dplyr::filter(
      .data$continent == .env$continent_label
    )

  if (
    base::nrow(res_components) == 0L
  ) {
    cli::cli_abort(
      c(
        "No temporal ANOVA data found for continent.",
        "i" = "Requested continent: {.val {continent_label}}."
      )
    )
  }

  return(res_components)
}

get_temporal_modularity_for_continent <- function(continent_label) {
  res_modularity <-
    data_slide_11_temporal_modularity |>
    dplyr::filter(
      .data$continent == .env$continent_label
    )

  if (
    base::nrow(res_modularity) == 0L
  ) {
    cli::cli_abort(
      c(
        "No temporal modularity Q data found for continent.",
        "i" = "Requested continent: {.val {continent_label}}."
      )
    )
  }

  return(res_modularity)
}


#----------------------------------------------------------#
# 2. Generate slide outputs -----
#----------------------------------------------------------#


save_temporal_trajectory_animation(
  continent_label = "America",
  data_temporal_components = get_temporal_components_for_continent(
    "America"
  ),
  data_temporal_modularity = get_temporal_modularity_for_continent(
    "America"
  ),
  output_file_name = "slide_11_temporal_trajectory_na.gif",
  frame_directory_name = "slide_11_temporal_trajectory_na",
  path_output = path_output,
  vec_component_colours = vec_component_colours,
  colour_modularity = colour_modularity,
  vec_palette = vec_oracle_palette,
  font_family = font_family
)

save_temporal_trajectory_animation(
  continent_label = "Europe",
  data_temporal_components = get_temporal_components_for_continent(
    "Europe"
  ),
  data_temporal_modularity = get_temporal_modularity_for_continent(
    "Europe"
  ),
  output_file_name = "slide_11_temporal_trajectory_eu.gif",
  frame_directory_name = "slide_11_temporal_trajectory_eu",
  path_output = path_output,
  vec_component_colours = vec_component_colours,
  colour_modularity = colour_modularity,
  vec_palette = vec_oracle_palette,
  font_family = font_family
)

save_temporal_trajectory_animation(
  continent_label = "Asia",
  data_temporal_components = get_temporal_components_for_continent(
    "Asia"
  ),
  data_temporal_modularity = get_temporal_modularity_for_continent(
    "Asia"
  ),
  output_file_name = "slide_11_temporal_trajectory_asia.gif",
  frame_directory_name = "slide_11_temporal_trajectory_asia",
  path_output = path_output,
  vec_component_colours = vec_component_colours,
  colour_modularity = colour_modularity,
  vec_palette = vec_oracle_palette,
  font_family = font_family
)

# Save legend as static image
ggview::save_ggplot(
  plot = build_temporal_trajectory_legend(
    vec_required_components = vec_required_components,
    vec_component_labels = vec_component_labels,
    vec_component_colours = vec_component_colours,
    colour_modularity = colour_modularity,
    vec_palette = vec_oracle_palette,
    font_family = font_family
  ),
  file = base::file.path(
    path_output,
    "slide_11_temporal_trajectory_legend.png"
  ),
  device = ragg::agg_png
)
