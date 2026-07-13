#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#            Shared sjSDM tier-tuning pipeline
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Collects compact tuning summaries from isolated spatial-unit stores and
#   publishes one selected regularization artifact per compatible context.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

base::suppressWarnings(
  library(
    "here",
    quietly = TRUE,
    warn.conflicts = FALSE,
    verbose = FALSE
  )
)

base::suppressMessages(
  base::suppressWarnings(
    base::source(
      here::here("R/___setup_project___.R")
    )
  )
)

vec_function_files <-
  base::list.files(
    path = here::here("R/Functions/"),
    pattern = "*.R",
    recursive = TRUE,
    full.names = TRUE
  ) |>
  purrr::discard(
    ~ stringr::str_detect(.x, "_outdated|_legacy")
  )

targets::tar_source(files = vec_function_files)

targets::tar_option_set(
  seed = get_active_config("seed"),
  format = "qs"
)


#----------------------------------------------------------#
# 1. Resolve spatial pipeline context -----
#----------------------------------------------------------#

model_tuning_id <-
  get_active_config(
    value = base::c("model_fitting", "model_tuning_id")
  )

active_config_id <-
  base::Sys.getenv("R_CONFIG_ACTIVE")

flag_temporal_config <-
  stringr::str_starts(
    active_config_id,
    "project_paleo_temporal_"
  )

list_tuning_context <-
  if (
    flag_temporal_config
  ) {
    vec_age_lim <-
      get_active_config(base::c("vegvault_data", "age_lim"))

    time_step <-
      get_active_config(base::c("data_processing", "time_step"))

    base::list(
      pipeline_name = "pipeline_paleo_temporal",
      resolution_ids = stringr::str_c(
        "timeslice_",
        base::seq(
          from = base::min(vec_age_lim),
          to = base::max(vec_age_lim),
          by = time_step
        )
      ),
      nested_unit_stores = FALSE
    )
  } else {
    base::switch(
      model_tuning_id,
      paleo_spatial = base::list(
        pipeline_name = "pipeline_paleo_spatial_resolution",
        resolution_ids = base::c(
          "genus",
          "family",
          "functional_type"
        ),
        nested_unit_stores = TRUE
      ),
      modern_spatial = base::list(
        pipeline_name = "pipeline_modern_spatial_resolution",
        resolution_ids = base::c("genus", "family", "ft_modern"),
        nested_unit_stores = TRUE
      ),
      base::list(
        pipeline_name = NULL,
        resolution_ids = NULL,
        nested_unit_stores = NULL
      )
    )
  }

if (
  base::is.null(list_tuning_context[["pipeline_name"]])
) {
  cli::cli_abort("Tier tuning requires a supported model configuration.")
}


#----------------------------------------------------------#
# 2. Pipeline definition -----
#----------------------------------------------------------#

base::list(
  targets::tar_target(
    description = "Discover completed spatial-unit targets stores",
    name = vec_sjsdm_unit_tuning_stores,
    command = {
      target_store_root <-
        here::here(get_active_config("target_store"))

      unit_store_roots <-
        if (
          list_tuning_context[["nested_unit_stores"]]
        ) {
          fs::dir_ls(
            path = target_store_root,
            type = "directory",
            recurse = FALSE
          )
        } else {
          target_store_root
        }

      unit_store_roots |>
        base::file.path(list_tuning_context[["pipeline_name"]]) |>
        purrr::keep(fs::dir_exists)
    },
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    description = "Collect compact unit tuning summaries",
    name = data_sjsdm_tier_tuning_summaries,
    command = collect_sjsdm_tuning_summaries(
      store_paths = vec_sjsdm_unit_tuning_stores,
      resolution_ids = list_tuning_context[["resolution_ids"]]
    )
  ),
  targets::tar_target(
    description = "Record tier-artifact creation time",
    name = sjsdm_tier_artifact_created_at,
    command = base::Sys.time(),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    description = "Build compatible tier regularization artifacts",
    name = list_sjsdm_tier_tuning_artifacts,
    command = build_sjsdm_tier_tuning_artifacts(
      data_tuning_summary = data_sjsdm_tier_tuning_summaries,
      created_at = sjsdm_tier_artifact_created_at
    )
  ),
  targets::tar_target(
    description = "Publish selected tier regularization artifacts",
    name = data_sjsdm_tier_regularization_artifacts,
    command = list_sjsdm_tier_tuning_artifacts |>
      purrr::chuck("data_artifacts")
  ),
  targets::tar_target(
    description = "Publish source-level tier tuning losses",
    name = data_sjsdm_tier_source_candidate_loss,
    command = list_sjsdm_tier_tuning_artifacts |>
      purrr::chuck("data_source_candidate_loss")
  ),
  targets::tar_target(
    description = "Publish tier candidate aggregation",
    name = data_sjsdm_tier_candidate_aggregation,
    command = list_sjsdm_tier_tuning_artifacts |>
      purrr::chuck("data_candidate_aggregation")
  ),
  targets::tar_target(
    description = "Publish tier weighting sensitivity",
    name = data_sjsdm_tier_selection_sensitivity,
    command = list_sjsdm_tier_tuning_artifacts |>
      purrr::chuck("data_selection_sensitivity")
  )
)
