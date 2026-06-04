#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#        Pre-render IAVS 2026 design tokens
#
#----------------------------------------------------------#

library(here)

here::i_am("Documentation/Presentations/IAVS_2026/R/pre_render.R")

source(
  here::here("R/03_Supplementary_analyses/Presentation/load_design_config.R")
)

list_oracle_design <-
  load_design_config()

vec_scss_path <-
  write_oracle_generated_scss(
    design = list_oracle_design
  )

cli::cli_alert_success(
  stringr::str_glue(
    "Design tokens synchronized: {vec_scss_path}"
  )
)
