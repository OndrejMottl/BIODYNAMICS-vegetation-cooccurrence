#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Common-regularization sensitivity pipeline
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Selects one regularization candidate across compatible spatial tiers and
#   refits the configured continental, regional, and local representatives.


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
  seed = load_active_config_value("seed"),
  format = "qs"
)


#----------------------------------------------------------#
# 1. Resolve spatial project family -----
#----------------------------------------------------------#

model_tuning_id <-
  load_active_config_value(
    base::c("model_fitting", "model_tuning_id")
  )

list_spatial_project <-
  base::switch(
    model_tuning_id,
    paleo_spatial = base::list(
      profile_ids = base::c(
        "project_paleo_spatial_continental",
        "project_paleo_spatial_regional",
        "project_paleo_spatial_local"
      ),
      pipeline_name = "pipeline_paleo_spatial_resolution",
      resolution_ids = base::c(
        "genus",
        "family",
        "functional_type"
      )
    ),
    modern_spatial = base::list(
      profile_ids = base::c(
        "project_modern_spatial_continental",
        "project_modern_spatial_regional",
        "project_modern_spatial_local"
      ),
      pipeline_name = "pipeline_modern_spatial_resolution",
      resolution_ids = base::c("genus", "family", "ft_modern")
    ),
    NULL
  )

if (
  base::is.null(list_spatial_project)
) {
  cli::cli_abort(
    "Common regularization requires a spatial model configuration."
  )
}

read_profile_context <- function(profile_id) {
  list_config <-
    load_config(
      config_id = profile_id,
      file = here::here("config.yml")
    )

  tibble::tibble(
    profile_id = profile_id,
    tier_id = purrr::chuck(
      list_config,
      "model_fitting",
      "cross_validation",
      "tier_id"
    ),
    representative_scale_id = purrr::chuck(
      list_config,
      "model_fitting",
      "cross_validation",
      "common_regularization_sensitivity",
      "representative_scale_id"
    ),
    enabled = purrr::chuck(
      list_config,
      "model_fitting",
      "cross_validation",
      "common_regularization_sensitivity",
      "enabled"
    ),
    target_store_root = here::here(
      purrr::chuck(list_config, "target_store")
    )
  )
}

data_spatial_profile_context <-
  list_spatial_project[["profile_ids"]] |>
  purrr::map(read_profile_context) |>
  purrr::list_rbind() |>
  dplyr::filter(.data[["enabled"]])


#----------------------------------------------------------#
# 2. Pipeline definition -----
#----------------------------------------------------------#

base::list(
  targets::tar_target(
    description = "Configured representative spatial model contexts",
    name = data_sjsdm_common_profile_context,
    command = data_spatial_profile_context
  ),
  targets::tar_target(
    description = "Collect tuning summaries across spatial tiers",
    name = data_sjsdm_common_tuning_summaries,
    command = data_sjsdm_common_profile_context |>
      dplyr::group_split(.data[["profile_id"]]) |>
      purrr::map(
        ~ {
          vec_store_paths <-
            fs::dir_ls(
              path = .x[["target_store_root"]][[1L]],
              type = "directory",
              recurse = FALSE
            ) |>
            base::file.path(list_spatial_project[["pipeline_name"]]) |>
            purrr::keep(fs::dir_exists)

          collect_sjsdm_tuning_summaries(
            store_paths = vec_store_paths,
            resolution_ids = list_spatial_project[["resolution_ids"]]
          )
        }
      ) |>
      purrr::list_rbind(),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    description = "Record common-artifact creation time",
    name = sjsdm_common_artifact_created_at,
    command = base::Sys.time(),
    cue = targets::tar_cue(mode = "always")
  ),
  targets::tar_target(
    description = "Build common regularization artifacts",
    name = list_sjsdm_common_regularization_artifacts,
    command = build_sjsdm_common_regularization_artifacts(
      data_tuning_summary = data_sjsdm_common_tuning_summaries,
      created_at = sjsdm_common_artifact_created_at
    )
  ),
  targets::tar_target(
    description = "Publish common selected candidates",
    name = data_sjsdm_common_regularization_artifacts,
    command = list_sjsdm_common_regularization_artifacts |>
      purrr::chuck("data_artifacts")
  ),
  targets::tar_target(
    description = "Publish equal-tier candidate losses",
    name = data_sjsdm_common_candidate_aggregation,
    command = list_sjsdm_common_regularization_artifacts |>
      purrr::chuck("data_candidate_aggregation")
  ),
  targets::tar_target(
    description = "Index representative model stores",
    name = data_sjsdm_common_model_index,
    command = tidyr::crossing(
      data_sjsdm_common_profile_context,
      resolution_id = list_spatial_project[["resolution_ids"]]
    ) |>
      dplyr::mutate(
        model_id = stringr::str_c(
          .data[["tier_id"]],
          .data[["representative_scale_id"]],
          .data[["resolution_id"]],
          sep = "/"
        ),
        scale_id = .data[["representative_scale_id"]],
        store_path = base::file.path(
          .data[["target_store_root"]],
          .data[["scale_id"]],
          list_spatial_project[["pipeline_name"]]
        )
      ) |>
      dplyr::select(
        "model_id",
        "tier_id",
        "scale_id",
        "resolution_id",
        "store_path"
      )
  ),
  targets::tar_target(
    description = "Run representative common-regularization refits",
    name = list_sjsdm_common_sensitivity_results,
    command = run_sjsdm_common_regularization_sensitivity(
      data_model_index = data_sjsdm_common_model_index,
      data_artifacts = data_sjsdm_common_regularization_artifacts
    )
  ),
  targets::tar_target(
    description = "Publish common-regularization models",
    name = list_sjsdm_common_sensitivity_models,
    command = list_sjsdm_common_sensitivity_results |>
      purrr::chuck("list_models")
  ),
  targets::tar_target(
    description = "Publish common-regularization ANOVA objects",
    name = list_sjsdm_common_sensitivity_anova,
    command = list_sjsdm_common_sensitivity_results |>
      purrr::chuck("list_anova")
  ),
  targets::tar_target(
    description = "Publish common-regularization model provenance",
    name = data_sjsdm_common_sensitivity_provenance,
    command = list_sjsdm_common_sensitivity_results |>
      purrr::chuck("data_provenance")
  ),
  targets::tar_target(
    description = "Publish common-regularization decompositions",
    name = data_sjsdm_common_sensitivity_decomposition,
    command = list_sjsdm_common_sensitivity_results |>
      purrr::chuck("data_decomposition")
  )
)
