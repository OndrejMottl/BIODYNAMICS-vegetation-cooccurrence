#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               Check project configuration
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

path_check_root <-
  withr::local_tempdir()

base::invisible(
  run_configuration_generation(
    path_destination_root = path_check_root
  )
)

vec_generated_paths <-
  base::c(
    "config.yml",
    "Configuration/Generated/profile_catalog.md"
  )

for (
  path_generated_relative in vec_generated_paths
) {
  path_tracked <-
    here::here(path_generated_relative)

  path_regenerated <-
    base::file.path(
      path_check_root,
      path_generated_relative
    )

  if (
    !base::file.exists(path_tracked) ||
      !base::identical(
        base::readBin(
          con = path_tracked,
          what = "raw",
          n = base::file.info(path_tracked)[["size"]]
        ),
        base::readBin(
          con = path_regenerated,
          what = "raw",
          n = base::file.info(path_regenerated)[["size"]]
        )
      )
  ) {
    cli::cli_abort(
      stringr::str_glue(
        "Generated artifact `{path_generated_relative}` is stale."
      )
    )
  }
}

cli::cli_inform(
  message = base::c(
    "v" = "Tracked configuration artifacts match their modular sources."
  )
)
