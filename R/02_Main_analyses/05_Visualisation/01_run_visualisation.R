#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               Run stage 05: visualisation
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Workflow contract:
#   Final main-analysis entry point. It requires current stage 04 synthesis and
#   completed temporal models, then rebuilds every publication figure.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)
source(here::here("R/___setup_project___.R"))


#----------------------------------------------------------#
# 1. Validate synthesis prerequisites -----
#----------------------------------------------------------#

path_synthesis_tables <- here::here("Outputs", "Tables")
vec_synthesis_patterns <- base::c(
  "^paleo_patterns_unit_.*[.]csv$",
  "^modern_patterns_unit_.*[.]csv$",
  "^paleo_modern_patterns_comparison_unit_.*[.]csv$"
)
vec_synthesis_files <-
  vec_synthesis_patterns |>
  purrr::map_chr(
    ~ {
      vec_matches <-
        base::list.files(
          path = path_synthesis_tables,
          pattern = .x,
          full.names = TRUE
        ) |>
        base::sort()
      if (
        base::length(vec_matches) == 0L
      ) {
        return(NA_character_)
      }
      return(vec_matches[[base::length(vec_matches)]])
    }
  )
file_budget_provenance <-
  here::here(
    "Documentation",
    "Reports",
    "Model_calibration",
    "sjsdm_cv_fit_budget",
    "budget_publication_provenance.csv"
  )
flag_synthesis_missing <-
  base::any(base::is.na(vec_synthesis_files)) ||
  base::any(!base::file.exists(vec_synthesis_files)) ||
  base::any(base::file.info(vec_synthesis_files)[["size"]] == 0)
flag_synthesis_stale <-
  base::file.exists(file_budget_provenance) &&
  !flag_synthesis_missing &&
  base::any(
    base::file.info(vec_synthesis_files)[["mtime"]] <
      base::file.info(file_budget_provenance)[["mtime"]]
  )

if (
  flag_synthesis_missing || flag_synthesis_stale
) {
  cli::cli_abort(
    base::c(
      "Stage 05 requires current, non-empty stage 04 synthesis tables.",
      "i" = stringr::str_c(
        "Run R/02_Main_analyses/04_Synthesis/",
        "01_run_synthesis.R first."
      )
    )
  )
}


#----------------------------------------------------------#
# 2. Run visualisation components -----
#----------------------------------------------------------#

path_component_root <-
  "R/02_Main_analyses/05_Visualisation/_components"
vec_component_files <-
  base::c(
    "01_plot_paleo_spatial_anova_maps.R",
    "02_plot_paleo_variance_waffle.R",
    "03_plot_paleo_variance_stack.R",
    "04_plot_modern_variance_partitioning.R",
    "05_plot_paleo_modern_comparison.R",
    "06_plot_functional_type_comparison.R",
    "07_plot_paleo_temporal_continents.R"
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
    stage_id = "05_visualisation",
    data_components = data_components,
    run_id = run_id
  )
