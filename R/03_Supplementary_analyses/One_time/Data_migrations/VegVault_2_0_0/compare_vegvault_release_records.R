#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#     Compare the records of VegVault 1.0.0 and 2.0.0
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Read-only comparison of the VegVault 2.0.0 migration (Stage V, step V5).
# For each continental window of spatial_grid.csv (the temporal profiles
#   use the same windows) and each data type, it counts with the same SQL
#   in both releases:
#   - datasets, samples and taxa, separating records that carry a value
#     from records without one: vaultkeepr::extract_data() drops records
#     without a value, so only the former reach the pipelines;
#   - trait datasets, trait values and taxa per source type (TRY, BIEN),
#     and trait datasets without coordinates;
#   - fossil-pollen cores with a sample at 0 cal yr BP. Extraction keeps
#     ages from 0 and the interpolation does not extrapolate, so only
#     these cores give a sample at the 0 ka slice.
# It draws one figure: the change of the counts that reach the pipelines.
# Inputs: Data/Input/VegVault.sqlite (2.0.0) and
#   Data/Input/VegVault_1.0.0.sqlite, opened read-only; the continental
#   rows of Data/Input/spatial_grid.csv; the extraction settings of the
#   main continental profiles.
# Outputs (Documentation/Reports/Model_evaluation/
#   vegvault_2_migration_2026-11/):
#   - release_window_counts.csv
#   - release_trait_sources.csv
#   - release_fossil_cores_at_0_ka.csv
#   - release_window_counts.png


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

suppressMessages(
  suppressWarnings(
    source(
      here::here("R/___setup_project___.R")
    )
  )
)

list_release_paths <-
  base::list(
    "1.0.0" = here::here("Data/Input/VegVault_1.0.0.sqlite"),
    "2.0.0" = here::here("Data/Input/VegVault.sqlite")
  )

file_spatial_grid <-
  here::here("Data/Input/spatial_grid.csv")

dir_output <-
  here::here(
    "Documentation/Reports/Model_evaluation/vegvault_2_migration_2026-11"
  )

# Community data types and the main continental profiles whose
#   extraction settings they use
vec_community_profiles <-
  base::c(
    fossil_pollen_archive = "project_paleo_spatial_continental",
    vegetation_plot = "project_modern_spatial_continental"
  )

graphical_options <-
  load_config_value(
    config_id = "default",
    value = "graphical"
  )

assertthat::assert_that(
  base::all(
    purrr::map_lgl(.x = list_release_paths, .f = base::file.exists)
  ),
  base::dir.exists(dir_output),
  msg = "Both VegVault files and the evidence folder must exist."
)


#----------------------------------------------------------#
# 1. Inputs -----
#----------------------------------------------------------#

data_continental_windows <-
  readr::read_csv(
    file = file_spatial_grid,
    show_col_types = FALSE
  ) |>
  dplyr::filter(.data[["scale"]] == "continental") |>
  dplyr::select(
    "continent_id", "x_min", "x_max", "y_min", "y_max"
  )

data_community_settings <-
  tibble::tibble(
    data_type = base::names(vec_community_profiles),
    config_id = base::unname(vec_community_profiles)
  ) |>
  dplyr::mutate(
    age_lim = purrr::map(
      .x = config_id,
      .f = ~ load_config_value(
        config_id = .x,
        value = base::c("vegvault_data", "age_lim")
      )
    ),
    age_min = purrr::map_dbl(.x = age_lim, .f = ~ .x[1]),
    age_max = purrr::map_dbl(.x = age_lim, .f = ~ .x[2])
  ) |>
  dplyr::select("data_type", "age_min", "age_max")


#----------------------------------------------------------#
# 2. Queries -----
#----------------------------------------------------------#
# The same statements run on both files. Windows and ages are inclusive,
#   as in vaultkeepr::select_dataset_by_geo() and select_samples_by_age().

query_community_counts <-
  stringr::str_c(
    "WITH sel AS (",
    " SELECT d.dataset_id, s.sample_id",
    " FROM Datasets d",
    " JOIN DatasetTypeID dt ON d.dataset_type_id = dt.dataset_type_id",
    " JOIN DatasetSample ds ON d.dataset_id = ds.dataset_id",
    " JOIN Samples s ON ds.sample_id = s.sample_id",
    " WHERE dt.dataset_type = ?",
    " AND d.coord_long BETWEEN ? AND ? AND d.coord_lat BETWEEN ? AND ?",
    " AND s.age BETWEEN ? AND ?),",
    " valued AS (",
    " SELECT sel.dataset_id, sel.sample_id, sx.taxon_id",
    " FROM sel JOIN SampleTaxa sx ON sel.sample_id = sx.sample_id",
    " WHERE sx.value IS NOT NULL)",
    " SELECT",
    " (SELECT COUNT(DISTINCT dataset_id) FROM sel) AS n_datasets,",
    " (SELECT COUNT(DISTINCT sample_id) FROM sel) AS n_samples,",
    " (SELECT COUNT(DISTINCT dataset_id) FROM valued)",
    " AS n_datasets_with_values,",
    " (SELECT COUNT(DISTINCT sample_id) FROM valued)",
    " AS n_samples_with_values,",
    " (SELECT COUNT(DISTINCT t.taxon_name) FROM valued v",
    " JOIN Taxa t ON v.taxon_id = t.taxon_id) AS n_taxa_with_values"
  )

query_trait_window_counts <-
  stringr::str_c(
    "SELECT COUNT(DISTINCT d.dataset_id) AS n_datasets,",
    " COUNT(*) AS n_trait_values,",
    " COUNT(DISTINCT t.taxon_name) AS n_taxa",
    " FROM Datasets d",
    " JOIN DatasetTypeID dt ON d.dataset_type_id = dt.dataset_type_id",
    " JOIN TraitsValue tv ON tv.dataset_id = d.dataset_id",
    " JOIN Taxa t ON tv.taxon_id = t.taxon_id",
    " WHERE dt.dataset_type = 'traits'",
    " AND d.coord_long BETWEEN ? AND ? AND d.coord_lat BETWEEN ? AND ?",
    " AND tv.trait_value IS NOT NULL"
  )

query_trait_counts <-
  stringr::str_c(
    "SELECT st.dataset_source_type,",
    " COUNT(DISTINCT d.dataset_id) AS n_datasets,",
    " COUNT(*) AS n_trait_values,",
    " COUNT(DISTINCT t.taxon_name) AS n_taxa",
    " FROM Datasets d",
    " JOIN DatasetTypeID dt ON d.dataset_type_id = dt.dataset_type_id",
    " JOIN TraitsValue tv ON tv.dataset_id = d.dataset_id",
    " JOIN Taxa t ON tv.taxon_id = t.taxon_id",
    " LEFT JOIN DatasetSourceTypeID st",
    " ON d.data_source_type_id = st.data_source_type_id",
    " WHERE dt.dataset_type = 'traits'",
    " AND d.coord_long BETWEEN ? AND ? AND d.coord_lat BETWEEN ? AND ?",
    " AND tv.trait_value IS NOT NULL",
    " GROUP BY st.dataset_source_type"
  )

query_trait_datasets_without_coordinates <-
  stringr::str_c(
    "SELECT st.dataset_source_type,",
    " COUNT(*) AS n_datasets,",
    " SUM(d.coord_long IS NULL OR d.coord_lat IS NULL)",
    " AS n_datasets_without_coordinates",
    " FROM Datasets d",
    " JOIN DatasetTypeID dt ON d.dataset_type_id = dt.dataset_type_id",
    " LEFT JOIN DatasetSourceTypeID st",
    " ON d.data_source_type_id = st.data_source_type_id",
    " WHERE dt.dataset_type = 'traits'",
    " GROUP BY st.dataset_source_type"
  )

query_fossil_cores_at_0_ka <-
  stringr::str_c(
    "SELECT COUNT(DISTINCT d.dataset_id) AS n_cores",
    " FROM Datasets d",
    " JOIN DatasetTypeID dt ON d.dataset_type_id = dt.dataset_type_id",
    " JOIN DatasetSample ds ON d.dataset_id = ds.dataset_id",
    " JOIN Samples s ON ds.sample_id = s.sample_id",
    " WHERE dt.dataset_type = 'fossil_pollen_archive'",
    " AND d.coord_long BETWEEN ? AND ? AND d.coord_lat BETWEEN ? AND ?",
    " AND s.age = 0"
  )


#----------------------------------------------------------#
# 3. Counts per release -----
#----------------------------------------------------------#

list_release_counts <-
  list_release_paths |>
  purrr::imap(
    .f = ~ {
      sel_release <- .y

      cli::cli_inform("Counting records of VegVault {sel_release}.")

      connection_vegvault <-
        DBI::dbConnect(
          drv = RSQLite::SQLite(),
          dbname = .x,
          flags = RSQLite::SQLITE_RO
        )

      data_window_queries <-
        tidyr::expand_grid(
          data_continental_windows,
          data_community_settings
        )

      data_community_counts <-
        base::seq_len(base::nrow(data_window_queries)) |>
        purrr::map(
          .f = ~ {
            data_query <-
              data_window_queries |>
              dplyr::slice(.x)

            DBI::dbGetQuery(
              conn = connection_vegvault,
              statement = query_community_counts,
              params = base::list(
                dplyr::pull(data_query, "data_type"),
                dplyr::pull(data_query, "x_min"),
                dplyr::pull(data_query, "x_max"),
                dplyr::pull(data_query, "y_min"),
                dplyr::pull(data_query, "y_max"),
                dplyr::pull(data_query, "age_min"),
                dplyr::pull(data_query, "age_max")
              )
            ) |>
              tibble::as_tibble() |>
              dplyr::mutate(
                continent_id = dplyr::pull(data_query, "continent_id"),
                data_type = dplyr::pull(data_query, "data_type")
              )
          }
        ) |>
        purrr::list_rbind()

      list_trait_counts <-
        base::list(
          window = query_trait_window_counts,
          source = query_trait_counts
        ) |>
        purrr::map(
          .f = ~ {
            sel_query <- .x

            base::seq_len(base::nrow(data_continental_windows)) |>
              purrr::map(
                .f = ~ {
                  data_window <-
                    data_continental_windows |>
                    dplyr::slice(.x)

                  DBI::dbGetQuery(
                    conn = connection_vegvault,
                    statement = sel_query,
                    params = base::list(
                      dplyr::pull(data_window, "x_min"),
                      dplyr::pull(data_window, "x_max"),
                      dplyr::pull(data_window, "y_min"),
                      dplyr::pull(data_window, "y_max")
                    )
                  ) |>
                    tibble::as_tibble() |>
                    dplyr::mutate(
                      continent_id = dplyr::pull(
                        data_window,
                        "continent_id"
                      )
                    )
                }
              ) |>
              purrr::list_rbind()
          }
        )

      data_trait_coordinates <-
        DBI::dbGetQuery(
          conn = connection_vegvault,
          statement = query_trait_datasets_without_coordinates
        ) |>
        tibble::as_tibble()

      data_fossil_cores <-
        base::seq_len(base::nrow(data_continental_windows)) |>
        purrr::map(
          .f = ~ {
            data_window <-
              data_continental_windows |>
              dplyr::slice(.x)

            DBI::dbGetQuery(
              conn = connection_vegvault,
              statement = query_fossil_cores_at_0_ka,
              params = base::list(
                dplyr::pull(data_window, "x_min"),
                dplyr::pull(data_window, "x_max"),
                dplyr::pull(data_window, "y_min"),
                dplyr::pull(data_window, "y_max")
              )
            ) |>
              tibble::as_tibble() |>
              dplyr::mutate(
                continent_id = dplyr::pull(data_window, "continent_id")
              )
          }
        ) |>
        purrr::list_rbind()

      DBI::dbDisconnect(connection_vegvault)

      base::list(
        community = data_community_counts,
        traits_window = purrr::chuck(list_trait_counts, "window"),
        traits = purrr::chuck(list_trait_counts, "source"),
        trait_coordinates = data_trait_coordinates,
        fossil_cores = data_fossil_cores
      ) |>
        purrr::map(
          .f = ~ dplyr::mutate(.x, vegvault_version = sel_release)
        )
    }
  )


#----------------------------------------------------------#
# 4. Tables -----
#----------------------------------------------------------#

# For traits, samples stand for trait values; all counted values exist.
data_release_window_counts <-
  list_release_counts |>
  purrr::map(.f = ~ purrr::chuck(.x, "community")) |>
  purrr::list_rbind() |>
  dplyr::bind_rows(
    list_release_counts |>
      purrr::map(.f = ~ purrr::chuck(.x, "traits_window")) |>
      purrr::list_rbind() |>
      dplyr::mutate(
        data_type = "traits",
        n_datasets_with_values = .data[["n_datasets"]],
        n_samples_with_values = .data[["n_trait_values"]],
        n_taxa_with_values = .data[["n_taxa"]]
      ) |>
      dplyr::select(
        "vegvault_version", "continent_id", "data_type",
        "n_datasets", "n_datasets_with_values",
        "n_samples_with_values", "n_taxa_with_values"
      )
  ) |>
  dplyr::select(
    "continent_id", "data_type", "vegvault_version",
    "n_datasets", "n_samples",
    "n_datasets_with_values", "n_samples_with_values",
    "n_taxa_with_values"
  ) |>
  dplyr::arrange(
    .data[["continent_id"]],
    .data[["data_type"]],
    .data[["vegvault_version"]]
  )

data_release_trait_sources <-
  list_release_counts |>
  purrr::map(.f = ~ purrr::chuck(.x, "traits")) |>
  purrr::list_rbind() |>
  dplyr::select(
    "continent_id", "dataset_source_type", "vegvault_version",
    "n_datasets", "n_trait_values", "n_taxa"
  ) |>
  dplyr::bind_rows(
    list_release_counts |>
      purrr::map(.f = ~ purrr::chuck(.x, "trait_coordinates")) |>
      purrr::list_rbind() |>
      dplyr::mutate(continent_id = "all_trait_datasets") |>
      dplyr::select(
        "continent_id", "dataset_source_type", "vegvault_version",
        "n_datasets", "n_datasets_without_coordinates"
      )
  ) |>
  dplyr::arrange(
    .data[["continent_id"]],
    .data[["dataset_source_type"]],
    .data[["vegvault_version"]]
  )

data_release_fossil_cores <-
  list_release_counts |>
  purrr::map(.f = ~ purrr::chuck(.x, "fossil_cores")) |>
  purrr::list_rbind() |>
  dplyr::select("continent_id", "vegvault_version", "n_cores") |>
  dplyr::arrange(.data[["continent_id"]], .data[["vegvault_version"]])


#----------------------------------------------------------#
# 5. Figure -----
#----------------------------------------------------------#

vec_continent_palette <-
  build_manuscript_palette(domain = "continent")

vec_data_type_labels <-
  base::c(
    fossil_pollen_archive = "Fossil pollen (0-20 ka)",
    vegetation_plot = "Vegetation plots (0 ka)",
    traits = "Plant traits"
  )

vec_metric_labels <-
  base::c(
    n_datasets_with_values = "Datasets",
    n_samples_with_values = "Samples or trait values",
    n_taxa_with_values = "Taxa"
  )

data_figure <-
  data_release_window_counts |>
  dplyr::select(
    "continent_id", "data_type", "vegvault_version",
    dplyr::all_of(base::names(vec_metric_labels))
  ) |>
  tidyr::pivot_longer(
    cols = dplyr::all_of(base::names(vec_metric_labels)),
    names_to = "metric",
    values_to = "n"
  ) |>
  dplyr::filter(!base::is.na(.data[["n"]])) |>
  dplyr::mutate(
    metric = base::factor(
      vec_metric_labels[.data[["metric"]]],
      levels = vec_metric_labels
    ),
    data_type = base::factor(
      vec_data_type_labels[.data[["data_type"]]],
      levels = vec_data_type_labels
    ),
    continent = base::factor(
      stringr::str_to_title(.data[["continent_id"]]),
      levels = base::rev(
        stringr::str_to_title(base::names(vec_continent_palette))
      )
    )
  )

# Change of each count from 1.0.0 to 2.0.0, in percent of 1.0.0
data_figure_change <-
  data_figure |>
  tidyr::pivot_wider(
    names_from = "vegvault_version",
    values_from = "n",
    names_prefix = "n_"
  ) |>
  dplyr::mutate(
    change_percent = 100 * (.data[["n_2.0.0"]] / .data[["n_1.0.0"]] - 1)
  )

vec_continent_colours <-
  vec_continent_palette |>
  rlang::set_names(
    stringr::str_to_title(base::names(vec_continent_palette))
  )

plot_release_window_counts <-
  data_figure_change |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = .data[["change_percent"]],
      y = .data[["continent"]],
      colour = .data[["continent"]]
    )
  ) +
  ggplot2::facet_grid(
    rows = ggplot2::vars(.data[["data_type"]]),
    cols = ggplot2::vars(.data[["metric"]])
  ) +
  ggplot2::scale_colour_manual(
    values = vec_continent_colours,
    guide = "none"
  ) +
  ggplot2::labs(
    x = "Change from VegVault 1.0.0 to 2.0.0 (%)",
    y = NULL
  ) +
  ggplot2::theme_classic() +
  ggplot2::theme(
    strip.background = ggplot2::element_blank(),
    panel.grid.major.y = ggplot2::element_line(
      colour = "grey92",
      linewidth = 0.3
    )
  ) +
  ggview::canvas(
    width = purrr::chuck(graphical_options, "width"),
    height = purrr::chuck(graphical_options, "height"),
    units = purrr::chuck(graphical_options, "units"),
    dpi = purrr::chuck(graphical_options, "dpi"),
    bg = purrr::chuck(graphical_options, "bg")
  ) +
  ggplot2::geom_vline(
    xintercept = 0,
    colour = "grey50",
    linewidth = 0.4
  ) +
  ggplot2::geom_segment(
    mapping = ggplot2::aes(
      x = 0,
      xend = .data[["change_percent"]],
      yend = .data[["continent"]]
    ),
    linewidth = 0.6
  ) +
  ggplot2::geom_point(size = 2.2)


#----------------------------------------------------------#
# 6. Outputs -----
#----------------------------------------------------------#

readr::write_csv(
  x = data_release_window_counts,
  file = base::file.path(dir_output, "release_window_counts.csv"),
  na = ""
)

readr::write_csv(
  x = data_release_trait_sources,
  file = base::file.path(dir_output, "release_trait_sources.csv"),
  na = ""
)

readr::write_csv(
  x = data_release_fossil_cores,
  file = base::file.path(dir_output, "release_fossil_cores_at_0_ka.csv"),
  na = ""
)

ggview::save_ggplot(
  plot = plot_release_window_counts,
  file = base::file.path(dir_output, "release_window_counts.png")
)


#----------------------------------------------------------#
# 7. Report -----
#----------------------------------------------------------#

data_release_window_counts |>
  base::print(n = Inf, width = Inf)

data_release_trait_sources |>
  base::print(n = Inf, width = Inf)

data_release_fossil_cores |>
  base::print(n = Inf)
