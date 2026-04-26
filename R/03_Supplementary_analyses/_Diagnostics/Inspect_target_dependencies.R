#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#            Inspect written target dependencies
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Export direct target dependencies as CSV tables and a
#   simple matrix plot. This is intended as a readable
#   alternative to `tar_visnetwork()` when the interactive
#   graph becomes too dense.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

# Edit these values before sourcing the script.
Sys.setenv(R_CONFIG_ACTIVE = "project_spatial_continental")

sel_script <-
  "R/02_Main_analyses/pipeline_spatial_resolution.R"

scale_id <- "europe"

graphical_options <-
  get_active_config("graphical")


#----------------------------------------------------------#
# 1. Resolve paths -----
#----------------------------------------------------------#

path_script <-
  here::here(sel_script)

name_pipeline <-
  stringr::str_remove(
    string = base::basename(path_script),
    pattern = "\\.R$"
  )

path_store <-
  here::here(
    get_active_config("target_store"),
    scale_id,
    name_pipeline
  )


flag_store_exists <-
  fs::dir_exists(path_store)

if (
  isTRUE(flag_store_exists)
) {
  base::message(
    stringr::str_glue("Using target store: {path_store}")
  )
} else {
  base::message(
    stringr::str_glue(
      "Store not found at {path_store}. ",
      "Dependencies will be read from the pipeline definition only."
    )
  )
}


#----------------------------------------------------------#
# 2. Build dependency tables -----
#----------------------------------------------------------#

list_target_graph <-
  if (
    isTRUE(flag_store_exists)
  ) {
    targets::tar_network(
      script = path_script,
      store = path_store,
      targets_only = TRUE,
      outdated = FALSE
    )
  } else {
    targets::tar_network(
      script = path_script,
      targets_only = TRUE,
      outdated = FALSE
    )
  }

data_target_vertices <-
  list_target_graph |>
  purrr::chuck("vertices") |>
  dplyr::rename(
    target_name = name,
    target_type = type,
    target_description = description,
    target_status = status,
    target_seconds = seconds,
    target_bytes = bytes,
    n_branches = branches
  ) |>
  dplyr::arrange(target_name)

data_target_edges <-
  list_target_graph |>
  purrr::chuck("edges") |>
  dplyr::rename(
    upstream_target = from,
    downstream_target = to
  ) |>
  dplyr::arrange(downstream_target, upstream_target)

data_target_dependencies <-
  data_target_edges |>
  dplyr::left_join(
    data_target_vertices |>
      dplyr::select(
        upstream_target = target_name
      ),
    by = dplyr::join_by(upstream_target)
  ) |>
  dplyr::left_join(
    data_target_vertices |>
      dplyr::select(
        downstream_target = target_name
      ),
    by = dplyr::join_by(downstream_target)
  ) |>
  dplyr::arrange(downstream_target, upstream_target)

print(data_target_dependencies, n = Inf)
