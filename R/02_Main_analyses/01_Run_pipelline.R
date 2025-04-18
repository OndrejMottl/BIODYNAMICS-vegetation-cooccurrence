#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#                     Run the main pipe
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# Run the main target pipe


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

#----------------------------------------------------------#
# 1. Check the active {config} control -----
#----------------------------------------------------------#

if (
  config::is_active("default")
) {
  stop(
    paste(
      "The default config is active. Please set specific config.",
      "See `config.yaml` for available options."
    )
  )
}

#----------------------------------------------------------#
# 2. Run the pipeline -----
#----------------------------------------------------------#

targets::tar_make(
  script = here::here("R/02_Main_analyses/pipeline.R"),
  store = get_active_config("target_store")
)

#----------------------------------------------------------#
# 3. Save the status of the project -----
#----------------------------------------------------------#

network_graph <-
  targets::tar_visnetwork(
    script = here::here("R/02_Main_analyses/pipeline.R"),
    store = get_active_config("target_store"),
    targets_only = TRUE
  )

visNetwork::visSave(
  graph = network_graph,
  file = here::here(
    "Outputs/Figures/project_status.html"
  ),
  background = "white",
  selfcontained = TRUE
)

webshot2::webshot(
  url = here::here(
    "Outputs/Figures/project_status.html"
  ),
  file = here::here(
    "Outputs/Figures/project_status_static.png"
  )
)
