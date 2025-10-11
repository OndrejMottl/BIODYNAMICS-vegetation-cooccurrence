#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#                   Predict from model
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# WIP a test to predict from an already fitted model
#   into a grid of selected points

#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

library(Hmsc)


#----------------------------------------------------------#
# 1. Extract data -----
#----------------------------------------------------------#

mod_hmsc_with_eval <-
  targets::tar_read(
    name = "mod_hmsc_to_use",
    store = here::here(
      config::get(
        value = "target_store",
        config = "project_cz",
        use_parent = FALSE,
        file = here::here("config.yml")
      )
    )
  )



mod_hmsc <-
  mod_hmsc_with_eval %>%
  purrr::chuck("mod")


age_lim <-
  get_active_config(
    value = c("vegvault_data", "age_lim")
  )

vec_age_slices <-
  seq(
    min(age_lim),
    max(age_lim),
    get_active_config(
      value = c("data_processing", "time_step")
    )
  )

x_lim <-
  get_active_config(
    value = c("vegvault_data", "x_lim")
  )

x_lim_max <- max(x_lim, na.rm = TRUE)
x_lim_min <- min(x_lim, na.rm = TRUE)

y_lim <-
  get_active_config(
    value = c("vegvault_data", "y_lim")
  )

y_lim_max <- max(y_lim, na.rm = TRUE)
y_lim_min <- min(y_lim, na.rm = TRUE)

con <-
  DBI::dbConnect(
    RSQLite::SQLite(),
    here::here("Data/Input/VegVault.sqlite")
  )

data_gridpoints_raw <-
  dplyr::tbl(con, "Datasets") %>%
  dplyr::filter(data_source_type_id == 5) %>%
  dplyr::filter(
    coord_long >= x_lim_min &
      coord_long <= x_lim_max &
      coord_lat >= y_lim_min &
      coord_lat <= y_lim_max
  ) %>%
  dplyr::inner_join(
    dplyr::tbl(con, "DatasetSample"),
    by = "dataset_id"
  ) %>%
  dplyr::inner_join(
    dplyr::tbl(con, "Samples"),
    by = "sample_id"
  ) %>%
  dplyr::inner_join(
    dplyr::tbl(con, "AbioticData") %>%
      dplyr::filter(
        abiotic_variable_id == 1 |
          abiotic_variable_id == 4
      ),
    by = "sample_id"
  ) %>%
  dplyr::collect()

DBI::dbDisconnect(con)


#----------------------------------------------------------#
# 2. preparation of data to be predicted upon -----
#----------------------------------------------------------#

data_to_predict <-
  data_gridpoints_raw %>%
  dplyr::filter(
    age %in% vec_age_slices
  ) %>%
  dplyr::select(
    dataset_name,
    coord_long, coord_lat,
    age,
    abiotic_variable_id, abiotic_value
  )


data_to_predict_distinct <-
  data_to_predict %>%
  tidyr::pivot_wider(
    names_from = abiotic_variable_id,
    values_from = abiotic_value,
    names_prefix = "var_id_"
  ) %>%
  dplyr::distinct(coord_long, coord_lat, age, .keep_all = TRUE) %>%
  dplyr::rename(
    bio1 = var_id_1,
    bio12 = var_id_4
  )

data_to_predict_clim <-
  data_to_predict_distinct %>%
  dplyr::select(bio1, bio12) %>%
  as.data.frame()


data_coords <-
  data_to_predict_distinct %>%
  dplyr::distinct(dataset_name, coord_long, coord_lat) %>%
  tibble::column_to_rownames("dataset_name")

random_coors_knots <-
  Hmsc::constructKnots(
    sData = data_coords,
    minKnotDist = get_active_config(
      c("data_processing", "min_distance_of_gpp_knots")
    )
  )

random_level_coords <-
  Hmsc::HmscRandomLevel(
    sData = data_coords,
    sMethod = "GPP",
    sKnot = random_coors_knots
  )

data_age <-
  data_to_predict_distinct %>%
  dplyr::distinct(age) %>%
  dplyr::arrange(age) %>%
  dplyr::mutate(
    age_rowname = as.character(age)
  ) %>%
  tibble::column_to_rownames("age_rowname")

random_level_age <-
  Hmsc::HmscRandomLevel(
    sData = data_age
  )

study_design <-
  data_to_predict_distinct %>%
  dplyr::mutate(
    age_factor = factor(
      x = age,
      levels = sort(unique(as.numeric(age))),
      ordered = TRUE
    ),
    dataset_name_factor = as.factor(dataset_name)
  ) %>%
  dplyr::select(
    "dataset_name" = "dataset_name_factor",
    "age" = "age_factor"
  ) %>%
  as.data.frame()


#----------------------------------------------------------#
# 3. Prediction -----
#----------------------------------------------------------#

data_pred <-
  Hmsc:::predict.Hmsc(
    object = mod_hmsc,
    XData = data_to_predict_clim,
    studyDesign = study_design,
    ranLevels = list(
      age = random_level_age,
      dataset_name = random_level_coords
    ),
    predictEtaMean = TRUE,
    expected = TRUE
  )


#----------------------------------------------------------#
# 4. Post-processing -----
#----------------------------------------------------------#

mean_with_na <- function(x) {
  mean(x, na.rm = TRUE)
}

data_pred_avg <-
  apply(
    abind::abind(data_pred, along = 3),
    c(1, 2),
    FUN = mean_with_na
  )


#----------------------------------------------------------#
# 5. test visualization -----
#----------------------------------------------------------#

data_to_fit <-
  targets::tar_read(
    name = "data_to_fit",
    store = here::here(
      config::get(
        value = "target_store",
        config = "project_cz",
        use_parent = FALSE,
        file = here::here("config.yml")
      )
    )
  )

# Check a good taxon to visualize
data_taxa_eval <-
  tibble::tibble(
    taxon = data_to_fit$data_community_to_fit %>%
      colnames(),
    mod_hmsc_with_eval %>%
      purrr::chuck("eval") %>%
      as.data.frame()
  )

data_taxa_n_ages_with_absent <-
  data_to_fit$data_community_to_fit %>%
  add_age_column_from_rownames() %>%
  tidyr::pivot_longer(
    cols = -c(age),
    names_to = "taxon",
    values_to = "proportion"
  ) %>%
  dplyr::mutate(
    present = ifelse(proportion > 0, TRUE, FALSE)
  ) %>%
  dplyr::group_by(taxon, age) %>%
  dplyr::summarise(
    .groups = "drop",
    n = n(),
    n_present = sum(present),
    n_absent = n - n_present,
    absent = ifelse(n_absent > 0 & n_present > 0, TRUE, FALSE)
  ) %>%
  dplyr::group_by(taxon) %>%
  dplyr::summarise(
    .groups = "drop",
    n_ages_with_absent = sum(absent)
  ) %>%
  dplyr::arrange(desc(n_ages_with_absent))

data_pred_values_summary <-
  data_pred_avg %>%
  as_tibble() %>%
  purrr::map(summary) %>%
  dplyr::bind_rows(.id = "taxon") %>%
  janitor::clean_names() %>%
  dplyr::mutate(
    dplyr::across(
      .cols = -taxon,
      .fns = ~ as.numeric(.x)
    )
  )

dplyr::inner_join(
  data_taxa_eval,
  data_taxa_n_ages_with_absent,
  by = "taxon"
) %>%
  dplyr::inner_join(
    data_pred_values_summary,
    by = "taxon"
  ) %>%
  dplyr::arrange(desc(AUC)) %>%
  View()


# based on the above, select a taxon to visualize
sel_taxa <- "Fraxinus"

data_observed <-
  data_to_fit %>%
  purrr::chuck("data_community_to_fit") %>%
  add_age_column_from_rownames() %>%
  add_dataset_name_column_from_rownames() %>%
  as_tibble() %>%
  dplyr::left_join(
    data_to_fit$data_coords_to_fit %>%
      tibble::rownames_to_column("dataset_name"),
    by = "dataset_name"
  ) %>%
  tidyr::pivot_longer(
    cols = -c(age, dataset_name, coord_long, coord_lat),
    names_to = "taxon",
    values_to = "proportion"
  ) %>%
  dplyr::filter(taxon == sel_taxa) %>%
  dplyr::mutate(
    present = ifelse(proportion > 0, "present", "absent")
  )

# Make a plot
as_tibble(study_design) %>%
  dplyr::mutate(
    coord_long = dataset_name %>%
      stringr::str_remove("geo_") %>%
      stringr::str_remove("_.*"),
    coord_lat = dataset_name %>%
      stringr::str_remove("geo_") %>%
      stringr::str_remove(".*_"),
    age = as.numeric(as.character(age))
  ) %>%
  dplyr::bind_cols(
    as_tibble(data_pred_avg)
  ) %>%
  tidyr::pivot_longer(
    cols = -c(dataset_name, coord_lat, coord_long, age),
    names_to = "taxon",
    values_to = "pred_value"
  ) %>%
  dplyr::filter(taxon == sel_taxa) %>%
  dplyr::select(coord_long, coord_lat, age, pred_value) %>%
  ggplot2::ggplot() +
  ggplot2::facet_wrap(~age) +
  ggplot2::geom_tile(
    mapping = ggplot2::aes(
      x = as.numeric(coord_long),
      y = as.numeric(coord_lat),
      fill = pred_value
    ),
    col = NA,
    alpha = 0.8,
    linewidth = 0,
    width = 0.5,
    height = 0.5
  ) +
  ggplot2::borders(
    "world",
    fill = NA,
    colour = "black"
  ) +
  ggplot2::geom_point(
    data = data_observed,
    mapping = ggplot2::aes(
      x = as.numeric(coord_long),
      y = as.numeric(coord_lat),
      color = as.factor(present),
      shape = as.factor(present)
    ),
    size = 5,
    alpha = 0.5
  ) +
  ggplot2::scale_fill_viridis_c() +
  ggplot2::scale_color_manual(
    values = c(
      "present" = "red",
      "absent" = "black"
    )
  ) +
  ggplot2::scale_shape_manual(
    values = c(
      "present" = 12,
      "absent" = 13
    )
  ) +
  ggplot2::theme_minimal() +
  ggplot2::theme(
    legend.position = "top",
    plot.title = ggplot2::element_text(hjust = 0.5),
    plot.subtitle = ggplot2::element_text(hjust = 0.5)
  ) +
  ggplot2::coord_quickmap(
    xlim = x_lim,
    ylim = y_lim
  ) +
  ggplot2::labs(
    fill = "Predicted\noccurrence",
    color = "Observed",
    shape = "Observed",
    x = "Longitude",
    y = "Latitude",
    title = paste(
      "Predicted occurrence of",
      sel_taxa,
      get_active_config(
        c("data_processing", "taxonomic_resolution")
      ),
      " for Czechia"
    ),
    subtitle = "Each facet is a different time slice",
    caption = paste(
      paste(
        "HMSC model with space (GPP; minimum distance of",
        get_active_config(
          c("data_processing", "min_distance_of_gpp_knots")
        ),
        ") and age as random effect"
      ),
      paste(
        "Climatic variables:",
        paste(
          get_active_config(
            c("vegvault_data", "sel_abiotic_var_name")
          ),
          collapse = ", "
        )
      ),
      paste(
        "Model fitted with",
        get_active_config(
          c("model_fitting", "n_cores")
        ),
        "cores,",
        get_active_config(
          c("model_fitting", "samples")
        ),
        "samples,",
        get_active_config(
          c("model_fitting", "cross_validation_folds")
        ),
        "cross-validation folds"
      ),
      paste(
        "Model evaluation:",
        data_taxa_eval %>%
          dplyr::filter(taxon == sel_taxa) %>%
          dplyr::pull(AUC) %>%
          round(3),
        "AUC;",
        data_taxa_eval %>%
          dplyr::filter(taxon == sel_taxa) %>%
          dplyr::pull(TjurR2) %>%
          round(3),
        "TjurR2;",
        data_taxa_eval %>%
          dplyr::filter(taxon == sel_taxa) %>%
          dplyr::pull(RMSE) %>%
          round(3),
        "RMSE"
      ),
      sep = "\n"
    )
  )
