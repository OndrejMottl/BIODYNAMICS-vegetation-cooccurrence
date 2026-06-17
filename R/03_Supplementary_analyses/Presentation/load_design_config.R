#----------------------------------------------------------#
#
#
#       BIODYNAMICS Vegetation Co-occurrence
#
#              load_design_config
#    Compatibility loader for design config helpers
#
#                   O. Mottl
#                    2025
#
#----------------------------------------------------------#
# Design config implementations live in separate files under
# R/Functions/Presentation/IAVS/. Source this file only when older scripts
# still expect a single load_design_config.R entry point.

vec_design_function_files <-
  base::file.path(
    here::here(
      "R",
      "Functions",
      "Presentation",
      "IAVS"
    ),
    base::c(
      "Paths_and_config/get_presentation_dir.R",
      "Paths_and_config/resolve_design_path.R",
      "Paths_and_config/load_design_config.R",
      "Design_tokens/format_token_name.R",
      "Design_tokens/flatten_token_node.R",
      "Design_tokens/flatten_design_tokens.R",
      "Design_tokens/format_scss_value.R",
      "Design_tokens/write_oracle_generated_scss.R"
    )
  )

for (
  vec_design_function_file in vec_design_function_files
) {
  base::sys.source(
    file = vec_design_function_file,
    envir = base::environment()
  )
}

if (
  !base::exists("list_oracle_design")
) {
  list_oracle_design <-
    load_design_config()

  write_oracle_generated_scss(list_oracle_design)
}
