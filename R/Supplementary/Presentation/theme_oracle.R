#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#               theme_oracle
#      Loader for ORACLE theme helpers
#
#                   O. Mottl
#                    2025
#
#----------------------------------------------------------#
# The theme implementation lives in
# R/Functions/Presentation/IAVS/theme_oracle.R.

vec_theme_function_files <-
  base::file.path(
    here::here(
      "R",
      "Functions",
      "Presentation",
      "IAVS"
    ),
    base::c(
      "oracle_palette_values.R",
      "oracle_discrete_palette.R",
      "oracle_continuous_palette.R",
      "scale_colour_oracle_discrete.R",
      "scale_color_oracle_discrete.R",
      "scale_fill_oracle_discrete.R",
      "scale_colour_oracle_continuous.R",
      "scale_color_oracle_continuous.R",
      "scale_fill_oracle_continuous.R",
      "theme_oracle.R"
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
