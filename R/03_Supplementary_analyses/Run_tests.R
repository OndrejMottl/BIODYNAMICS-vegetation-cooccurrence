#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#                       Run tests
#
#
#                       O. Mottl
#                         2025
# ;
#----------------------------------------------------------#
# Run all tests in the project

library(here)

source(
  here::here("R/___setup_project___.R")
)

library(testthat)

testthat::test_dir(
  here::here(
    "R/03_Supplementary_analyses/testthat"
  )
)
