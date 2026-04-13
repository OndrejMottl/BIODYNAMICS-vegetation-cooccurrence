#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#     Analyse Functional-Type Taxonomic Coherence
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# For each continent, joins the FT clustering results with
#    the full taxonomic hierarchy (class -> genus) and
#    computes "FT purity" — the proportion of taxa in a clade
#    assigned to the dominant FT.
#
# Hypothesis: purity increases as rank gets finer
#    (class -> order -> family -> genus), reflecting phylogenetic
#    signal in the trait-based clustering.
#
# Produces two output figures saved to Outputs/Figures/Traits/
#    1. plot_rank_purity.pdf  — violin + jitter of FT purity
#                               by taxonomic rank and continent
#    2. plot_order_heatmap.pdf — tile heatmap of FT composition
#                                for top-25 orders per continent


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

# Traits pipeline configuration
Sys.setenv(R_CONFIG_ACTIVE = "traits")

# Graphical options shared across all plots in this script.
graphical_options <-
  get_active_config("graphical")


#----------------------------------------------------------#
# 1. Settings -----
#----------------------------------------------------------#

vec_pipelines <- "pipeline_traits"

path_target_store <-
  here::here(
    stringr::str_glue(
      "{get_active_config('target_store')}/{vec_pipelines}/"
    )
  )

# Minimum number of taxa in a clade for purity to be computed.
# Clades with fewer taxa are dropped to avoid trivial purity = 1.
n_minimum_clade_size <- 3L

# Ranks to assess — kingdom and phylum excluded (too coarse).
vec_ranks <-
  base::c("class", "order", "family", "genus") |>
  forcats::fct_inorder()

# Top-n orders shown in the heatmap per continent.
n_top_order_count <- 25L


#----------------------------------------------------------#
# 2. Load data -----
#----------------------------------------------------------#


#--------------------------------------------------#
## 2.1. Taxonomic classification tables -----
#--------------------------------------------------#

data_combined_classification_table_traits <-
  targets::tar_read(
    name = "data_combined_classification_table_traits",
    store = path_target_store
  )

data_resolution_to_finest <-
  targets::tar_read(
    name = "data_resolution_to_finest",
    store = path_target_store
  )


#--------------------------------------------------#
## 2.2. FT classification files -----
#--------------------------------------------------#

vec_continent_ids <-
  load_continental_rows(
    path_spatial_grid = here::here("Data/Input/spatial_grid.csv")
  ) |>
  dplyr::pull(scale_id)

# Read the most recent saved FT classification for each continent,
# attach continent_id, and combine.
data_ft_all <-
  vec_continent_ids |>
  purrr::map(
    .f = ~ {
      get_functional_type_classification(
        continent_id = .x,
        path_processed = here::here("Data/Processed/Traits")
      ) |>
        dplyr::mutate(continent_id = .x)
    }
  ) |>
  purrr::list_rbind()


#----------------------------------------------------------#
# 3. Join taxonomy -----
#----------------------------------------------------------#

# FT classification files are keyed on resolved taxon names, not the
# original trait-taxonomy input names. Collapse the full classification
# table to one taxonomy row per resolved taxon before joining.
data_taxonomy_resolved <-
  data_resolution_to_finest |>
  dplyr::left_join(
    data_combined_classification_table_traits,
    by = dplyr::join_by(sel_name),
    relationship = "one-to-one"
  ) |>
  dplyr::group_by(taxon_resolved) |>
  dplyr::summarise(
    dplyr::across(
      dplyr::all_of(
        base::c(
          "kingdom",
          "phylum",
          "class",
          "order",
          "family",
          "genus",
          "species"
        )
      ),
      ~ {
        vec_values <-
          .x |>
          stats::na.omit() |>
          base::unique() |>
          base::as.character()

        if (
          base::length(vec_values) == 0L
        ) {
          return(NA_character_)
        }

        return(vec_values[[1L]])
      }
    ),
    .groups = "drop"
  ) |>
  dplyr::rename(taxon_name = taxon_resolved)

# Left-join so taxa without a taxonomy row are kept
# (they will be filtered out by tidyr::drop_na() per rank).
data_ft_classified <-
  data_ft_all |>
  dplyr::left_join(
    data_taxonomy_resolved,
    by = dplyr::join_by(taxon_name),
    relationship = "many-to-one"
  )


#----------------------------------------------------------#
# 4. Compute FT purity per rank -----
#----------------------------------------------------------#

# For each rank: proportion of taxa in the dominant FT within
# each clade. Only clades with >= n_min_clade_size are kept.

data_purity <-
  base::as.character(vec_ranks) |>
  purrr::map(
    .f = ~ data_ft_classified |>
      tidyr::drop_na(
        dplyr::all_of(base::c("functional_type", .x))
      ) |>
      dplyr::group_by(
        continent_id,
        dplyr::across(dplyr::all_of(.x)),
        functional_type
      ) |>
      dplyr::summarise(
        n = dplyr::n(),
        .groups = "drop"
      ) |>
      dplyr::group_by(
        continent_id,
        dplyr::across(dplyr::all_of(.x))
      ) |>
      dplyr::mutate(
        n_total = base::sum(n),
        prop = n / n_total
      ) |>
      dplyr::summarise(
        dominant_ft_prop = base::max(prop),
        n_taxa = dplyr::first(n_total),
        n_ft = dplyr::n_distinct(functional_type),
        .groups = "drop"
      ) |>
      dplyr::filter(n_taxa >= n_minimum_clade_size) |>
      dplyr::rename(clade_name = dplyr::all_of(.x)) |>
      dplyr::mutate(rank = .x)
  ) |>
  purrr::list_rbind() |>
  dplyr::mutate(
    rank = forcats::fct_relevel(
      rank,
      base::as.character(vec_ranks)
    )
  )


#----------------------------------------------------------#
# 5. Build order FT composition (heatmap data) -----
#----------------------------------------------------------#

# Proportion of taxa per order assigned to each FT.
# Only the top-n orders per continent by total taxon count.

data_top_orders <-
  data_ft_classified |>
  tidyr::drop_na(
    order,
    functional_type
  ) |>
  dplyr::group_by(
    continent_id,
    order
  ) |>
  dplyr::summarise(
    n_total = dplyr::n(),
    .groups = "drop"
  ) |>
  dplyr::group_by(continent_id) |>
  dplyr::slice_max(
    order_by = n_total,
    n = n_top_order_count,
    with_ties = FALSE
  ) |>
  dplyr::ungroup()

data_order_heatmap <-
  data_ft_classified |>
  tidyr::drop_na(
    order,
    functional_type
  ) |>
  dplyr::semi_join(
    data_top_orders,
    by = dplyr::join_by(
      continent_id,
      order
    )
  ) |>
  dplyr::group_by(
    continent_id,
    order,
    functional_type
  ) |>
  dplyr::summarise(
    n = dplyr::n(),
    .groups = "drop"
  ) |>
  dplyr::group_by(
    continent_id,
    order
  ) |>
  dplyr::mutate(
    n_total = base::sum(n),
    prop = n / n_total,
    # Order by the FT with the highest proportion (dominant FT)
    dominant_ft = functional_type[base::which.max(prop)]
  ) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    order = forcats::fct_reorder(
      order,
      dominant_ft
    )
  )


#----------------------------------------------------------#
# 6. Visualise -----
#----------------------------------------------------------#


#--------------------------------------------------#
## 6.1. Figure 1 — Rank purity -----
#--------------------------------------------------#

# Expected pattern: purity increases class -> genus,
# reflecting phylogenetic signal in the trait-based clusters.

plot_rank_purity <-
  data_purity |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = rank,
      y = dominant_ft_prop
    )
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(continent_id),
    nrow = 1L
  ) +
  ggplot2::scale_x_discrete(
    name = "Taxonomic rank"
  ) +
  ggplot2::scale_y_continuous(
    name = "FT purity (dominant-FT proportion)",
    limits = base::c(0, 1),
    breaks = base::seq(
      0,
      1,
      by = 0.25
    )
  ) +
  ggplot2::scale_colour_viridis_c(
    name = "Clade size\n(log\u2081\u2080 taxa)",
    option = "viridis",
    trans = "log10"
  ) +
  ggplot2::labs(
    title = "Functional-type purity by taxonomic rank",
    subtitle = stringr::str_glue(
      "Clades with \u2265 {n_minimum_clade_size} taxa only"
    )
  ) +
  ggplot2::theme_classic() +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  ) +
  ggplot2::geom_violin(
    fill = "grey90",
    colour = "grey60",
    linewidth = 0.4,
    na.rm = TRUE
  ) +
  ggplot2::geom_jitter(
    mapping = ggplot2::aes(colour = n_taxa),
    width = 0.15,
    height = 0,
    size = 1.5,
    alpha = 0.7,
    na.rm = TRUE
  )


#--------------------------------------------------#
## 6.2. Figure 2 — Order FT heatmap -----
#--------------------------------------------------#

# Rows = orders (top-25 per continent, sorted by dominant FT).
# Columns = functional type (integer label, continent-specific).
# Fill = proportion of taxa assigned to that FT.

plot_order_heatmap <-
  data_order_heatmap |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = base::as.factor(functional_type),
      y = order,
      fill = prop
    )
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(continent_id),
    scales = "free_y",
    nrow = 1L
  ) +
  ggplot2::scale_fill_viridis_c(
    name = "Proportion\nof taxa",
    option = "plasma",
    limits = base::c(0, 1),
    breaks = base::seq(
      0,
      1,
      by = 0.25
    )
  ) +
  ggplot2::scale_x_discrete(
    name = "Functional type (continent-specific integer label)"
  ) +
  ggplot2::scale_y_discrete(
    name = "Order"
  ) +
  ggplot2::labs(
    title = stringr::str_glue(
      "FT composition of top-{n_top_order_count} orders per continent"
    ),
    subtitle = "Rows ordered by dominant functional type within continent"
  ) +
  ggplot2::theme_classic() +
  ggplot2::theme(
    axis.text.y = ggplot2::element_text(size = 6L)
  ) +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]],
    dpi = graphical_options[["dpi"]],
    bg = graphical_options[["bg"]]
  ) +
  ggplot2::geom_tile(
    colour = "white",
    linewidth = 0.2
  )


#----------------------------------------------------------#
# 7. Save figures -----
#----------------------------------------------------------#

path_output_directory <-
  here::here("Outputs/Figures/Traits")

fs::dir_create(
  path_output_directory,
  recurse = TRUE
)

ggview::save_ggplot(
  plot = plot_rank_purity,
  file = base::file.path(
    path_output_directory,
    "plot_rank_purity.pdf"
  )
)

ggview::save_ggplot(
  plot = plot_order_heatmap,
  file = base::file.path(
    path_output_directory,
    "plot_order_heatmap.pdf"
  )
)
