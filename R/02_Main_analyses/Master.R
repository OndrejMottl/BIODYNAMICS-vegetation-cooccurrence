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
# 1. Load packages -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

targets::tar_make(
  script = here::here("R/02_Main_analyses/run_pipe.R"),
  store = config::get(
    value = "target_store",
    config =  Sys.getenv("R_CONFIG_ACTIVE"),
    use_parent = FALSE,
    file = here::here("config.yml")
  )
)

targets::tar_visnetwork(
  script = here::here("R/02_Main_analyses/run_pipe.R"),
  store = config::get(
    value = "target_store",
    config =  Sys.getenv("R_CONFIG_ACTIVE"),
    use_parent = FALSE,
    file = here::here("config.yml")
  ),
  targets_only = TRUE
)
