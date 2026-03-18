#----------------------------------------------------------#
#
#
#               Vegetation Co-occurrence
#
#          Predict on full spatio-temporal grid
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Load the fitted pipeline model and predict taxon
# occurrence probabilities across a regular lat/lon grid
# for all configured age slices. Climate data are
# downloaded from CHELSA-TraCE21k and cached locally.
# Spatial MEVs are interpolated to grid points via IDW.
# Results are saved as a tidy data frame; a named list of
# per-taxon faceted plots is built for interactive review.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

# ---- USER SETTINGS (edit here) -------------------------
sel_project <- "project_temporal_europe" # or "project_cz"
vec_pipelines <- "pipeline_basic"
sel_grid_resolution <- 0.5 # degrees (finer = slower)
verbose <- FALSE
# --------------------------------------------------------

Sys.setenv(R_CONFIG_ACTIVE = sel_project)


#----------------------------------------------------------#
# 1. Load pipeline targets -----
#----------------------------------------------------------#

set_store <-
  here::here(
    base::paste0(
      get_active_config("target_store"),
      "/",
      vec_pipelines,
      "/"
    )
  )

# Read model-fitting config first to drive conditional loading
use_spatial <-
  get_active_config(c("model_fitting", "use_spatial"))

spatial_mode <-
  get_active_config(c("model_fitting", "spatial_mode"))

spatial_crs <-
  get_active_config(c("model_fitting", "spatial_crs"))

# Always-needed targets
mod_jsdm <-
  targets::tar_read(
    name = "mod_jsdm",
    store = set_store
  )

model_evaluation <-
  targets::tar_read(
    name = "model_evaluation",
    store = set_store
  )

data_to_fit <-
  targets::tar_read(
    name = "data_to_fit",
    store = set_store
  )

# Site-level WGS84 coords (used for observed overlay)
data_coords <-
  targets::tar_read(
    name = "data_coords",
    store = set_store
  )

# Conditional targets: only loaded when spatial is active
data_coords_projected <- NULL
data_spatial_mev_core <- NULL
data_spatial_mev_samples <- NULL
spatial_scale_attributes <- NULL

if (
  isTRUE(use_spatial)
) {
  # Projected km coords needed for MEV IDW interpolation
  data_coords_projected <-
    targets::tar_read(
      name = "data_coords_projected",
      store = set_store
    )

  spatial_scale_attributes <-
    data_to_fit |>
    purrr::pluck("spatial_scale_attributes")

  if (
    spatial_mode == "spatial"
  ) {
    # 2-D site-level MEVs
    data_spatial_mev_core <-
      targets::tar_read(
        name = "data_spatial_mev_core",
        store = set_store
      )
  } else {
    # 3-D sample-level MEVs for spatiotemporal mode
    data_spatial_mev_samples <-
      targets::tar_read(
        name = "data_spatial_mev_samples",
        store = set_store
      )
  }
}

# Training scale attributes (always needed)
scale_attributes <-
  data_to_fit |>
  purrr::chuck("scale_attributes")

if (
  isTRUE(verbose)
) {
  cat("spatial_mode:", spatial_mode, "\n")
  cat("use_spatial:", use_spatial, "\n")
}


#----------------------------------------------------------#
# 2. Config-based prediction grid -----
#----------------------------------------------------------#

x_lim <-
  get_active_config(c("vegvault_data", "x_lim"))

y_lim <-
  get_active_config(c("vegvault_data", "y_lim"))

age_lim <-
  get_active_config(c("vegvault_data", "age_lim"))

time_step <-
  get_active_config(c("data_processing", "time_step"))

sel_abiotic_var_name <-
  get_active_config(c("vegvault_data", "sel_abiotic_var_name"))

vec_age_slices <-
  base::seq(
    base::min(age_lim),
    base::max(age_lim),
    by = time_step
  )

# Regular lat/lon grid for the configured geographic extent
data_grid_base <-
  tidyr::expand_grid(
    coord_long = base::seq(
      base::min(x_lim),
      base::max(x_lim),
      by = sel_grid_resolution
    ),
    coord_lat = base::seq(
      base::min(y_lim),
      base::max(y_lim),
      by = sel_grid_resolution
    )
  ) |>
  dplyr::mutate(grid_id = dplyr::row_number())

# Mask to land-only cells: remove ocean grid points before any
# downstream extraction or interpolation.
land_poly <-
  rnaturalearth::ne_countries(
    scale = "medium",
    returnclass = "sf"
  )

data_grid_land_mask <-
  data_grid_base |>
  sf::st_as_sf(
    coords = c("coord_long", "coord_lat"),
    crs = 4326L
  ) |>
  sf::st_filter(land_poly) |>
  sf::st_drop_geometry() |>
  dplyr::pull(grid_id)

data_grid_base <-
  data_grid_base |>
  dplyr::filter(grid_id %in% data_grid_land_mask)

# Project grid coords to km once — reused across all age slices
data_grid_coords_km <-
  data_grid_base |>
  dplyr::mutate(
    dataset_name = base::paste0("grid_", grid_id)
  ) |>
  dplyr::select(-grid_id) |>
  tibble::column_to_rownames("dataset_name") |>
  project_coords_to_metric(
    target_crs = spatial_crs
  )

if (
  isTRUE(verbose)
) {
  cat(
    "Prediction grid:",
    nrow(data_grid_base), "cells x",
    length(vec_age_slices), "age slices\n"
  )
}


#----------------------------------------------------------#
# 3. CHELSA cache directory -----
#----------------------------------------------------------#

# Project-specific subdirectory so files cropped for different
# geographic extents are never mixed.
path_chelsa_cache <-
  here::here(base::paste0("Data/Temp/chelsa/", sel_project))

base::dir.create(
  path_chelsa_cache,
  recursive = TRUE,
  showWarnings = FALSE
)


#----------------------------------------------------------#
# 4. Precompute 2-D MEV interpolation (spatial mode) -----
#----------------------------------------------------------#

# In 2-D mode MEVs do not change with age, so interpolate
# to the full grid once and subset per age slice later.
data_grid_mev_all <- NULL

if (
  isTRUE(use_spatial) && spatial_mode == "spatial"
) {
  if (
    is.null(data_spatial_mev_core)
  ) {
    stop(
      paste0(
        "spatial_mode = 'spatial' but data_spatial_mev_core",
        " is NULL in the pipeline store."
      )
    )
  }

  data_grid_mev_all <-
    interpolate_mev_to_grid(
      data_coords_projected_train = data_coords_projected,
      data_mev_core = data_spatial_mev_core,
      data_coords_projected_pred = data_grid_coords_km,
      spatial_scale_attributes = spatial_scale_attributes
    )
}


#----------------------------------------------------------#
# 5. Build full predictor matrix and predict -----
#----------------------------------------------------------#


#--------------------------------------------------#
## 5.1. Download all CHELSA rasters and extract -----
#--------------------------------------------------#

# Loop is over ages only because each age requires a
# separate CHELSA raster. Rows are then stacked into
# one all-samples matrix for a single predict call.
data_climate_all <-
  vec_age_slices |>
  rlang::set_names() |>
  purrr::map(
    .progress = verbose,
    .f = ~ {
      age_i <- .x

      if (
        isTRUE(verbose)
      ) {
        cat("Processing/Downloading CHELSA for age:", age_i, "BP\n")
      }

      sel_abiotic_var_name |>
        rlang::set_names() |>
        purrr::map(
          .f = ~ {
            rast_bio <-
              get_chelsa_raster(
                chelsa_var = .x,
                age = age_i,
                x_lim = x_lim,
                y_lim = y_lim,
                cache_dir = path_chelsa_cache
              )

            terra::extract(
              rast_bio,
              y = base::cbind(
                data_grid_base$coord_long,
                data_grid_base$coord_lat
              )
            )[[1]]
          }
        ) |>
        tibble::as_tibble() |>
        dplyr::bind_cols(
          data_grid_base |>
            dplyr::select(grid_id, coord_long, coord_lat)
        ) |>
        dplyr::mutate(age = age_i) |>
        tidyr::drop_na()
    }
  ) |>
  purrr::list_rbind()


#--------------------------------------------------#
## 5.2. Scale abiotic predictors -----
#--------------------------------------------------#

# Replicate scaling from scale_abiotic_for_fit():
#   age -> centre only; bio vars -> centre + scale.
data_abiotic_scaled_all <-
  data_climate_all |>
  dplyr::select(
    dplyr::any_of(base::names(scale_attributes))
  ) |>
  dplyr::mutate(
    dplyr::across(
      .cols = dplyr::any_of("age"),
      .fns = ~ .x - base::as.numeric(
        scale_attributes[["age"]][["scaled:center"]]
      )
    )
  ) |>
  dplyr::mutate(
    dplyr::across(
      .cols = -dplyr::any_of("age"),
      .fns = ~ {
        col_nm <- dplyr::cur_column()
        center <- base::as.numeric(
          scale_attributes[[col_nm]][["scaled:center"]]
        )
        sc <- base::as.numeric(
          scale_attributes[[col_nm]][["scaled:scale"]]
        )
        (.x - center) / sc
      }
    )
  ) |>
  base::as.data.frame()


#--------------------------------------------------#
## 5.3. Spatial MEV predictors for all samples -----
#--------------------------------------------------#

mat_sp_all <- NULL

if (
  isTRUE(use_spatial)
) {
  if (
    spatial_mode == "spatial"
  ) {
    # 2-D: MEVs do not vary with age — index the
    # precomputed grid MEV matrix by valid grid IDs
    # present in climate data (after drop_na).
    mat_sp_all <-
      data_grid_mev_all[
        base::paste0("grid_", data_climate_all$grid_id), ,
        drop = FALSE
      ] |>
      base::as.data.frame()
  } else {
    # 3-D: interpolate per age slice, then row-bind
    # in the same order as data_climate_all.
    mat_sp_all <-
      vec_age_slices |>
      rlang::set_names() |>
      purrr::map(
        .f = ~ {
          age_i <- .x

          valid_ids <-
            data_climate_all |>
            dplyr::filter(age == age_i) |>
            dplyr::pull(grid_id)

          valid_rownames <-
            base::paste0("grid_", valid_ids)

          interpolate_st_mev_to_grid(
            data_st_mev_samples = data_spatial_mev_samples,
            data_coords_projected_train = data_coords_projected,
            data_coords_projected_pred =
              data_grid_coords_km[
                valid_rownames, ,
                drop = FALSE
              ],
            pred_age = age_i,
            spatial_scale_attributes = spatial_scale_attributes
          )
        }
      ) |>
      purrr::list_rbind() |>
      base::as.data.frame()
  }
}


#--------------------------------------------------#
## 5.4. Single predict call on full matrix -----
#--------------------------------------------------#

mat_pred <-
  sjSDM:::predict.sjSDM(
    mod_jsdm,
    newdata = data_abiotic_scaled_all,
    SP = mat_sp_all,
    type = "link"
  )

base::colnames(mat_pred) <- mod_jsdm$species


#--------------------------------------------------#
## 5.5. Reshape to long format -----
#--------------------------------------------------#

data_predicted_long <-
  dplyr::bind_cols(
    data_climate_all |>
      dplyr::select(grid_id, coord_long, coord_lat, age),
    tibble::as_tibble(mat_pred)
  ) |>
  tidyr::pivot_longer(
    cols = -c(grid_id, coord_long, coord_lat, age),
    names_to = "taxon",
    values_to = "predicted_value"
  )


#----------------------------------------------------------#
# 6. In-sample observations (for map overlays) -----
#----------------------------------------------------------#

data_observed_long <-
  data_to_fit |>
  purrr::chuck("data_community_to_fit") |>
  base::as.data.frame() |>
  add_dataset_name_column_from_rownames() |>
  add_age_column_from_rownames() |>
  tibble::as_tibble() |>
  tidyr::pivot_longer(
    cols = -c(dataset_name, age),
    names_to = "taxon",
    values_to = "value"
  ) |>
  dplyr::mutate(
    observed = base::ifelse(value > 0, "present", "absent")
  ) |>
  dplyr::left_join(
    data_coords |>
      tibble::rownames_to_column("dataset_name") |>
      dplyr::select(dataset_name, coord_long, coord_lat),
    by = dplyr::join_by(dataset_name)
  )


#----------------------------------------------------------#
# 7. Summaries -----
#----------------------------------------------------------#

# Model performance per species (sorted by AUC)
data_species_eval <-
  model_evaluation |>
  purrr::chuck("species") |>
  dplyr::arrange(dplyr::desc(AUC))

if (
  isTRUE(verbose)
) {
  print(data_species_eval, n = 100)
}

# Per-taxon mean predicted occurrence and temporal stability
data_summary_by_taxon <-
  data_predicted_long |>
  dplyr::group_by(taxon, age) |>
  dplyr::summarise(
    .groups = "drop",
    mean_pred_at_age = base::mean(predicted_value, na.rm = TRUE)
  ) |>
  dplyr::group_by(taxon) |>
  dplyr::summarise(
    .groups = "drop",
    mean_predicted = base::mean(mean_pred_at_age, na.rm = TRUE),
    # Temporal CV: high = strong temporal dynamics
    temporal_cv = stats::sd(mean_pred_at_age) /
      base::mean(mean_pred_at_age, na.rm = TRUE)
  ) |>
  dplyr::arrange(dplyr::desc(mean_predicted))

if (
  isTRUE(verbose)
) {
  print(data_summary_by_taxon, n = 100)
}


#----------------------------------------------------------#
# 8. Visualisations -----
#----------------------------------------------------------#

# One plot per taxon, faceted by age.
# Tile fill = predicted occurrence; points = observed
# presence (triangle) / absence (inverted triangle).
vec_taxa <-
  base::sort(base::unique(data_predicted_long$taxon))

list_figures <-
  vec_taxa |>
  rlang::set_names() |>
  purrr::map(
    .f = ~ {
      taxon_i <- .x

      ggplot2::ggplot(
        data = data_predicted_long |>
          dplyr::filter(taxon == taxon_i)
      ) +
        ggplot2::facet_wrap(~age) +
        ggplot2::geom_tile(
          mapping = ggplot2::aes(
            x = coord_long,
            y = coord_lat,
            fill = predicted_value
          ),
          width = sel_grid_resolution,
          height = sel_grid_resolution
        ) +
        ggplot2::geom_point(
          data = data_observed_long |>
            dplyr::filter(taxon == taxon_i),
          mapping = ggplot2::aes(
            x = coord_long,
            y = coord_lat,
            shape = observed,
            col = observed
          ),
          size = 2L,
        ) +
        ggplot2::scale_fill_viridis_c(
          option = "plasma",
          name = "Predicted\noccurrence"
        ) +
        ggplot2::scale_shape_manual(
          values = c("present" = 12L, "absent" = 4L),
          name = "Observed"
        ) +
        scale_color_manual(
          values = c("present" = "red3", "absent" = "black"),
          name = "Observed"
        ) +
        ggplot2::coord_quickmap(
          xlim = x_lim,
          ylim = y_lim
        ) +
        ggplot2::theme_minimal() +
        ggplot2::labs(
          x = "Longitude",
          y = "Latitude",
          title = taxon_i,
          subtitle = base::paste0(
            sel_project,
            " | CHELSA-TraCE21k | ",
            vec_pipelines
          )
        )
    }
  )

# Example: inspect a specific taxon
# plot(list_figures[[1]])
# plot(list_figures[["Fagus"]])
# plot(list_figures[["Acer"]])
