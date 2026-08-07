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

base::source(
  here::here(
    "Documentation",
    "Presentations",
    "IAVS_2026",
    "R",
    "load_iavs_functions.R"
  )
)

load_iavs_functions()

list_oracle_design <-
  load_design_config()

vec_scss_path <-
  save_generated_oracle_scss(
    design = list_oracle_design
  )

cli::cli_alert_success(
  stringr::str_glue(
    "Design tokens synchronized: {vec_scss_path}"
  )
)
