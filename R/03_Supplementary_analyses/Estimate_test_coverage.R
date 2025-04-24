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

library(covr)
library(jsonlite)

data_covr <-
  covr::file_coverage(
    source_files = list.files(
      here::here("R/Functions/"),
      recursive = TRUE,
      full.names = TRUE
    ),
    test_files = list.files(
      here::here("R/03_Supplementary_analyses/testthat"),
      recursive = TRUE,
      full.names = TRUE
    )
  )

data_covr %>%
  as.data.frame() %>%
  jsonlite::write_json(
    path = here::here("Documentation/function_test_coverage.json"),
    auto_unbox = TRUE,
    pretty = TRUE
  )

covr::report(
  x = covr::file_coverage(
    source_files = list.files(
      here::here("R/Functions/"),
      recursive = TRUE,
      full.names = TRUE
    ),
    test_files = list.files(
      here::here("tests/testthat"),
      recursive = TRUE,
      full.names = TRUE
    )
  ),
  file = here::here("Documentation/function_test_coverage.html"),
  browse = FALSE
)
