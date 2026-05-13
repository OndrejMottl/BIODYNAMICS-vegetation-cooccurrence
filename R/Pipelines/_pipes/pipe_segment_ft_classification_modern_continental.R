#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#   {targets} pipe: Modern FT clustering for one continent
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Modern equivalent of pipe_segment_ft_classification_continental. It
#   reuses the same continental FT clustering factory, but saves the
#   final classification with the modern file prefix and exposes it
#   under file_ft_classification_modern.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

source(
  here::here("R/Pipelines/_pipes/pipe_segment_ft_classification_continental.R")
)


#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

pipe_segment_ft_classification_modern_continental <-
  make_pipe_segment_ft_classification_continental(
    output_target_name = "file_ft_classification_modern",
    data_source_prefix = "modern"
  )
