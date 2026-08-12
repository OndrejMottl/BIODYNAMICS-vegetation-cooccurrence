#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Generate persisted-contract manifest inventory
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Expand every configured pipeline/profile into its resolved targets for
# Issue #141 v2 contract. This inventory complements the frozen v1 inventory.


#----------------------------------------------------------#
# 1. Load configured profiles and migration decisions -----
#----------------------------------------------------------#

path_config <- here::here("config.yml")

vec_profile_ids <-
  base::readLines(path_config, warn = FALSE, encoding = "UTF-8") |>
  stringr::str_match("^([A-Za-z][A-Za-z0-9_]*):\\s*$") |>
  base::`[`(, 2L) |>
  base::as.character() |>
  stats::na.omit()

data_profiles <-
  purrr::map_dfr(
    vec_profile_ids,
    function(profile_id) {
      list_config <-
        config::get(
          config = profile_id,
          file = path_config
        )

      profile_owner_issue <-
        list_config[["_profile"]][["related_issue"]]
      if (
        base::is.null(profile_owner_issue) ||
          base::length(profile_owner_issue) == 0L ||
          base::is.na(profile_owner_issue)
      ) {
        profile_owner_issue <- ""
      } else {
        profile_owner_issue <- base::as.character(profile_owner_issue)
      }

      tibble::tibble(
        profile_id = profile_id,
        profile_role = list_config[["_profile"]][["role"]],
        profile_status = list_config[["_profile"]][["status"]],
        profile_selectable = list_config[["_profile"]][["selectable"]],
        pipeline_id = list_config[["_profile"]][["pipeline"]],
        target_store = list_config[["target_store"]],
        profile_owner_issue = profile_owner_issue
      )
    }
  )

data_migration <-
  readr::read_csv(
    here::here(
      "Documentation/Implementation_inventories/R_architecture",
      "r_persisted_contract_migration_v1.csv"
    ),
    show_col_types = FALSE
  )

data_target_migration <-
  data_migration |>
  dplyr::filter(
    .data[["surface_type"]] == "target",
    .data[["current_name"]] != .data[["intended_name"]]
  ) |>
  dplyr::mutate(
    intended_name_length = base::nchar(.data[["intended_name"]])
  ) |>
  dplyr::arrange(dplyr::desc(.data[["intended_name_length"]]))


#----------------------------------------------------------#
# 2. Map profile pipeline identifiers to entry files -----
#----------------------------------------------------------#

data_pipeline_scripts <-
  tibble::tribble(
    ~pipeline_id, ~pipeline_script,
    "paleo_spatial", "R/Pipelines/pipeline_paleo_spatial_resolution.R",
    "paleo_temporal", "R/Pipelines/pipeline_paleo_temporal.R",
    "modern_spatial", "R/Pipelines/pipeline_modern_spatial_resolution.R",
    "paleo_smoke", "R/Pipelines/pipeline_paleo_core.R",
    "paleo_smoke", "R/Pipelines/pipeline_paleo_resolution_test.R",
    "modern_spatial_smoke", "R/Pipelines/pipeline_modern_spatial_resolution_test.R",
    "paleo_core_cv", "R/Pipelines/pipeline_paleo_core.R",
    "paleo_cv_component_reference", "R/Pipelines/pipeline_cz_paleo_cv_component_reference.R",
    "paleo_cv_regularization_reference", "R/Pipelines/pipeline_cz_paleo_cv_regularization_reference.R",
    "paleo_local_cv", "R/Pipelines/pipeline_paleo_local_cv_scientific_reference.R",
    "paleo_local_cv_decomposition", "R/Pipelines/pipeline_paleo_local_cv_decomposition_reference.R",
    "traits", "R/Pipelines/pipeline_traits_reference.R",
    "issue_138_paleo_spatial", "R/Pipelines/pipeline_paleo_spatial_resolution.R",
    "issue_138_modern_spatial", "R/Pipelines/pipeline_modern_spatial_resolution.R",
    "issue_138_paleo_temporal", "R/Pipelines/pipeline_paleo_temporal.R",
    "issue_143_modern_spatial", "R/Pipelines/pipeline_modern_spatial_resolution.R"
  )

data_profile_scripts <-
  data_profiles |>
  dplyr::left_join(
    data_pipeline_scripts,
    by = "pipeline_id",
    relationship = "many-to-many"
  )

if (
  base::any(
    base::is.na(data_profile_scripts[["pipeline_script"]]) &
      data_profile_scripts[["pipeline_id"]] != "shared"
  )
) {
  base::stop("Every non-shared configured pipeline must have an entry file.")
}


#----------------------------------------------------------#
# 3. Expand manifests and translate approved names -----
#----------------------------------------------------------#

match_target_migration <-
  function(target_name) {
    vec_match <-
      target_name == data_target_migration[["intended_name"]] |
      base::startsWith(
        target_name,
        base::paste0(data_target_migration[["intended_name"]], "_")
      )

    if (!base::any(vec_match)) {
      return(
        tibble::tibble(
          legacy_target_name = NA_character_,
          target_owner_issue = NA_character_,
          migration_status = "unchanged"
        )
      )
    }

    index_match <- base::which(vec_match)[[1L]]
    intended_base <- data_target_migration[["intended_name"]][[index_match]]
    legacy_base <- data_target_migration[["current_name"]][[index_match]]

    tibble::tibble(
      legacy_target_name = base::paste0(
        legacy_base,
        base::substring(target_name, base::nchar(intended_base) + 1L)
      ),
      target_owner_issue =
        data_target_migration[["owning_issue"]][[index_match]],
      migration_status = "migrated_in_issue_156"
    )
  }

data_manifest_inventory <-
  purrr::pmap_dfr(
    data_profile_scripts,
    function(
      profile_id,
      profile_role,
      profile_status,
      profile_selectable,
      pipeline_id,
      target_store,
      profile_owner_issue,
      pipeline_script
    ) {
      if (base::is.na(pipeline_script)) {
        return(
          tibble::tibble(
            profile_id = profile_id,
            profile_role = profile_role,
            profile_status = profile_status,
            profile_selectable = profile_selectable,
            pipeline_id = pipeline_id,
            target_store = target_store,
            profile_owner_issue = profile_owner_issue,
            pipeline_script = NA_character_,
            manifest_target_count = 0L,
            target_name = NA_character_,
            legacy_target_name = NA_character_,
            target_owner_issue = NA_character_,
            migration_status = "profile_without_entry_file"
          )
        )
      }

      old_profile <- Sys.getenv("R_CONFIG_ACTIVE", unset = NA_character_)
      on.exit(
        if (base::is.na(old_profile)) {
          Sys.unsetenv("R_CONFIG_ACTIVE")
        } else {
          Sys.setenv(R_CONFIG_ACTIVE = old_profile)
        },
        add = TRUE
      )
      Sys.setenv(R_CONFIG_ACTIVE = profile_id)

      data_manifest <-
        targets::tar_manifest(
          script = here::here(pipeline_script)
        )

      vec_target_names <- base::as.character(data_manifest[["name"]])
      data_translation <- purrr::map_dfr(vec_target_names, match_target_migration)

      tibble::tibble(
        profile_id = profile_id,
        profile_role = profile_role,
        profile_status = profile_status,
        profile_selectable = profile_selectable,
        pipeline_id = pipeline_id,
        target_store = target_store,
        profile_owner_issue = profile_owner_issue,
        pipeline_script = pipeline_script,
        manifest_target_count = base::nrow(data_manifest),
        target_name = vec_target_names
      ) |>
        dplyr::bind_cols(data_translation)
    }
  ) |>
  dplyr::arrange(
    .data[["profile_id"]],
    .data[["pipeline_script"]],
    .data[["target_name"]]
  )


#----------------------------------------------------------#
# 4. Write deterministic snapshot -----
#----------------------------------------------------------#

readr::write_csv(
  data_manifest_inventory,
  here::here(
    "Documentation/Implementation_inventories/R_architecture",
    "r_manifest_contract_inventory_v2.csv"
  ),
  na = ""
)

base::message(
  "Recorded ",
  base::nrow(data_manifest_inventory),
  " profile-target rows across ",
  dplyr::n_distinct(data_manifest_inventory[["profile_id"]]),
  " configured profiles."
)
