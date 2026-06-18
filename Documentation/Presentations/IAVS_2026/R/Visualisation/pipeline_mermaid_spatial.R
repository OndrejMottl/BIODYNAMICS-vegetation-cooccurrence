#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#       Generate mermaid diagram for the spatial pipeline
#       (Europe continental, paleo_spatial_resolution)
#
#----------------------------------------------------------#

library(here)

base::source(
  here::here("R", "___setup_project___.R")
)


#----------------------------------------------------------#
# 0. Paths -----
#----------------------------------------------------------#

path_store <-
  here::here(
    "Data",
    "targets",
    "paleo_spatial_continental",
    "europe",
    "pipeline_paleo_spatial_resolution"
  )

path_script <-
  here::here(
    "R",
    "Pipelines",
    "pipeline_paleo_spatial_resolution.R"
  )

path_output <-
  here::here(
    "Documentation",
    "Presentations",
    "IAVS_2026",
    "figures",
    "results",
    "slide_extra_pipeline_spatial.mmd"
  )


#----------------------------------------------------------#
# 1. Generate and save -----
#----------------------------------------------------------#

# R_CONFIG_ACTIVE must be forwarded to the callr subprocess that
# tar_mermaid() uses to source the pipeline script.
mermaid_code <-
  targets::tar_mermaid(
    script = path_script,
    store = path_store,
    targets_only = TRUE,
    outdated = FALSE,
    callr_arguments = list(
      env = c(
        callr::rcmd_safe_env(),
        R_CONFIG_ACTIVE = "project_paleo_spatial_continental"
      )
    )
  )

base::writeLines(
  text = mermaid_code,
  con = path_output
)

cli::cli_inform(
  "Spatial pipeline mermaid saved to {.path {path_output}}"
)
