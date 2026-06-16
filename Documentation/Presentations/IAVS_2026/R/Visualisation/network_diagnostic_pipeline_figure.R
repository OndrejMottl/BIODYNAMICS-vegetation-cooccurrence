#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Europe time-slice bipartite network figure
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

path_to_vegvault <-
  here::here("Data", "Input", "VegVault.sqlite")

flag_vegvault_present <-
  check_presence_of_vegvault(path_to_vegvault)

if (
  isFALSE(flag_vegvault_present)
) {
  cli::cli_abort(
    c(
      "VegVault database not found at expected path.",
      "i" = "Expected path: {.path {path_to_vegvault}}."
    )
  )
}

selected_age <- 2000
time_step <- 500
slice_half_width <- time_step / 2

list_europe_config <-
  config::get(
    value = "vegvault_data",
    config = "project_paleo_temporal_europe",
    file = here::here("config.yml")
  )

x_min <- purrr::chuck(list_europe_config, "x_lim", 1)
x_max <- purrr::chuck(list_europe_config, "x_lim", 2)
y_min <- purrr::chuck(list_europe_config, "y_lim", 1)
y_max <- purrr::chuck(list_europe_config, "y_lim", 2)
age_min <- selected_age - slice_half_width
age_max <- selected_age + slice_half_width


#----------------------------------------------------------#
# 1. Extract time-slice sample-taxon links -----
#----------------------------------------------------------#

data_sample_taxa <-
  local({
    con <-
      DBI::dbConnect(
        RSQLite::SQLite(),
        path_to_vegvault
      )

    base::on.exit(
      if (
        DBI::dbIsValid(con)
      ) {
        DBI::dbDisconnect(con)
      },
      add = TRUE
    )

    query_sample_taxa <-
      stringr::str_glue(
        "
          select
            d.dataset_name,
            s.sample_id,
            s.sample_name,
            s.age,
            t.taxon_name,
            st.value
          from Datasets d
          inner join DatasetSample ds
            on d.dataset_id = ds.dataset_id
          inner join Samples s
            on ds.sample_id = s.sample_id
          inner join SampleTaxa st
            on s.sample_id = st.sample_id
          inner join Taxa t
            on st.taxon_id = t.taxon_id
          left join DatasetTypeID dti
            on d.dataset_type_id = dti.dataset_type_id
          where d.coord_long >= {x_min}
            and d.coord_long <= {x_max}
            and d.coord_lat >= {y_min}
            and d.coord_lat <= {y_max}
            and s.age >= {age_min}
            and s.age < {age_max}
            and st.value > 0
            and dti.dataset_type = 'fossil_pollen_archive'
        "
      )

    res_sample_taxa <-
      DBI::dbGetQuery(
        conn = con,
        statement = query_sample_taxa
      ) |>
      tibble::as_tibble()

    res_sample_taxa
  })

if (
  base::nrow(data_sample_taxa) == 0L
) {
  cli::cli_abort("No Europe sample-taxon links found for the slice.")
}

data_network_edges_all <-
  data_sample_taxa |>
  dplyr::group_by(dataset_name, taxon_name) |>
  dplyr::summarise(
    link_weight = base::sum(value, na.rm = TRUE),
    .groups = "drop"
  )

vec_selected_taxa <-
  data_network_edges_all |>
  dplyr::count(taxon_name, name = "core_count", sort = TRUE) |>
  dplyr::slice_head(n = 26L) |>
  dplyr::pull(taxon_name)

vec_selected_cores <-
  data_network_edges_all |>
  dplyr::filter(
    taxon_name %in% vec_selected_taxa
  ) |>
  dplyr::count(dataset_name, name = "taxon_count", sort = TRUE) |>
  dplyr::slice_head(n = 28L) |>
  dplyr::pull(dataset_name)

data_network_edges <-
  data_network_edges_all |>
  dplyr::filter(
    taxon_name %in% vec_selected_taxa,
    dataset_name %in% vec_selected_cores
  )

data_taxon_nodes <-
  data_network_edges |>
  dplyr::count(taxon_name, name = "core_count", sort = TRUE) |>
  dplyr::mutate(
    node_id = taxon_name,
    node_type = "taxon",
    commonness = core_count,
    x = base::seq(
      from = 4,
      to = 96,
      length.out = dplyr::n()
    ),
    y = 86,
    label = stringr::str_trunc(taxon_name, width = 13)
  ) |>
  dplyr::select(node_id, node_type, x, y, label, commonness, core_count)

data_core_nodes <-
  data_network_edges |>
  dplyr::count(dataset_name, name = "taxon_count", sort = TRUE) |>
  dplyr::mutate(
    node_id = dataset_name,
    node_type = "core",
    commonness = taxon_count,
    x = base::seq(
      from = 4,
      to = 96,
      length.out = dplyr::n()
    ),
    y = 14,
    label = stringr::str_glue(
      "core {stringr::str_pad(dplyr::row_number(), 2, pad = '0')}"
    )
  ) |>
  dplyr::select(node_id, node_type, x, y, label, commonness, taxon_count)

data_edge_plot <-
  data_network_edges |>
  dplyr::inner_join(
    data_taxon_nodes |>
      dplyr::select(taxon_name = node_id, x_taxon = x, y_taxon = y),
    by = dplyr::join_by(taxon_name)
  ) |>
  dplyr::inner_join(
    data_core_nodes |>
      dplyr::select(dataset_name = node_id, x_core = x, y_core = y),
    by = dplyr::join_by(dataset_name)
  ) |>
  dplyr::mutate(
    link_alpha = scales::rescale(
      link_weight,
      to = base::c(0.12, 0.55)
    )
  )

data_nodes <-
  dplyr::bind_rows(
    data_taxon_nodes |>
      dplyr::mutate(
        colour = vec_oracle_palette[["purple"]]
      ),
    data_core_nodes |>
      dplyr::mutate(
        colour = vec_oracle_palette[["phosphor"]]
      )
  ) |>
  dplyr::mutate(
    node_size = scales::rescale(
      commonness,
      to = base::c(0.5, 3)
    ),
    by = node_type
  )


#----------------------------------------------------------#
# 2. Make figure -----
#----------------------------------------------------------#

figure_network_pipeline <-
  ggplot2::ggplot() +
  ggplot2::coord_cartesian(
    xlim = base::c(0, 100),
    ylim = base::c(0, 100),
    expand = FALSE,
    clip = "off"
  ) +
  ggplot2::scale_colour_identity() +
  ggplot2::scale_alpha_identity() +
  ggplot2::scale_size_identity() +
  ggview::canvas(
    width = 800,
    height = 600,
    units = "px",
    dpi = 300,
    bg = vec_oracle_palette[["background"]]
  ) +
  theme_oracle(base_family = font_family, base_size = 9) +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    panel.background = ggplot2::element_rect(
      fill = vec_oracle_palette[["background"]],
      colour = NA
    ),
    panel.grid = ggplot2::element_blank(),
    panel.grid.major = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank(),
    axis.text = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    plot.margin = ggplot2::margin(8, 6, 8, 6)
  ) +
  ggplot2::geom_curve(
    data = data_edge_plot,
    mapping = ggplot2::aes(
      x = x_core,
      y = y_core,
      xend = x_taxon,
      yend = y_taxon,
      alpha = link_alpha
    ),
    colour = vec_oracle_palette[["muted"]],
    linewidth = 0.18,
    curvature = 0.04
  ) +
  ggplot2::geom_point(
    data = data_nodes  |> 
    dplyr::filter(node_type == "core"),
    mapping = ggplot2::aes(
      x = x,
      y = y,
      colour = colour,
      size = node_size
    ),
    shape = 15
  ) +
    ggplot2::geom_point(
    data = data_nodes  |> 
    dplyr::filter(node_type == "taxon"),
    mapping = ggplot2::aes(
      x = x,
      y = y,
      colour = colour,
      size = node_size
    ),
    shape = 16
  ) +
  ggplot2::annotate(
    geom = "text",
    x = 2,
    y = 94,
    label = stringr::str_glue(
      "TAXA // n = {base::length(vec_selected_taxa)}"
    ),
    hjust = 0,
    colour = vec_oracle_palette[["purple"]],
    family = font_family,
    fontface = "bold",
    size = 3
  ) +
  ggplot2::annotate(
    geom = "text",
    x = 98,
    y = 4,
    label = stringr::str_glue(
      "CORES // n = {base::length(vec_selected_cores)}"
    ),
    hjust = 1,
    colour = vec_oracle_palette[["phosphor"]],
    family = font_family,
    fontface = "bold",
    size = 3.0
  ) +
  ggplot2::annotate(
    geom = "text",
    x = 2,
    y = 4,
    label = stringr::str_glue(
      "EU : {selected_age} yr BP"
    ),
    hjust = 0,
    colour = vec_oracle_palette[["red"]],
    family = font_family,
    fontface = "bold",
    size = 3.0
  )

#----------------------------------------------------------#
# 3. Save figure -----
#----------------------------------------------------------#

ggview::save_ggplot(
  plot = figure_network_pipeline,
  file = base::file.path(
    path_output,
    "slide_10_network_example.png"
  ),
  device = ragg::agg_png
)
