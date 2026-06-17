#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#               create_oracle_theme
#      Loader for ORACLE theme helpers
#
#                   O. Mottl
#                    2025
#
#----------------------------------------------------------#
# The theme implementation lives in
# R/Functions/Presentation/IAVS/Oracle_theme/create_oracle_theme.R.

vec_theme_function_files <-
  base::file.path(
    here::here(
      "R",
      "Functions",
      "Presentation",
      "IAVS"
    ),
    base::c(
      "Oracle_palettes/get_oracle_palette_values.R",
      "Oracle_palettes/get_oracle_discrete_palette.R",
      "Oracle_palettes/get_oracle_continuous_palette.R",
      "Oracle_scales/scale_colour_oracle_discrete.R",
      "Oracle_scales/scale_color_oracle_discrete.R",
      "Oracle_scales/scale_fill_oracle_discrete.R",
      "Oracle_scales/scale_colour_oracle_continuous.R",
      "Oracle_scales/scale_color_oracle_continuous.R",
      "Oracle_scales/scale_fill_oracle_continuous.R",
      "Oracle_theme/create_oracle_theme.R"
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
