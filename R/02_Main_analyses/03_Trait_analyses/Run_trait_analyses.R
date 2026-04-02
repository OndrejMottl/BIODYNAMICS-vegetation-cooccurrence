#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Run trait analyses: master runner
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Master runner for the trait analysis workflow.
# Executes all three trait analysis scripts in sequence:
#   1. Extract trait data from VegVault
#   2. Classify taxa and align to community genera
#   3. Build genus × traits table and check coverage
#
# Note: script 01 (extraction) is slow due to the large
#   VegVault SQLite file. Expect 15–60 min on first run.
#   Outputs are cached in Data/Processed/ as .qs files.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)


#----------------------------------------------------------#
# 1. Extract trait data -----
#----------------------------------------------------------#

source(
  here::here(
    "R/02_Main_analyses/03_Trait_analyses/01_Extract_trait_data.R"
  )
)


#----------------------------------------------------------#
# 2. Classify and align taxa -----
#----------------------------------------------------------#

source(
  here::here(
    "R/02_Main_analyses/03_Trait_analyses/02_Classify_and_align_taxa.R"
  )
)


#----------------------------------------------------------#
# 3. Build trait table -----
#----------------------------------------------------------#

source(
  here::here(
    "R/02_Main_analyses/03_Trait_analyses/03_Build_trait_table.R"
  )
)
