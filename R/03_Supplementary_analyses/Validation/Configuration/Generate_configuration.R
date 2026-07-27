#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Generate project configuration
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#

base::Sys.setenv(
  BIODYNAMICS_PREPROCESSING_WORKER = "true"
)

base::source(
  file = "R/___setup_project___.R"
)

base::invisible(
  run_configuration_generation()
)
