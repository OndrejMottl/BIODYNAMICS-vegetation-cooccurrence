#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#               palette_oracle
#      Loader for ORACLE palette helpers
#
#                   O. Mottl
#                    2025
#
#----------------------------------------------------------#
# Palette and scale implementations live in separate files under
# R/Functions/Presentation/IAVS/.

vec_palette_function_files <-
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
      "Oracle_scales/scale_fill_oracle_continuous.R"
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
