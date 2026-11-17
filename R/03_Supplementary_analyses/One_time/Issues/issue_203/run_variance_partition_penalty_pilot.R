#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Pilot the penalised variance partition
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Issue #203: compares published variance partitions with partitions rebuilt
#   by the corrected compute_jsdm_variance_partition(), whose sub-models carry
#   the full model's association penalty and seed. Works on COPIES of stores
#   under Data/Temp/pilot_203/; production stores are only read.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

base::source(
  file = "R/___setup_project___.R"
)

path_pilot_root <-
  here::here("Data/Temp/pilot_203")

path_report <-
  here::here(
    "Documentation/Reports/Model_evaluation",
    "stage_a_model_input_corrections_2026-11"
  )

base::dir.create(
  path = path_report,
  showWarnings = FALSE,
  recursive = TRUE
)

# Pilot units: penalised (candidate_005-008) across fossil tiers, one modern
#   unit, and one unpenalised resolution (candidate_004) for comparison.
data_pilot_units <-
  tibble::tribble(
    ~profile_id, ~store_root, ~scale_id, ~pipeline_name, ~resolution_id,
    "project_paleo_spatial_local", "paleo_spatial_local", "eu_r002_l001",
    "pipeline_paleo_spatial_resolution", "genus",
    "project_paleo_spatial_local", "paleo_spatial_local", "eu_r002_l001",
    "pipeline_paleo_spatial_resolution", "family",
    "project_paleo_spatial_local", "paleo_spatial_local", "eu_r002_l001",
    "pipeline_paleo_spatial_resolution", "functional_type",
    "project_paleo_spatial_local", "paleo_spatial_local", "eu_r008_l003",
    "pipeline_paleo_spatial_resolution", "family",
    "project_paleo_spatial_regional", "paleo_spatial_regional", "eu_r004",
    "pipeline_paleo_spatial_resolution", "genus",
    "project_paleo_spatial_continental", "paleo_spatial_continental", "asia",
    "pipeline_paleo_spatial_resolution", "functional_type",
    "project_modern_spatial_local", "modern_spatial_local", "eu_r005_l002",
    "pipeline_modern_spatial_resolution", "family"
  ) |>
  dplyr::mutate(
    store_production = here::here(
      "Data/targets",
      .data[["store_root"]],
      .data[["scale_id"]],
      .data[["pipeline_name"]]
    ),
    store_copy = base::file.path(
      path_pilot_root,
      "Data/targets",
      .data[["store_root"]],
      .data[["scale_id"]],
      .data[["pipeline_name"]]
    ),
    target_name = stringr::str_c(
      "list_jsdm_variance_partition_",
      .data[["resolution_id"]]
    )
  )


#----------------------------------------------------------#
# 1. Copy stores -----
#----------------------------------------------------------#

data_pilot_units |>
  dplyr::distinct(.data[["store_production"]], .data[["store_copy"]]) |>
  purrr::pwalk(
    .f = function(store_production, store_copy) {
      if (
        !base::dir.exists(store_copy)
      ) {
        fs::dir_copy(path = store_production, new_path = store_copy)
      }
    }
  )


#----------------------------------------------------------#
# 2. Rebuild partitions on the copies -----
#----------------------------------------------------------#

data_rebuild <-
  data_pilot_units |>
  dplyr::group_by(
    .data[["profile_id"]],
    .data[["pipeline_name"]],
    .data[["store_copy"]]
  ) |>
  dplyr::summarise(
    vec_target_names = base::list(.data[["target_name"]]),
    .groups = "drop"
  ) |>
  purrr::pmap(
    .f = function(profile_id, pipeline_name, store_copy, vec_target_names) {
      withr::with_envvar(
        new = base::c(R_CONFIG_ACTIVE = profile_id),
        code = rlang::inject(
          targets::tar_make(
            names = tidyselect::all_of(!!vec_target_names),
            shortcut = TRUE,
            script = here::here(
              "R/Pipelines",
              stringr::str_c(pipeline_name, ".R")
            ),
            store = store_copy,
            callr_function = callr::r
          )
        )
      )
      targets::tar_meta(
        store = store_copy,
        fields = tidyselect::any_of(base::c("name", "seconds", "error"))
      ) |>
        dplyr::filter(.data[["name"]] %in% vec_target_names) |>
        dplyr::mutate(store_copy = store_copy)
    }
  ) |>
  purrr::list_rbind()


#----------------------------------------------------------#
# 3. Compare published and rebuilt partitions -----
#----------------------------------------------------------#

data_pilot_comparison <-
  data_pilot_units |>
  purrr::pmap(
    .f = function(profile_id, store_root, scale_id, pipeline_name,
                  resolution_id, store_production, store_copy, target_name) {
      list_versions <-
        base::list(
          published = store_production,
          corrected = store_copy
        ) |>
        purrr::map(
          .f = ~ targets::tar_read_raw(name = target_name, store = .x)
        )
      mod_selected <-
        targets::tar_read_raw(
          name = stringr::str_c("mod_jsdm_selected_", resolution_id),
          store = store_production
        )
      list_biotic <-
        mod_selected[["settings"]][["biotic"]]

      list_versions |>
        purrr::imap(
          .f = ~ {
            data_fractions <-
              extract_jsdm_variance_fractions(
                anova_object = .x,
                clamp_negative = FALSE
              )
            data_shares <-
              extract_jsdm_variance_fractions(
                anova_object = .x,
                clamp_negative = TRUE
              ) |>
              dplyr::mutate(age = 0) |>
              compute_shapley_variance_components()
            tibble::tibble(
              version = .y,
              component = data_shares[["component"]],
              share_percentage = data_shares[["R2_Nagelkerke_percentage"]],
              fraction_abiotic_associations_spatial =
                data_fractions[["R2_Nagelkerke"]][
                  data_fractions[["component"]] ==
                    "Abiotic&Associations&Spatial"
                ][1]
            )
          }
        ) |>
        purrr::list_rbind() |>
        dplyr::mutate(
          data_source = stringr::str_extract(store_root, "^[a-z]+"),
          scale = stringr::str_remove(store_root, "^[a-z]+_spatial_"),
          scale_id = scale_id,
          resolution_id = resolution_id,
          lambda_cov = list_biotic[["l1_cov"]] + list_biotic[["l2_cov"]],
          .before = 1L
        )
    }
  ) |>
  purrr::list_rbind() |>
  tidyr::pivot_wider(
    names_from = "version",
    values_from = base::c(
      "share_percentage",
      "fraction_abiotic_associations_spatial"
    )
  ) |>
  dplyr::mutate(
    share_difference = .data[["share_percentage_corrected"]] -
      .data[["share_percentage_published"]]
  ) |>
  dplyr::left_join(
    data_rebuild |>
      dplyr::mutate(
        resolution_id = stringr::str_remove(
          .data[["name"]],
          "^list_jsdm_variance_partition_"
        ),
        scale_id = base::basename(base::dirname(.data[["store_copy"]]))
      ) |>
      dplyr::select(
        "scale_id",
        "resolution_id",
        partition_seconds = "seconds"
      ),
    by = dplyr::join_by(scale_id, resolution_id)
  )

readr::write_csv(
  x = data_pilot_comparison,
  file = base::file.path(path_report, "variance_partition_penalty_pilot.csv")
)

base::print(data_pilot_comparison, n = Inf, width = Inf)
