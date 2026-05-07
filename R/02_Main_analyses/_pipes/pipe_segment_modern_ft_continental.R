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
# Modern equivalent of pipe_segment_ft_continental. It reuses the
#   same continental FT clustering targets, but saves the final
#   classification with the modern file prefix and exposes it under
#   path_ft_classification_modern.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

source(
  here::here("R/02_Main_analyses/_pipes/pipe_segment_ft_continental.R")
)


#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

pipe_segment_modern_ft_continental <-
  pipe_segment_ft_continental

pipe_segment_modern_ft_continental[[
  base::length(pipe_segment_modern_ft_continental)
]] <-
  targets::tar_target(
    description = stringr::str_glue(
      "Save modern FT classification for this continental unit ",
      "to a dated .qs file and track its path"
    ),
    name = path_ft_classification_modern,
    command = save_ft_classification_for_continent(
      continent_id = get_scale_id_from_store(),
      data_classification = ft_result_continental_unit,
      data_source_prefix = "modern",
      verbose = TRUE
    ),
    format = "file"
  )
