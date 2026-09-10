#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#                  Run stage 04: synthesis
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Workflow contract:
#   Requires successful spatial model fitting in stage 03. It builds paleo and
#   modern summaries before their matched comparison. It never fits models.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)
source(here::here("R/___setup_project___.R"))


#----------------------------------------------------------#
# 1. Validate model-output prerequisites -----
#----------------------------------------------------------#

vec_data_sources <- base::c("paleo", "modern")
vec_spatial_tiers <- base::c("continental", "regional", "local")
vec_resolution_ids <- base::c(
  "genus",
  "family",
  "functional_type"
)
data_available_outputs <-
  vec_data_sources |>
  purrr::map(
    ~ build_spatial_model_store_index(data_source = .x) |>
      load_spatial_model_results(
        resolution_ids = vec_resolution_ids,
        require_non_empty = FALSE
      )
  ) |>
  purrr::list_rbind() |>
  dplyr::distinct(
    .data[["data_source"]],
    .data[["scale"]],
    .data[["resolution_id"]]
  )
data_required_outputs <-
  tidyr::expand_grid(
    data_source = vec_data_sources,
    scale = vec_spatial_tiers,
    resolution_id = vec_resolution_ids
  )
data_missing_outputs <-
  data_required_outputs |>
  dplyr::anti_join(
    data_available_outputs,
    by = dplyr::join_by(data_source, scale, resolution_id)
  )

if (
  base::nrow(data_missing_outputs) > 0L
) {
  cli::cli_abort(
    base::c(
      "Stage 04 requires completed spatial outputs from stage 03.",
      "x" = paste(
        "Missing tier-resolution outputs:",
        base::paste(
          base::apply(data_missing_outputs, 1L, base::paste, collapse = "/"),
          collapse = ", "
        )
      ),
      "i" = stringr::str_c(
        "Run R/02_Main_analyses/03_Model_fitting/",
        "01_run_model_fitting.R first."
      )
    )
  )
}


#----------------------------------------------------------#
# 2. Run synthesis components -----
#----------------------------------------------------------#

path_component_root <-
  "R/02_Main_analyses/04_Synthesis/_components"
vec_component_files <-
  base::c(
    "01_analyse_paleo_spatial_patterns.R",
    "02_analyse_modern_spatial_patterns.R",
    "03_compare_paleo_modern.R"
  )
data_components <-
  tibble::tibble(
    component_id = stringr::str_remove(vec_component_files, "[.]R$"),
    script_path = fs::path(path_component_root, vec_component_files)
  )
run_id <-
  base::format(base::Sys.time(), "%Y%m%d_%H%M%S")

data_stage_status <-
  run_main_analysis_stage(
    stage_id = "04_synthesis",
    data_components = data_components,
    run_id = run_id,
    next_stage_script = paste(
      "R/02_Main_analyses/05_Visualisation/",
      "01_run_visualisation.R",
      sep = ""
    )
  )
