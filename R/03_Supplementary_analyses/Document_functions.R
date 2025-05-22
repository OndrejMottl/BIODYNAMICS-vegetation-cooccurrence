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
      output_directory = here::here(
        "Documentation/Functions"
      )
    ),
    otherwise = NULL,
    quiet = TRUE
  )
)


# Make QUARTO site for each function
vec_html_files <-
  list.files(
    path = here::here("Documentation/Functions"),
    pattern = "\\.html$",
    full.names = TRUE,
    recursive = TRUE
  )

purrr::walk(
  .x = vec_html_files,
  .f = purrr::possibly(
    .f = ~ {
      base_name <-
        fs::path_file(.x)

      name_no_ext <-
        fs::path_ext_remove(base_name)

      # Read the content of the HTML file
      html_content <-
        readLines(.x, warn = FALSE)

      # Define the content of the .qmd file
      qmd_content <-
        c(
          "---",
          "format: html",
          paste0("title: ", name_no_ext, "()"),
          "---",
          "",
          html_content
        )

      # Remove the first line of the HTML content
      # (which is the DOCTYPE declaration)
      qmd_content[6] <-
        qmd_content[6] %>%
        stringr::str_remove(
          pattern = "^<!DOCTYPE html>"
        )  %>% 
        # remove the <title> div as well
        stringr::str_remove(
          pattern = "<title>.*</title>"
        )

      # Write the content to a .qmd file
      writeLines(
        qmd_content,
        here::here(
          "website/Documentation/Functions",
          paste0(
            fs::path_ext_remove(base_name),
            ".qmd"
          )
        )
      )
    }
  ),
  otherwise = NULL,
  quiet = TRUE
)
