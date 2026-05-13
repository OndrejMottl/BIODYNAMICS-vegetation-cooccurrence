#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#               palette_mother
#    Compatibility loader for MOTHER palette helpers
#
#                   O. Mottl
#                    2025
#
#----------------------------------------------------------#
# Palette and scale implementations live in separate files under
# R/Functions/Presentation/IAVS/. Source this file only when older scripts
# still expect a single palette_mother.R entry point.

vec_palette_function_files <-
  base::file.path(
    here::here(
      "R",
      "Functions",
      "Presentation",
      "IAVS"
    ),
    base::c(
      "mother_palette_values.R",
      "mother_discrete_palette.R",
      "mother_continuous_palette.R",
      "scale_colour_mother_discrete.R",
      "scale_color_mother_discrete.R",
      "scale_fill_mother_discrete.R",
      "scale_colour_mother_continuous.R",
      "scale_color_mother_continuous.R",
      "scale_fill_mother_continuous.R"
    )
  )

for (
  vec_palette_function_file in vec_palette_function_files
) {
  base::sys.source(
    file = vec_palette_function_file,
    envir = base::environment()
  )
}
