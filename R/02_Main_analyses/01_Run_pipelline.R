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
# 1. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)


#----------------------------------------------------------#
# 2. Run the pipeline -----
#----------------------------------------------------------#

targets::tar_make(
  script = here::here("R/02_Main_analyses/pipeline.R"),
  store = config::get(
    value = "target_store",
    config =  Sys.getenv("R_CONFIG_ACTIVE"),
    use_parent = FALSE,
    file = here::here("config.yml")
  )
)

targets::tar_visnetwork(
  script = here::here("R/02_Main_analyses/pipeline.R"),
  store = config::get(
    value = "target_store",
    config =  Sys.getenv("R_CONFIG_ACTIVE"),
    use_parent = FALSE,
    file = here::here("config.yml")
  ),
  targets_only = TRUE
)
