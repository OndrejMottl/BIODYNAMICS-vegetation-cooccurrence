#----------------------------------------------------------#
#
#
#               Vegetation Co-occurrence
#
#       Debug: Incremental jSDM - single age slice
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Standalone script that builds three progressively richer
# jSDMs for the age == 1000 BP slice, then predicts across
# the full CZ grid at each stage:
#
#   Stage 1 — abiotic only (bio1)
#   Stage 2 — abiotic only (bio1 + bio12)
#   Stage 3 — abiotic + spatial MEVs
#
# Fixes applied vs. earlier versions:
#   * Community matrix is binarised BEFORE filter_constant_taxa()
#     to avoid always-present taxa saturating the binomial link.
#   * n_mev_debug = 2L prevents overfitting with ~24 sites.
#   * CZ grid predictions (not in-sample) at every stage.
#----------------------------------------------------------#


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

# Set specific config active
Sys.setenv(R_CONFIG_ACTIVE = "project_cz")

# --- Constants (edit here to explore) ---
sel_age <- 1000L # time slice in BP
n_mev_debug <- 2L # MEVs for Stage 3 (>3 overfits ~24 sites)
n_mev_st_debug <- 2L # MEVs for Stage 4 - 3-D spatiotemporal
# Ages used to build Stage 4 MEVs — must span multiple values
#   so sd(age_kyr) > 0 and z-scoring does not produce NaN.
vec_ages_s4 <- c(0L, 500L, 1000L, 2000L, 3000L)
sel_grid_resolution <- 0.1 # degrees; finer = slower CZ grid download
sel_taxon <- "Fagus" # taxon shown in maps
flag_verbose <- FALSE

set_store <-
  paste0(
    get_active_config("target_store"), "/pipeline_basic/"
  ) |>
  here::here()


#----------------------------------------------------------#
# 1. Load intermediate pipeline targets -----
#----------------------------------------------------------#

data_community_subset <-
  targets::tar_read(
    name = "data_community_subset",
    store = set_store
  )

data_abiotic_interpolated <-
  targets::tar_read(
    name = "data_abiotic_interpolated",
    store = set_store
  )

data_coords <-
  targets::tar_read(
    name = "data_coords",
    store = set_store
  )

data_sample_ids_all <-
  targets::tar_read(
    name = "data_sample_ids",
    store = set_store
  )


#----------------------------------------------------------#
# 2. Shared community and abiotic preparation -----
#----------------------------------------------------------#

data_sample_ids_1k <-
  data_sample_ids_all |>
  dplyr::filter(age == sel_age)

# Binarise BEFORE filter_constant_taxa() so always-present taxa
# (varying proportion but always > 0) are caught as constant
# after conversion and removed — preventing intercept saturation
# inside fit_jsdm_model(error_family = "binomial").
data_community_binary_1k <-
  prepare_community_for_fit(
    data_community_long = data_community_subset,
    data_sample_ids = data_sample_ids_1k
  ) %>%
  { (. > 0) * 1L } |>
  filter_constant_taxa()

if (flag_verbose) {
  cat("Taxa retained (binary):", ncol(data_community_binary_1k), "\n")
  cat("Samples:", nrow(data_community_binary_1k), "\n")
}

# Tidy observation data for map overlays at all stages
data_obs_long_1k <-
  data_community_binary_1k |>
  base::as.data.frame() |>
  add_dataset_name_column_from_rownames() |>
  add_age_column_from_rownames() |>
  tidyr::pivot_longer(
    cols = -c(dataset_name, age),
    names_to = "taxon",
    values_to = "presence"
  ) |>
  dplyr::inner_join(
    data_coords |>
      tibble::rownames_to_column("dataset_name"),
    by = dplyr::join_by(dataset_name)
  ) |>
  dplyr::mutate(
    observed = base::ifelse(presence == 1L, "present", "absent")
  )

# Shared abiotic (bio1 + bio12) — used by all stages
data_abiotic_wide_1k <-
  prepare_abiotic_for_fit(
    data_abiotic_long = data_abiotic_interpolated,
    data_sample_ids = data_sample_ids_1k
  )

data_abiotic_scaled_list_1k <-
  scale_abiotic_for_fit(
    data_abiotic_wide = data_abiotic_wide_1k
  )

scale_attrs_1k <-
  data_abiotic_scaled_list_1k |>
  purrr::chuck("scale_attributes")


#----------------------------------------------------------#
# 3. CZ prediction grid -----
#----------------------------------------------------------#

x_lim_pred <-
  get_active_config(
    value = c("vegvault_data", "x_lim")
  )

y_lim_pred <-
  get_active_config(
    value = c("vegvault_data", "y_lim")
  )

data_grid_cz <-
  tidyr::expand_grid(
    coord_long = seq(
      min(x_lim_pred),
      max(x_lim_pred),
      by = sel_grid_resolution
    ),
    coord_lat = seq(
      min(y_lim_pred),
      max(y_lim_pred),
      by = sel_grid_resolution
    )
  ) |>
  dplyr::mutate(
    grid_id = dplyr::row_number()
  )


#----------------------------------------------------------#
# 4. Download CHELSA-TraCE21k bio01 and bio12 -----
#----------------------------------------------------------#

# CHELSA-TraCE21k time-step encoding: step = -(age_BP / 100)
# e.g. 1000 BP -> step -010
chelsa_base_url <-
  paste0(
    "/vsicurl/https://os.zhdk.cloud.switch.ch/",
    "chelsa01/chelsa_trace21k/global/bioclim/"
  )

chelsa_time_step <-
  base::sprintf("-%03d", sel_age %/% 100L)

vec_chelsa_vars <- c("bio01", "bio12")

ext_cz <-
  terra::ext(
    min(x_lim_pred), max(x_lim_pred),
    min(y_lim_pred), max(y_lim_pred)
  )

list_rast_chelsa <-
  purrr::map(
    .x = vec_chelsa_vars,
    .f = ~ {
      url_rast <-
        base::paste0(
          chelsa_base_url,
          .x, "/",
          "CHELSA_TraCE21k_",
          .x, "_",
          chelsa_time_step,
          "_V.1.0.tif"
        )
      terra::rast(url_rast) |>
        terra::crop(y = ext_cz)
    }
  ) |>
  rlang::set_names(vec_chelsa_vars)

# Extract climate values at grid points
# bio01: Kelvin -> subtract 273.15 for °C
# bio12: mm, no conversion needed
data_grid_chelsa <-
  data_grid_cz |>
  dplyr::mutate(
    bio1 = terra::extract(
      list_rast_chelsa[["bio01"]],
      y = cbind(coord_long, coord_lat)
    )[[1]] - 273.15,
    bio12 = terra::extract(
      list_rast_chelsa[["bio12"]],
      y = cbind(coord_long, coord_lat)
    )[[1]]
  ) |>
  tidyr::drop_na()


#----------------------------------------------------------#
# 5. Scale CZ grid abiotic using training scale attributes -----
#----------------------------------------------------------#

data_grid_abiotic_scaled <-
  data_grid_chelsa |>
  dplyr::mutate(
    dplyr::across(
      .cols = c(bio1, bio12),
      .fns = ~ {
        col_nm <- dplyr::cur_column()
        center <- base::as.numeric(
          scale_attrs_1k[[col_nm]]$"scaled:center"
        )
        sc <- base::as.numeric(
          scale_attrs_1k[[col_nm]]$"scaled:scale"
        )
        (.x - center) / sc
      }
    )
  ) |>
  dplyr::select(bio1, bio12)

if (flag_verbose) {
  cat(
    "Grid bio1 range (scaled):",
    base::round(base::range(data_grid_abiotic_scaled$bio1), 2),
    "\n"
  )
  cat(
    "Training bio1 range (scaled):",
    base::round(
      base::range(
        data_abiotic_scaled_list_1k$data_abiotic_scaled$bio1,
        na.rm = TRUE
      ),
      2
    ),
    "\n"
  )
}


#----------------------------------------------------------#
# 6. Stage 1: abiotic only (bio1) -----
#----------------------------------------------------------#

# Assemble data — no spatial component
data_to_fit_s1 <-
  assemble_data_to_fit(
    data_community_filtered = data_community_binary_1k,
    data_abiotic_scaled_list = data_abiotic_scaled_list_1k
  )

mod_s1 <-
  fit_jsdm_model(
    data_to_fit = data_to_fit_s1,
    abiotic_method = "linear",
    sel_abiotic_formula = as.formula(~bio1),
    spatial_method = "none",
    error_family = "binomial",
    device = "gpu",
    parallel = 0L,
    sampling = 1000L,
    iter = 1000L,
    seed = 900723,
    verbose = flag_verbose,
    compute_se = TRUE
  )

if (flag_verbose) {
  summary(mod_s1)
}


#----------------------------------------------------------#
# 7. Stage 1: evaluate + CZ grid prediction + map -----
#----------------------------------------------------------#

eval_s1 <-
  evaluate_jsdm(
    mod_jsdm = mod_s1
  )

if (flag_verbose) {
  cat("Stage 1 AUC by species:\n")
  print(
    eval_s1$species |>
      dplyr::arrange(dplyr::desc(AUC))
  )
}

# Predict on CZ grid — newdata must match the formula (bio1 only)
mat_pred_s1 <-
  sjSDM:::predict.sjSDM(
    mod_s1,
    newdata = data_grid_abiotic_scaled |>
      dplyr::select(bio1),
    type = "link"
  )

base::colnames(mat_pred_s1) <- mod_s1$species

# Build long-format grid predictions
data_pred_s1_long <-
  dplyr::bind_cols(
    data_grid_chelsa |>
      dplyr::select(grid_id, coord_long, coord_lat),
    tibble::as_tibble(mat_pred_s1)
  ) |>
  tidyr::pivot_longer(
    cols = -c(grid_id, coord_long, coord_lat),
    names_to = "taxon",
    values_to = "predicted_value"
  )

# Map for selected taxon
data_sel_s1 <-
  data_obs_long_1k |>
  dplyr::filter(taxon == sel_taxon)

fig_s1 <-
  data_pred_s1_long |>
  dplyr::filter(taxon == sel_taxon) |>
  ggplot2::ggplot() +
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
    data = data_sel_s1,
    mapping = ggplot2::aes(
      x = coord_long,
      y = coord_lat,
      shape = observed
    ),
    size = 2,
    colour = "red"
  ) +
  ggplot2::scale_fill_viridis_c(
    option = "plasma",
    name = "Predicted\noccurrence"
  ) +
  ggplot2::scale_shape_manual(
    values = c("present" = 21L, "absent" = 24L),
    name = "Observed"
  ) +
  ggplot2::coord_quickmap(
    xlim = x_lim_pred,
    ylim = y_lim_pred
  ) +
  ggplot2::theme_minimal() +
  ggplot2::labs(
    x = "Longitude",
    y = "Latitude",
    title = base::paste0("Stage 1 (bio1): ", sel_taxon),
    subtitle = base::paste0(
      "CHELSA-TraCE21k | age ", sel_age, " BP"
    )
  )

plot(fig_s1)


#----------------------------------------------------------#
# 8. Stage 2: abiotic only (bio1 + bio12) -----
#----------------------------------------------------------#

# Same data_to_fit as Stage 1 (binary community + both abiotic vars)
mod_s2 <-
  fit_jsdm_model(
    data_to_fit = data_to_fit_s1,
    abiotic_method = "linear",
    sel_abiotic_formula = as.formula(~ bio1 + bio12),
    spatial_method = "none",
    error_family = "binomial",
    device = "gpu",
    parallel = 0L,
    sampling = 1000L,
    iter = 1000L,
    seed = 900723,
    verbose = flag_verbose,
    compute_se = TRUE
  )

if (flag_verbose) {
  summary(mod_s2)
}


#----------------------------------------------------------#
# 9. Stage 2: evaluate + CZ grid prediction + map -----
#----------------------------------------------------------#

eval_s2 <-
  evaluate_jsdm(
    mod_jsdm = mod_s2
  )

if (flag_verbose) {
  cat("Stage 2 AUC by species:\n")
  print(
    eval_s2$species |>
      dplyr::arrange(dplyr::desc(AUC))
  )
}

mat_pred_s2 <-
  sjSDM:::predict.sjSDM(
    mod_s2,
    newdata = data_grid_abiotic_scaled,
    type = "link"
  )

base::colnames(mat_pred_s2) <- mod_s2$species

data_pred_s2_long <-
  dplyr::bind_cols(
    data_grid_chelsa |>
      dplyr::select(grid_id, coord_long, coord_lat),
    tibble::as_tibble(mat_pred_s2)
  ) |>
  tidyr::pivot_longer(
    cols = -c(grid_id, coord_long, coord_lat),
    names_to = "taxon",
    values_to = "predicted_value"
  )

data_sel_s2 <-
  data_obs_long_1k |>
  dplyr::filter(taxon == sel_taxon)

fig_s2 <-
  data_pred_s2_long |>
  dplyr::filter(taxon == sel_taxon) |>
  ggplot2::ggplot() +
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
    data = data_sel_s2,
    mapping = ggplot2::aes(
      x = coord_long,
      y = coord_lat,
      shape = observed
    ),
    size = 2,
    colour = "red"
  ) +
  ggplot2::scale_fill_viridis_c(
    option = "plasma",
    name = "Predicted\noccurrence"
  ) +
  ggplot2::scale_shape_manual(
    values = c("present" = 21L, "absent" = 24L),
    name = "Observed"
  ) +
  ggplot2::coord_quickmap(
    xlim = x_lim_pred,
    ylim = y_lim_pred
  ) +
  ggplot2::theme_minimal() +
  ggplot2::labs(
    x = "Longitude",
    y = "Latitude",
    title = base::paste0("Stage 2 (bio1 + bio12): ", sel_taxon),
    subtitle = base::paste0(
      "CHELSA-TraCE21k | age ", sel_age, " BP"
    )
  )

plot(fig_s2)


#----------------------------------------------------------#
# 10. Spatial MEV preparation (Stage 3 inputs) -----
#----------------------------------------------------------#

# Project unique-site coordinates to metric km
data_coords_projected_1k <-
  project_coords_to_metric(
    data_coords = data_coords
  )

# Compute n_mev_debug Moran eigenvectors on unique sites
data_spatial_mev_core_1k <-
  compute_spatial_mev(
    data_coords_projected = data_coords_projected_1k,
    n_mev = n_mev_debug
  )

if (flag_verbose) {
  cat("MEV dimensions (sites x MEVs):", dim(data_spatial_mev_core_1k), "\n")
}

# Expand to sample-level (one row per site x age combination)
data_spatial_mev_samples_1k <-
  prepare_spatial_predictors_for_fit(
    data_spatial = data_spatial_mev_core_1k,
    data_sample_ids = data_sample_ids_1k
  )

data_spatial_scaled_list_1k <-
  scale_spatial_for_fit(
    data_spatial = data_spatial_mev_samples_1k
  )

spatial_scale_attrs_1k <-
  data_spatial_scaled_list_1k |>
  purrr::chuck("spatial_scale_attributes")

vec_mev_cols <-
  base::names(data_spatial_mev_core_1k)


#----------------------------------------------------------#
# 11. IDW interpolation of MEVs to CZ grid -----
#----------------------------------------------------------#

# MEVs are eigenvectors of the training-site connectivity matrix
# and cannot be evaluated analytically at new locations.
# Inverse Distance Weighting (IDW, power = 2) approximates them.

# Project grid coords to km (same CRS as training MEVs)
data_grid_coords_km <-
  data_grid_chelsa |>
  dplyr::select(grid_id, coord_long, coord_lat) |>
  dplyr::mutate(
    dataset_name = base::paste0("grid_", grid_id)
  ) |>
  tibble::column_to_rownames("dataset_name") |>
  project_coords_to_metric()

# Training km-coordinates + unscaled MEV values
data_train_mev_coords <-
  data_coords_projected_1k |>
  tibble::rownames_to_column("dataset_name") |>
  dplyr::inner_join(
    data_spatial_mev_core_1k |>
      tibble::rownames_to_column("dataset_name"),
    by = dplyr::join_by(dataset_name)
  )

mat_xy_train_km <-
  data_train_mev_coords |>
  dplyr::select(coord_x_km, coord_y_km) |>
  base::as.matrix()

mat_xy_grid_km <-
  data_grid_coords_km |>
  dplyr::select(coord_x_km, coord_y_km) |>
  base::as.matrix()

# Euclidean distance matrix (rows = grid pts, cols = train sites)
mat_dist_km <-
  base::sqrt(
    base::outer(
      mat_xy_grid_km[, 1],
      mat_xy_train_km[, 1],
      `-`
    )^2 +
      base::outer(
        mat_xy_grid_km[, 2],
        mat_xy_train_km[, 2],
        `-`
      )^2
  )

# IDW weights (epsilon avoids division by zero at coincident pts)
mat_idw_weights <-
  1 / (mat_dist_km^2 + 1e-10)

mat_idw_weights <-
  mat_idw_weights / base::rowSums(mat_idw_weights)

mat_train_mev <-
  data_train_mev_coords |>
  dplyr::select(dplyr::all_of(vec_mev_cols)) |>
  base::as.matrix()

data_grid_mev_raw <-
  base::as.data.frame(mat_idw_weights %*% mat_train_mev)

base::colnames(data_grid_mev_raw) <- vec_mev_cols
base::rownames(data_grid_mev_raw) <- base::rownames(data_grid_coords_km)

# Scale grid MEVs using training spatial scale attributes
data_grid_mev_scaled <-
  data_grid_mev_raw |>
  dplyr::mutate(
    dplyr::across(
      .cols = dplyr::everything(),
      .fns = ~ {
        col_nm <- dplyr::cur_column()
        center <- base::as.numeric(
          spatial_scale_attrs_1k[[col_nm]]$"scaled:center"
        )
        sc <- base::as.numeric(
          spatial_scale_attrs_1k[[col_nm]]$"scaled:scale"
        )
        (.x - center) / sc
      }
    )
  )


#----------------------------------------------------------#
# 12. Stage 3: abiotic + spatial MEVs -----
#----------------------------------------------------------#

data_to_fit_s3 <-
  assemble_data_to_fit(
    data_community_filtered = data_community_binary_1k,
    data_abiotic_scaled_list = data_abiotic_scaled_list_1k,
    data_spatial_scaled_list = data_spatial_scaled_list_1k
  )

mod_s3 <-
  fit_jsdm_model(
    data_to_fit = data_to_fit_s3,
    abiotic_method = "linear",
    sel_abiotic_formula = as.formula(~ bio1 + bio12),
    spatial_method = "linear",
    sel_spatial_formula = as.formula(~ 0 + .),
    error_family = "binomial",
    device = "gpu",
    parallel = 0L,
    sampling = 1000L,
    iter = 1000L,
    seed = 900723,
    verbose = flag_verbose,
    compute_se = TRUE
  )

if (flag_verbose) {
  summary(mod_s3)
}


#----------------------------------------------------------#
# 13. Stage 3: evaluate + CZ grid prediction + map -----
#----------------------------------------------------------#

eval_s3 <-
  evaluate_jsdm(
    mod_jsdm = mod_s3
  )

if (flag_verbose) {
  cat("Stage 3 AUC by species:\n")
  print(
    eval_s3$species |>
      dplyr::arrange(dplyr::desc(AUC))
  )
}

mat_pred_s3 <-
  sjSDM:::predict.sjSDM(
    mod_s3,
    newdata = data_grid_abiotic_scaled,
    SP = data_grid_mev_scaled,
    type = "link"
  )

base::colnames(mat_pred_s3) <- mod_s3$species

data_pred_s3_long <-
  dplyr::bind_cols(
    data_grid_chelsa |>
      dplyr::select(grid_id, coord_long, coord_lat),
    tibble::as_tibble(mat_pred_s3)
  ) |>
  tidyr::pivot_longer(
    cols = -c(grid_id, coord_long, coord_lat),
    names_to = "taxon",
    values_to = "predicted_value"
  )

data_sel_s3 <-
  data_obs_long_1k |>
  dplyr::filter(taxon == sel_taxon)

fig_s3 <-
  data_pred_s3_long |>
  dplyr::filter(taxon == sel_taxon) |>
  ggplot2::ggplot() +
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
    data = data_sel_s3,
    mapping = ggplot2::aes(
      x = coord_long,
      y = coord_lat,
      shape = observed
    ),
    size = 2,
    colour = "red"
  ) +
  ggplot2::scale_fill_viridis_c(
    option = "plasma",
    name = "Predicted\noccurrence"
  ) +
  ggplot2::scale_shape_manual(
    values = c("present" = 21L, "absent" = 24L),
    name = "Observed"
  ) +
  ggplot2::coord_quickmap(
    xlim = x_lim_pred,
    ylim = y_lim_pred
  ) +
  ggplot2::theme_minimal() +
  ggplot2::labs(
    x = "Longitude",
    y = "Latitude",
    title = base::paste0(
      "Stage 3 (bio1 + bio12 + ", n_mev_debug, " MEVs): ",
      sel_taxon
    ),
    subtitle = base::paste0(
      "CHELSA-TraCE21k | age ", sel_age, " BP | IDW-interpolated MEVs"
    )
  )

plot(fig_s3)


#----------------------------------------------------------#
# 14. Stage 4 shared data preparation -----
#----------------------------------------------------------#

# Stage 4 is a spatiotemporal model: community, abiotic, and
# 3-D MEVs are all prepared from vec_ages_s4 so the temporal
# dimension has genuine variance throughout the pipeline.
# The formula uses only bio1 + bio12 (no age interaction) so
# predictions at sel_age are not distorted by bio:age terms;
# temporal structure is captured exclusively by the ST-MEVs.

data_sample_ids_s4 <-
  data_sample_ids_all |>
  dplyr::filter(age %in% vec_ages_s4)

# Community: binarise + filter constant taxa over all slices
data_community_binary_s4 <-
  prepare_community_for_fit(
    data_community_long = data_community_subset,
    data_sample_ids = data_sample_ids_s4
  ) %>%
  { (. > 0) * 1L } |>
  filter_constant_taxa()

if (flag_verbose) {
  cat(
    "Stage 4 taxa retained (binary):",
    ncol(data_community_binary_s4), "\n"
  )
  cat(
    "Stage 4 samples (all slices):",
    nrow(data_community_binary_s4), "\n"
  )
}

# Abiotic: wide format over vec_ages_s4
data_abiotic_wide_s4 <-
  prepare_abiotic_for_fit(
    data_abiotic_long = data_abiotic_interpolated,
    data_sample_ids = data_sample_ids_s4
  )

# scale_abiotic_for_fit() centres+scales bio variables;
# age is also centred (no SD division) but excluded from
# the formula via use_age = FALSE in Section 17.
data_abiotic_scaled_list_s4 <-
  scale_abiotic_for_fit(
    data_abiotic_wide = data_abiotic_wide_s4
  )

scale_attrs_s4 <-
  data_abiotic_scaled_list_s4 |>
  purrr::chuck("scale_attributes")


#----------------------------------------------------------#
# 15. Spatiotemporal MEV preparation (Stage 4 inputs) -----
#----------------------------------------------------------#

# 3-D MEVs require age variance across samples.
# Using a single time slice means sd(age_kyr) = 0, which
# breaks z-scoring inside compute_spatiotemporal_mev().
# Solution: compute MEVs from vec_ages_s4 (multiple slices)
# so the age dimension has genuine variance, then filter
# to the sel_age rows for model fitting.

# data_sample_ids_s4 was defined in Section 14.

# 3-D MEVs from the full multi-slice sample set
# (data_coords_projected_1k covers all sites)
data_st_mev_samples_s4 <-
  compute_spatiotemporal_mev(
    data_coords_projected = data_coords_projected_1k,
    data_sample_ids = data_sample_ids_s4,
    n_mev = n_mev_st_debug
  )

if (flag_verbose) {
  cat(
    "ST-MEV dimensions (all slices, samples x MEVs):",
    dim(data_st_mev_samples_s4),
    "\n"
  )
}

# Scale using all slices — scale attributes reflect the
# full spatio-temporal distribution
data_st_spatial_scaled_list_s4 <-
  scale_spatial_for_fit(
    data_spatial = data_st_mev_samples_s4
  )

st_spatial_scale_attrs_s4 <-
  data_st_spatial_scaled_list_s4 |>
  purrr::chuck("spatial_scale_attributes")

vec_st_mev_cols <-
  base::names(data_st_mev_samples_s4)

# Extract the sel_age rows for model fitting.
# Row names follow "dataset_name__age"; keep only those
# whose suffix matches sel_age.
data_st_mev_scaled_1k <-
  data_st_spatial_scaled_list_s4 |>
  purrr::chuck("data_spatial_scaled") |>
  tibble::rownames_to_column("sample_id") |>
  dplyr::filter(
    stringr::str_ends(
      sample_id,
      base::paste0("__", sel_age)
    )
  ) |>
  tibble::column_to_rownames("sample_id")

# Rebuild the list structure expected by assemble_data_to_fit():
# scaled data is the sel_age subset; scale attributes come from
# the full multi-slice computation.
data_st_spatial_scaled_list_1k <-
  base::list(
    data_spatial_scaled = data_st_mev_scaled_1k,
    spatial_scale_attributes = st_spatial_scale_attrs_s4
  )


#----------------------------------------------------------#
# 16. IDW interpolation of 3-D MEVs to CZ grid -----
#----------------------------------------------------------#

# The 3-D MEVs were computed from z-scored (x_km, y_km,
# age_kyr).  IDW interpolation to grid points must use
# the same 3-D z-scored space so distances are consistent.
# Grid points are fixed at sel_age (prediction surface
# for a single time slice).

# Training 3-D matrix (unscaled raw values) -----
# Row order is anchored to the row names of data_st_mev_samples_s4
# to guarantee alignment with mat_train_st_mev below.
data_train_3d_raw <-
  tibble::tibble(
    sample_id = base::rownames(data_st_mev_samples_s4)
  ) |>
  tidyr::separate(
    col = sample_id,
    into = c("dataset_name", "age_chr"),
    sep = "__",
    extra = "merge"
  ) |>
  dplyr::mutate(age = base::as.integer(age_chr)) |>
  dplyr::select(-age_chr) |>
  dplyr::inner_join(
    data_coords_projected_1k |>
      tibble::rownames_to_column("dataset_name"),
    by = dplyr::join_by(dataset_name)
  ) |>
  dplyr::mutate(
    age_kyr = age / 1000
  ) |>
  dplyr::select(dataset_name, age, coord_x_km,
    coord_y_km, age_kyr)

mat_3d_train_raw <-
  data_train_3d_raw |>
  dplyr::select(coord_x_km, coord_y_km, age_kyr) |>
  base::as.matrix()

# Capture z-score parameters from training data
vec_3d_center <-
  base::colMeans(mat_3d_train_raw)

vec_3d_scale <-
  base::apply(mat_3d_train_raw, 2, stats::sd)

# Z-score training matrix -----
mat_3d_train_z <-
  base::scale(
    mat_3d_train_raw,
    center = vec_3d_center,
    scale = vec_3d_scale
  )

# Grid 3-D matrix — x/y from projected grid, age = sel_age
data_grid_3d_raw <-
  data_grid_chelsa |>
  dplyr::select(grid_id, coord_long, coord_lat) |>
  dplyr::mutate(
    dataset_name = base::paste0("grid_", grid_id)
  ) |>
  tibble::column_to_rownames("dataset_name") |>
  project_coords_to_metric() |>
  dplyr::mutate(
    age_kyr = sel_age / 1000
  )

mat_3d_grid_raw <-
  data_grid_3d_raw |>
  dplyr::select(coord_x_km, coord_y_km, age_kyr) |>
  base::as.matrix()

# Apply training z-score to grid -----
mat_3d_grid_z <-
  base::scale(
    mat_3d_grid_raw,
    center = vec_3d_center,
    scale = vec_3d_scale
  )

# Euclidean distances in 3-D z-scored space -----
mat_dist_3d <-
  base::sqrt(
    base::outer(
      mat_3d_grid_z[, 1],
      mat_3d_train_z[, 1],
      `-`
    )^2 +
      base::outer(
        mat_3d_grid_z[, 2],
        mat_3d_train_z[, 2],
        `-`
      )^2 +
      base::outer(
        mat_3d_grid_z[, 3],
        mat_3d_train_z[, 3],
        `-`
      )^2
  )

# IDW weights (power = 2) -----
mat_idw_weights_3d <-
  1 / (mat_dist_3d^2 + 1e-10)

mat_idw_weights_3d <-
  mat_idw_weights_3d / base::rowSums(mat_idw_weights_3d)

# Unscaled ST-MEV values at training samples (all slices) -----
mat_train_st_mev <-
  data_st_mev_samples_s4 |>
  dplyr::select(dplyr::all_of(vec_st_mev_cols)) |>
  base::as.matrix()

# Interpolated raw ST-MEV values at grid -----
data_grid_st_mev_raw <-
  base::as.data.frame(
    mat_idw_weights_3d %*% mat_train_st_mev
  )

base::colnames(data_grid_st_mev_raw) <- vec_st_mev_cols

# Scale using training ST-MEV scale attributes -----
data_grid_st_mev_scaled <-
  data_grid_st_mev_raw |>
  dplyr::mutate(
    dplyr::across(
      .cols = dplyr::everything(),
      .fns = ~ {
        col_nm <- dplyr::cur_column()
        center <- base::as.numeric(
          st_spatial_scale_attrs_s4[[col_nm]]$"scaled:center"
        )
        sc <- base::as.numeric(
          st_spatial_scale_attrs_s4[[col_nm]]$"scaled:scale"
        )
        (.x - center) / sc
      }
    )
  )


#----------------------------------------------------------#
# 17. Stage 4: scale CZ grid abiotic for Stage 4 -----
#----------------------------------------------------------#

# data_grid_abiotic_scaled uses scale_attrs_1k (single slice)
# and is correct for Stages 1-3.  Stage 4 was trained on
# multi-slice data (scale_attrs_s4), so the grid predictors
# must be re-centred and re-scaled with the same attributes.
data_grid_abiotic_scaled_s4 <-
  data_grid_chelsa |>
  dplyr::mutate(
    dplyr::across(
      .cols = c(bio1, bio12),
      .fns = ~ {
        col_nm <- dplyr::cur_column()
        center <- base::as.numeric(
          scale_attrs_s4[[col_nm]]$"scaled:center"
        )
        sc <- base::as.numeric(
          scale_attrs_s4[[col_nm]]$"scaled:scale"
        )
        (.x - center) / sc
      }
    )
  ) |>
  dplyr::select(bio1, bio12)


#----------------------------------------------------------#
# 18. Stage 4: abiotic + spatiotemporal MEVs -----
#----------------------------------------------------------#

# Stage 4 trains on all vec_ages_s4 slices so both the
# community observations and climate predictors span
# genuine temporal variation — consistent with the 3-D
# ST-MEVs computed in Section 15.
# use_age = FALSE: temporal structure is encoded by the
# ST-MEVs; the bio formula stays ~ bio1 + bio12 so
# no bio:age interaction distorts the sel_age prediction.
data_to_fit_s4 <-
  assemble_data_to_fit(
    data_community_filtered = data_community_binary_s4,
    data_abiotic_scaled_list = data_abiotic_scaled_list_s4,
    data_spatial_scaled_list = data_st_spatial_scaled_list_s4
  )

mod_s4 <-
  fit_jsdm_model(
    data_to_fit = data_to_fit_s4,
    abiotic_method = "linear",
    sel_abiotic_formula = make_env_formula(
      data = data_to_fit_s4$data_abiotic_to_fit,
      use_age = FALSE
    ),
    spatial_method = "linear",
    sel_spatial_formula = as.formula(~ 0 + .),
    error_family = "binomial",
    device = "gpu",
    parallel = 0L,
    sampling = 1000L,
    iter = 1000L,
    seed = 900723,
    verbose = flag_verbose,
    compute_se = TRUE
  )

if (flag_verbose) {
  summary(mod_s4)
}


#----------------------------------------------------------#
# 19. Stage 4: evaluate + CZ grid prediction + map -----
#----------------------------------------------------------#

eval_s4 <-
  evaluate_jsdm(
    mod_jsdm = mod_s4
  )

if (flag_verbose) {
  cat("Stage 4 AUC by species:\n")
  print(
    eval_s4$species |>
      dplyr::arrange(dplyr::desc(AUC))
  )
}

mat_pred_s4 <-
  sjSDM:::predict.sjSDM(
    mod_s4,
    # Use data_grid_abiotic_scaled_s4: same bio columns but
    # centred/scaled with the multi-slice scale_attrs_s4
    # to match the scale seen during training.
    newdata = data_grid_abiotic_scaled_s4,
    SP = data_grid_st_mev_scaled,
    type = "link"
  )

base::colnames(mat_pred_s4) <- mod_s4$species

data_pred_s4_long <-
  dplyr::bind_cols(
    data_grid_chelsa |>
      dplyr::select(grid_id, coord_long, coord_lat),
    tibble::as_tibble(mat_pred_s4)
  ) |>
  tidyr::pivot_longer(
    cols = -c(grid_id, coord_long, coord_lat),
    names_to = "taxon",
    values_to = "predicted_value"
  )

data_sel_s4 <-
  data_obs_long_1k |>
  dplyr::filter(taxon == sel_taxon)

fig_s4 <-
  data_pred_s4_long |>
  dplyr::filter(taxon == sel_taxon) |>
  ggplot2::ggplot() +
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
    data = data_sel_s4,
    mapping = ggplot2::aes(
      x = coord_long,
      y = coord_lat,
      shape = observed
    ),
    size = 2,
    colour = "red"
  ) +
  ggplot2::scale_fill_viridis_c(
    option = "plasma",
    name = "Predicted\noccurrence"
  ) +
  ggplot2::scale_shape_manual(
    values = c("present" = 21L, "absent" = 24L),
    name = "Observed"
  ) +
  ggplot2::coord_quickmap(
    xlim = x_lim_pred,
    ylim = y_lim_pred
  ) +
  ggplot2::theme_minimal() +
  ggplot2::labs(
    x = "Longitude",
    y = "Latitude",
    title = base::paste0(
      "Stage 4 (bio1 + bio12 + ",
      n_mev_st_debug,
      " ST-MEVs): ",
      sel_taxon
    ),
    subtitle = base::paste0(
      "CHELSA-TraCE21k | age ", sel_age,
      " BP | IDW-interpolated 3-D MEVs"
    )
  )

plot(fig_s4)


#----------------------------------------------------------#
# 20. AUC comparison across all four stages -----
#----------------------------------------------------------#

# Stages 1-3 train on the single sel_age slice.
# Stage 4 trains on all vec_ages_s4 slices (needed for
# genuine 3-D ST-MEV variance) with formula ~ bio1 + bio12.
# AUC_s4 is in-sample over multiple time points so direct
# magnitude comparisons with AUC_s1-s3 should be treated
# with caution; the sign of delta_s3_s4 is the key metric.

data_auc_comparison <-
  eval_s1$species |>
  dplyr::select(species, AUC) |>
  dplyr::rename(AUC_s1 = AUC) |>
  dplyr::full_join(
    eval_s2$species |>
      dplyr::select(species, AUC) |>
      dplyr::rename(AUC_s2 = AUC),
    by = dplyr::join_by(species)
  ) |>
  dplyr::full_join(
    eval_s3$species |>
      dplyr::select(species, AUC) |>
      dplyr::rename(AUC_s3 = AUC),
    by = dplyr::join_by(species)
  ) |>
  dplyr::full_join(
    eval_s4$species |>
      dplyr::select(species, AUC) |>
      dplyr::rename(AUC_s4 = AUC),
    by = dplyr::join_by(species)
  ) |>
  dplyr::mutate(
    delta_s1_s2 = AUC_s2 - AUC_s1,
    delta_s2_s3 = AUC_s3 - AUC_s2,
    delta_s3_s4 = AUC_s4 - AUC_s3
  ) |>
  dplyr::arrange(dplyr::desc(AUC_s4))

if (flag_verbose) {
  cat("\nAUC comparison across all four stages:\n")
  print(data_auc_comparison)
}

cowplot::plot_grid(
  fig_s1, fig_s2, fig_s3, fig_s4,
  ncol = 1,
  labels = "AUTO"
)

summary(data_pred_s1_long)
summary(data_pred_s2_long)
summary(data_pred_s3_long)
summary(data_pred_s4_long)

data_auc_comparison  |> 
dplyr::filter(species == sel_taxon) 
