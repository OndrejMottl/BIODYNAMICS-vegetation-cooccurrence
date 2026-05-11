#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#               theme_mother
#      Compatibility loader for MOTHER theme
#
#                   O. Mottl
#                    2025
#
#----------------------------------------------------------#
# The theme implementation lives in
# R/Functions/Presentation/IAVS/theme_mother.R. Source this file only when
# older scripts still expect a single theme_mother.R entry point.

vec_theme_function_files <-
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
      "scale_fill_mother_continuous.R",
      "theme_mother.R"
    )
  )

for (
  vec_theme_function_file in vec_theme_function_files
) {
  base::sys.source(
    file = vec_theme_function_file,
    envir = base::environment()
  )
}
