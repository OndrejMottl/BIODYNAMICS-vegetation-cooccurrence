#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#           Update the configuration semantic reference
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Regenerates config.yml and the profile catalog and accepts differences
#   from the semantic reference only when each one is declared in
#   Documentation/Implementation_inventories/Configuration/
#   configuration_reference_changes.csv. Undeclared differences abort.

base::Sys.setenv(
  BIODYNAMICS_PREPROCESSING_WORKER = "true"
)

base::source(
  file = "R/___setup_project___.R"
)

base::invisible(
  run_configuration_generation(
    path_reference_changes = here::here(
      "Documentation/Implementation_inventories/Configuration",
      "configuration_reference_changes.csv"
    )
  )
)
