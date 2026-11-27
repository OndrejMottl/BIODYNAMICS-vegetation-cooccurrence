#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#     Compare the climate of VegVault 1.0.0 and 2.0.0
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Read-only comparison of the VegVault 2.0.0 migration (Stage V, step V5).
# For the gridpoints of each continental window of spatial_grid.csv, ages
#   0 to 20,000 cal yr BP, it matches the samples of both releases by name
#   (geo_<long>_<lat>_<age>, unchanged between the releases) and compares
#   every value of the seven climate variables the models use.
# The release notes of 2.0.0 say that only present-day bio4 changed inside
#   these windows; that 6553.5 mm of present-day bio12 is a storage limit;
#   that bio18 and bio19 can be 0 in dry quarters; and that a masked block
#   of past precipitation lies in South America. The checks test these
#   statements for the project windows.
# Inputs: Data/Input/VegVault.sqlite (2.0.0) and
#   Data/Input/VegVault_1.0.0.sqlite, opened read-only; the continental
#   rows of Data/Input/spatial_grid.csv.
# Outputs (Documentation/Reports/Model_evaluation/
#   vegvault_2_migration_2026-11/):
#   - release_climate_by_age.csv
#   - release_climate_checks.csv


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

vec_climate_variables <-
  load_config_value(
    config_id = "project_paleo_spatial_continental",
    value = base::c("vegvault_data", "sel_abiotic_var_name")
  )

vec_age_lim <-
  load_config_value(
    config_id = "project_paleo_spatial_continental",
    value = base::c("vegvault_data", "age_lim")
  )

# Storage limit of present-day CHELSA V2.1 annual precipitation
value_bio12_storage_limit <- 6553.5

# Values that differ by less than this count as equal
value_tolerance <- 1e-6

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

query_gridpoint_samples <-
  stringr::str_c(
    "SELECT s.sample_id, s.sample_name, s.age",
    " FROM Datasets d",
    " JOIN DatasetTypeID dt ON d.dataset_type_id = dt.dataset_type_id",
    " JOIN DatasetSample ds ON d.dataset_id = ds.dataset_id",
    " JOIN Samples s ON ds.sample_id = s.sample_id",
    " WHERE dt.dataset_type = 'gridpoints'",
    " AND d.coord_long BETWEEN ? AND ? AND d.coord_lat BETWEEN ? AND ?",
    " AND s.age BETWEEN ? AND ?"
  )

query_gridpoint_values <-
  stringr::str_c(
    "SELECT s.sample_name, av.abiotic_variable_name AS variable,",
    " ad.abiotic_value AS value",
    " FROM Datasets d",
    " JOIN DatasetTypeID dt ON d.dataset_type_id = dt.dataset_type_id",
    " JOIN DatasetSample ds ON d.dataset_id = ds.dataset_id",
    " JOIN Samples s ON ds.sample_id = s.sample_id",
    " JOIN AbioticData ad ON ad.sample_id = s.sample_id",
    " JOIN AbioticVariable av",
    " ON ad.abiotic_variable_id = av.abiotic_variable_id",
    " WHERE dt.dataset_type = 'gridpoints'",
    " AND d.coord_long BETWEEN ? AND ? AND d.coord_lat BETWEEN ? AND ?",
    " AND s.age BETWEEN ? AND ?"
  )


#----------------------------------------------------------#
# 2. Values of both releases -----
#----------------------------------------------------------#

data_climate_by_age <-
  base::seq_len(base::nrow(data_continental_windows)) |>
  purrr::map(
    .f = ~ {
      data_window <-
        data_continental_windows |>
        dplyr::slice(.x)

      sel_continent_id <-
        dplyr::pull(data_window, "continent_id")

      list_query_params <-
        base::list(
          dplyr::pull(data_window, "x_min"),
          dplyr::pull(data_window, "x_max"),
          dplyr::pull(data_window, "y_min"),
          dplyr::pull(data_window, "y_max"),
          vec_age_lim[1],
          vec_age_lim[2]
        )

      list_release_values <-
        list_release_paths |>
        purrr::imap(
          .f = ~ {
            cli::cli_inform(
              "Reading {sel_continent_id} gridpoints of VegVault {.y}."
            )

            connection_vegvault <-
              DBI::dbConnect(
                drv = RSQLite::SQLite(),
                dbname = .x,
                flags = RSQLite::SQLITE_RO
              )

            data_samples <-
              DBI::dbGetQuery(
                conn = connection_vegvault,
                statement = query_gridpoint_samples,
                params = list_query_params
              ) |>
              tibble::as_tibble()

            data_values <-
              DBI::dbGetQuery(
                conn = connection_vegvault,
                statement = query_gridpoint_values,
                params = list_query_params
              ) |>
              tibble::as_tibble() |>
              dplyr::filter(
                .data[["variable"]] %in% vec_climate_variables
              )

            DBI::dbDisconnect(connection_vegvault)

            # One row per gridpoint sample and variable; a value the
            #   release does not hold stays NA
            tidyr::expand_grid(
              data_samples |>
                dplyr::select("sample_name", "age") |>
                dplyr::mutate(present = TRUE),
              variable = vec_climate_variables
            ) |>
              dplyr::left_join(
                data_values,
                by = dplyr::join_by("sample_name", "variable"),
                relationship = "one-to-one"
              )
          }
        )

      data_release_pairs <-
        dplyr::full_join(
          purrr::chuck(list_release_values, "1.0.0"),
          purrr::chuck(list_release_values, "2.0.0"),
          by = dplyr::join_by("sample_name", "age", "variable"),
          suffix = base::c("_v1", "_v2"),
          relationship = "one-to-one"
        )

      # bio4 of the present day against 500 cal yr BP at the same point
      data_bio4_ratio <-
        data_release_pairs |>
        dplyr::filter(
          .data[["variable"]] == "bio4",
          .data[["age"]] %in% base::c(0, 500)
        ) |>
        dplyr::mutate(
          gridpoint = stringr::str_remove(
            .data[["sample_name"]],
            "_[0-9]+$"
          )
        ) |>
        dplyr::select("gridpoint", "age", "value_v2") |>
        tidyr::pivot_wider(
          names_from = "age",
          values_from = "value_v2",
          names_prefix = "bio4_"
        ) |>
        dplyr::mutate(
          ratio = .data[["bio4_0"]] / .data[["bio4_500"]]
        )

      # A sample can be absent from one release, or present there
      #   without a value; both are counted apart.
      data_release_pairs |>
        dplyr::mutate(
          present_v1 = dplyr::coalesce(.data[["present_v1"]], FALSE),
          present_v2 = dplyr::coalesce(.data[["present_v2"]], FALSE),
          flag_both = !base::is.na(.data[["value_v1"]]) &
            !base::is.na(.data[["value_v2"]]),
          flag_differ = .data[["flag_both"]] &
            base::abs(.data[["value_v1"]] - .data[["value_v2"]]) >
              value_tolerance
        ) |>
        dplyr::group_by(.data[["variable"]], .data[["age"]]) |>
        dplyr::summarise(
          n_gridpoints = dplyr::n(),
          n_samples_v1 = base::sum(.data[["present_v1"]]),
          n_samples_v2 = base::sum(.data[["present_v2"]]),
          n_missing_v1 = base::sum(
            .data[["present_v1"]] & base::is.na(.data[["value_v1"]])
          ),
          n_missing_v2 = base::sum(
            .data[["present_v2"]] & base::is.na(.data[["value_v2"]])
          ),
          n_differ = base::sum(.data[["flag_differ"]]),
          n_zero_v1 = base::sum(.data[["value_v1"]] == 0, na.rm = TRUE),
          n_zero_v2 = base::sum(.data[["value_v2"]] == 0, na.rm = TRUE),
          n_at_bio12_limit_v2 = base::sum(
            .data[["variable"]] == "bio12" &
              .data[["value_v2"]] >= value_bio12_storage_limit,
            na.rm = TRUE
          ),
          min_v2 = base::suppressWarnings(
            base::min(.data[["value_v2"]], na.rm = TRUE)
          ),
          median_v2 = stats::median(.data[["value_v2"]], na.rm = TRUE),
          max_v2 = base::suppressWarnings(
            base::max(.data[["value_v2"]], na.rm = TRUE)
          ),
          .groups = "drop"
        ) |>
        dplyr::mutate(
          continent_id = sel_continent_id,
          bio4_ratio_0_to_500_median = dplyr::if_else(
            .data[["variable"]] == "bio4" & .data[["age"]] == 0,
            stats::median(
              dplyr::pull(data_bio4_ratio, "ratio"),
              na.rm = TRUE
            ),
            NA_real_
          ),
          bio4_ratio_0_to_500_lwr_90 = dplyr::if_else(
            .data[["variable"]] == "bio4" & .data[["age"]] == 0,
            stats::quantile(
              dplyr::pull(data_bio4_ratio, "ratio"),
              probs = 0.05,
              na.rm = TRUE,
              names = FALSE
            ),
            NA_real_
          ),
          bio4_ratio_0_to_500_upr_90 = dplyr::if_else(
            .data[["variable"]] == "bio4" & .data[["age"]] == 0,
            stats::quantile(
              dplyr::pull(data_bio4_ratio, "ratio"),
              probs = 0.95,
              na.rm = TRUE,
              names = FALSE
            ),
            NA_real_
          )
        )
    }
  ) |>
  purrr::list_rbind() |>
  dplyr::relocate("continent_id") |>
  dplyr::arrange(
    .data[["continent_id"]],
    .data[["variable"]],
    .data[["age"]]
  )


#----------------------------------------------------------#
# 3. Checks -----
#----------------------------------------------------------#

data_climate_checks <-
  data_climate_by_age |>
  dplyr::group_by(.data[["continent_id"]]) |>
  dplyr::summarise(
    n_gridpoints_at_0_ka = base::sum(
      .data[["n_gridpoints"]][
        .data[["variable"]] == "bio4" & .data[["age"]] == 0
      ]
    ),
    n_bio4_zero_at_0_ka_v1 = base::sum(
      .data[["n_zero_v1"]][
        .data[["variable"]] == "bio4" & .data[["age"]] == 0
      ]
    ),
    n_bio4_zero_at_0_ka_v2 = base::sum(
      .data[["n_zero_v2"]][
        .data[["variable"]] == "bio4" & .data[["age"]] == 0
      ]
    ),
    min_bio4_at_0_ka_v2 = base::min(
      .data[["min_v2"]][
        .data[["variable"]] == "bio4" & .data[["age"]] == 0
      ]
    ),
    bio4_ratio_0_to_500_median = base::max(
      .data[["bio4_ratio_0_to_500_median"]],
      na.rm = TRUE
    ),
    bio4_ratio_0_to_500_lwr_90 = base::max(
      .data[["bio4_ratio_0_to_500_lwr_90"]],
      na.rm = TRUE
    ),
    bio4_ratio_0_to_500_upr_90 = base::max(
      .data[["bio4_ratio_0_to_500_upr_90"]],
      na.rm = TRUE
    ),
    n_values_differ_other_than_bio4_at_0_ka = base::sum(
      .data[["n_differ"]][
        !(.data[["variable"]] == "bio4" & .data[["age"]] == 0)
      ]
    ),
    n_gridpoint_samples_v1 = base::sum(
      .data[["n_samples_v1"]][.data[["variable"]] == "bio1"]
    ),
    n_gridpoint_samples_v2 = base::sum(
      .data[["n_samples_v2"]][.data[["variable"]] == "bio1"]
    ),
    n_values_missing_v1 = base::sum(.data[["n_missing_v1"]]),
    n_values_missing_v2 = base::sum(.data[["n_missing_v2"]]),
    n_bio12_at_storage_limit_v2 = base::sum(
      .data[["n_at_bio12_limit_v2"]]
    ),
    n_bio18_zero_v1 = base::sum(
      .data[["n_zero_v1"]][.data[["variable"]] == "bio18"]
    ),
    n_bio18_zero_v2 = base::sum(
      .data[["n_zero_v2"]][.data[["variable"]] == "bio18"]
    ),
    n_bio19_zero_v1 = base::sum(
      .data[["n_zero_v1"]][.data[["variable"]] == "bio19"]
    ),
    n_bio19_zero_v2 = base::sum(
      .data[["n_zero_v2"]][.data[["variable"]] == "bio19"]
    ),
    .groups = "drop"
  )


#----------------------------------------------------------#
# 4. Outputs -----
#----------------------------------------------------------#

readr::write_csv(
  x = data_climate_by_age,
  file = base::file.path(dir_output, "release_climate_by_age.csv"),
  na = ""
)

readr::write_csv(
  x = data_climate_checks,
  file = base::file.path(dir_output, "release_climate_checks.csv"),
  na = ""
)

data_climate_checks |>
  tidyr::pivot_longer(
    cols = -"continent_id",
    names_to = "check",
    values_to = "value"
  ) |>
  tidyr::pivot_wider(
    names_from = "continent_id",
    values_from = "value"
  ) |>
  base::print(n = Inf, width = Inf)
