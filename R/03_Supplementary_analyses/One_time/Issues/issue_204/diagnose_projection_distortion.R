#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#            Diagnose projection distance distortion
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Issue #204: compares candidate projections per continent by the ratio of
#   projected to great-circle distance between sampled cores, following the
#   9 November 2026 method (up to 300 random cores per continental
#   fossil-pollen store, pairs more than 50 km apart). Stores are only read.
# The selected projection per continent has the narrowest 5-95 % ratio range
#   (ties: median closest to 1). Europe keeps EPSG:3035 by decision.
# Great-circle distances use {s2} (spherical Earth); the ellipsoid is not
#   available without {lwgeom}, and a spherical reference shifts all ratios
#   by less than 0.5 %, leaving the ranking of candidates unchanged.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

base::source(
  file = "R/___setup_project___.R"
)

seed_sampling <- 900723L
n_cores_max <- 300L
distance_min_km <- 50

path_report <-
  here::here(
    "Documentation/Reports/Model_evaluation",
    "stage_a_model_input_corrections_2026-11"
  )

data_continents <-
  readr::read_csv(
    file = here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  ) |>
  dplyr::filter(.data[["scale"]] == "continental") |>
  dplyr::mutate(
    lon_centre = (.data[["x_min"]] + .data[["x_max"]]) / 2,
    lat_centre = (.data[["y_min"]] + .data[["y_max"]]) / 2
  )


#----------------------------------------------------------#
# 1. Candidate projections -----
#----------------------------------------------------------#

data_candidates <-
  data_continents |>
  purrr::pmap(
    .f = function(continent_id, lon_centre, lat_centre, ...) {
      vec_regional_albers <-
        base::c(
          america = "ESRI:102008",
          asia = "ESRI:102025"
        )
      vec_centre <-
        stringr::str_c(
          "+lat_0=", lat_centre, " +lon_0=", lon_centre,
          " +datum=WGS84 +units=m +no_defs"
        )
      vec_definitions <-
        base::c(
          "EPSG:3035",
          base::unname(vec_regional_albers[continent_id]),
          stringr::str_c("+proj=laea ", vec_centre),
          stringr::str_c("+proj=aeqd ", vec_centre)
        )
      tibble::tibble(
        continent_id = continent_id,
        crs_label = base::c(
          "etrs89_laea_europe",
          "albers_equal_area_regional",
          "laea_continent_centre",
          "aeqd_continent_centre"
        ),
        crs_definition = vec_definitions
      ) |>
        dplyr::filter(!base::is.na(.data[["crs_definition"]]))
    }
  ) |>
  purrr::list_rbind() |>
  dplyr::mutate(crs_definition = base::as.character(.data[["crs_definition"]]))


#----------------------------------------------------------#
# 2. Distance ratios -----
#----------------------------------------------------------#

data_distortion <-
  tidyr::expand_grid(
    data_source = base::c("paleo", "modern"),
    continent_id = data_continents[["scale_id"]]
  ) |>
  purrr::pmap(
    .f = function(data_source, continent_id) {
      path_store <-
        here::here(
          "Data/targets",
          stringr::str_c(data_source, "_spatial_continental"),
          continent_id,
          stringr::str_c("pipeline_", data_source, "_spatial_resolution")
        )
      data_coords <-
        targets::tar_read_raw(name = "data_coords_analysis", store = path_store)

      base::set.seed(seed_sampling)
      index_sampled <-
        base::sample(
          x = base::nrow(data_coords),
          size = base::min(n_cores_max, base::nrow(data_coords))
        )
      sf_points <-
        sf::st_as_sf(
          data_coords[index_sampled, , drop = FALSE],
          coords = base::c("coord_long", "coord_lat"),
          crs = 4326
        )
      mat_geodesic_km <-
        base::unclass(sf::st_distance(sf_points)) / 1000
      flag_pair <-
        base::upper.tri(mat_geodesic_km) &
        mat_geodesic_km > distance_min_km

      data_candidates |>
        dplyr::filter(.data[["continent_id"]] == .env[["continent_id"]]) |>
        purrr::pmap(
          .f = function(crs_label, crs_definition, ...) {
            mat_projected_km <-
              sf_points |>
              sf::st_transform(crs = crs_definition) |>
              sf::st_coordinates() |>
              stats::dist() |>
              base::as.matrix() / 1000
            vec_ratio <-
              mat_projected_km[flag_pair] / mat_geodesic_km[flag_pair]
            tibble::tibble(
              data_source = data_source,
              continent_id = continent_id,
              crs_label = crs_label,
              crs_definition = crs_definition,
              n_cores = base::length(index_sampled),
              n_pairs = base::length(vec_ratio),
              ratio_median = stats::median(vec_ratio),
              ratio_lwr_90 = stats::quantile(vec_ratio, probs = 0.05),
              ratio_upr_90 = stats::quantile(vec_ratio, probs = 0.95),
              ratio_min = base::min(vec_ratio),
              ratio_max = base::max(vec_ratio)
            )
          }
        ) |>
        purrr::list_rbind()
    }
  ) |>
  purrr::list_rbind() |>
  dplyr::mutate(
    ratio_range_90 = .data[["ratio_upr_90"]] - .data[["ratio_lwr_90"]]
  )


#----------------------------------------------------------#
# 3. Select per continent -----
#----------------------------------------------------------#

data_selected <-
  data_distortion |>
  dplyr::filter(.data[["data_source"]] == "paleo") |>
  dplyr::group_by(.data[["continent_id"]]) |>
  dplyr::arrange(
    .data[["ratio_range_90"]],
    base::abs(.data[["ratio_median"]] - 1),
    .by_group = TRUE
  ) |>
  dplyr::slice_head(n = 1L) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    crs_label = dplyr::if_else(
      .data[["continent_id"]] == "europe",
      "etrs89_laea_europe",
      .data[["crs_label"]]
    )
  ) |>
  dplyr::select("continent_id", crs_label_selected = "crs_label")

data_distortion_report <-
  data_distortion |>
  dplyr::left_join(
    data_selected,
    by = dplyr::join_by(continent_id)
  ) |>
  dplyr::mutate(
    flag_selected = .data[["crs_label"]] == .data[["crs_label_selected"]]
  ) |>
  dplyr::select(-"crs_label_selected")

readr::write_csv(
  x = data_distortion_report,
  file = base::file.path(path_report, "projection_distortion.csv")
)

data_distortion_report |>
  dplyr::mutate(
    dplyr::across(
      .cols = dplyr::starts_with("ratio_"),
      .fns = ~ base::round(.x, 3)
    )
  ) |>
  dplyr::select(-"crs_definition") |>
  base::print(n = Inf, width = Inf)
