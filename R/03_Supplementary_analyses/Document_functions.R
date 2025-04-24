#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#                   Make documentation
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# Cretae all documentation files in the project using roxygen2

library(here)

source(
  here::here("R/___setup_project___.R")
)

library(document)

purrr::walk(
  .x = list.files(
    path = here::here("R/Functions"),
    full.names = TRUE,
    pattern = "\\.R$",
    recursive = TRUE
  ),
  .f = purrr::possibly(
    .f = ~ document::document(
      file = .x,
      check_package = FALSE,
      working_directory = tempdir(),
      output_directory = here::here(
        "R/Functions/Documentation"
      )
    )
  )
)
