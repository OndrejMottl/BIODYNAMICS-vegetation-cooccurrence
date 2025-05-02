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
      "The default config is active. Please set specific config.", "\n",
      "See `config.yaml` for available options.", "\n",
      "use Sys.setenv(R_CONFIG_ACTIVE = 'XXX') to set the config."
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

save_progress_visualisation(
  sel_script = here::here("R/02_Main_analyses/pipeline.R"),
  level_separation = 200
)
