#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#           Render IAVS 2026 presentation
#
#----------------------------------------------------------#

library(here)

here::i_am("Documentation/Presentations/IAVS_2026/R/render.R")

path_presentation <-
  here::here("Documentation/Presentations/IAVS_2026")

path_output <-
  here::here(
    "Documentation/Presentations/IAVS_2026",
    "_output",
    "index.html"
  )


#----------------------------------------------------------#
# Render presentation -----
#----------------------------------------------------------#

quarto::quarto_render(
  input = path_presentation
)

if (
  !base::file.exists(path_output)
) {
  base::stop(
    "The presentation render completed without the expected HTML output."
  )
}

base::message(
  "Presentation rendered to: ",
  path_output
)
