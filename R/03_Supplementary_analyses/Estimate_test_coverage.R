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
      here::here(
        "R/03_Supplementary_analyses/testthat"
      ),
      recursive = TRUE,
      full.names = TRUE
    )
  )

data_covr %>%
  as.data.frame() %>%
  jsonlite::write_json(
    path = here::here(
      "Documentation/Functions_test_coverage/covr_report.json"
    ),
    auto_unbox = TRUE,
    pretty = TRUE
  )

covr::report(
  x = data_covr,
  file = here::here(
    "Documentation/Functions_test_coverage/covr_report.html"
  ),
  browse = FALSE
)

covr:::tally_coverage(data_covr, by = "line") %>%
  covr:::percent_coverage(by = "line") %>%
  round(digits = 2) %>%
  list(value = .) %>%
  jsonlite::write_json(
    x = .,
    path = here::here(
      "Documentation/Functions_test_coverage/covr_report_summary.json"
    ),
    auto_unbox = TRUE,
    pretty = TRUE
  )
