#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#          Render IAVS 2026 presentation
#
#                   O. Mottl
#                    2026
#
#----------------------------------------------------------#
# Render the IAVS 2026 RevealJS presentation.
#   The presentation's _quarto.yml runs load_design_config.R as a
#   pre-render step, which regenerates mother_generated.scss from
#   design_config.json before the slides are compiled.

library(here)
library(quarto)

#----------------------------------------------------------#
# 1. Render -----
#----------------------------------------------------------#

quarto::quarto_render(
  input = here::here(
    "Documentation/Presentations/IAVS_2026"
  )
)
