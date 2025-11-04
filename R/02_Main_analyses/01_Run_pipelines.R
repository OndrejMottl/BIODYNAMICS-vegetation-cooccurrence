#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#                 Run the specific pipelines
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# Run the specific target pipeline


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)


#----------------------------------------------------------#
# 2. Run the pipelines -----
#----------------------------------------------------------#

# Basic pipeline
run_pipeline(
  sel_script = "R/02_Main_analyses/pipeline_basic.R",
  level_separation = 100
)

# Pipeline with time slices
run_pipeline(
  sel_script = "R/02_Main_analyses/pipeline_time.R",
  level_separation = 300
)