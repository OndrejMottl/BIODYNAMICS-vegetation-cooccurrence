#----------------------------------------------------------#
#
#
#           BIODYNAMICS — Vegetation Co-occurrence
#
#              Redo all progress visualisations
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#

# Re-generates every project_status HTML (and PNG) file under
# Documentation/Progress/ using the current save_progress_visualisation(),
# which applies the BIODYNAMICS brand theme (dark background, brand fonts,
# brand-coloured edges).
#
# How it works:
#   1. Recursively scans Data/targets/ for leaf directories named
#      "pipeline_basic" or "pipeline_time".
#   2. Maps the pipeline name to the corresponding pipeline script in
#      R/02_Main_analyses/.
#   3. Calls save_progress_visualisation() for each store found.
#
# Run interactively or via:
#   Rscript R/03_Supplementary_analyses/Redo_progress_visualisations.R


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)


#----------------------------------------------------------#
# 1. Discover all pipeline store directories -----
#----------------------------------------------------------#

# Map pipeline folder name → script path
list_pipeline_scripts <-
  base::list(
    pipeline_basic = here::here(
      "R/02_Main_analyses/pipeline_basic.R"
    ),
    pipeline_time = here::here(
      "R/02_Main_analyses/pipeline_time.R"
    )
  )

vec_pipeline_names <-
  base::names(list_pipeline_scripts)

# Find every directory under Data/targets/ whose final component
# is one of the known pipeline names.
vec_all_dirs <-
  base::list.dirs(
    path = here::here("Data/targets"),
    full.names = TRUE,
    recursive = TRUE
  )

vec_store_dirs <-
  vec_all_dirs[
    base::basename(vec_all_dirs) %in% vec_pipeline_names
  ]

n_stores <-
  base::length(vec_store_dirs)

cli::cli_inform(
  c(
    "i" = "Found {n_stores} pipeline store{?s} to visualise."
  )
)


#----------------------------------------------------------#
# 2. Re-generate visualisations -----
#----------------------------------------------------------#

vec_store_dirs |>
  purrr::walk(
    .f = ~ {
      store_path <- .x
      pipeline_name <- base::basename(store_path)

      sel_script <-
        list_pipeline_scripts |>
        purrr::chuck(pipeline_name)

      cli::cli_inform(
        c("i" = "Processing: {store_path}")
      )

      tryCatch(
        save_progress_visualisation(
          sel_script = sel_script,
          sel_store = store_path
        ),
        error = function(err) {
          cli::cli_warn(
            c(
              "!" = "Skipping store (targets metadata unavailable):",
              " " = store_path,
              "i" = base::conditionMessage(err)
            )
          )
        }
      )
    }
  )

cli::cli_inform(
  c("v" = "All progress visualisations updated.")
)
