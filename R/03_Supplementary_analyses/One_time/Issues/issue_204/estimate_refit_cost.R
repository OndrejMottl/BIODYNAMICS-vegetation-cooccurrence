#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Estimate the compute cost of Stage B refits
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Issues #203 and #204: for every published spatial model (fossil pollen and
#   modern plots, all continents), sum the recorded runtime of the targets
#   that a refit would rebuild, split by component. The runtimes come from
#   the `seconds` field of each production store's metadata, so they describe
#   the last build of each target. Production stores are only read.
# The projection change (#204) rebuilds every target downstream of
#   `data_coords_projected`; the partition fix (#203) rebuilds only
#   `list_jsdm_variance_partition_<resolution>`.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

base::source(
  file = "R/___setup_project___.R"
)

path_report <-
  here::here(
    "Documentation/Reports/Model_evaluation",
    "stage_a_model_input_corrections_2026-11"
  )

vec_resolutions <-
  base::c("genus", "family", "functional_type", "ft_modern")

data_published <-
  base::c(paleo = "paleo", modern = "modern") |>
  purrr::imap(
    .f = ~ readr::read_csv(
      file = here::here(
        "Outputs/Tables",
        stringr::str_c(.x, "_patterns_unit_2026-10-22.csv")
      ),
      show_col_types = FALSE
    ) |>
      dplyr::distinct(.data[["scale_id"]], .data[["resolution_id"]]) |>
      dplyr::mutate(data_source = .y)
  ) |>
  purrr::list_rbind()

data_projection_refit <-
  readr::read_csv(
    file = base::file.path(path_report, "mem_projection_r2_by_unit.csv"),
    show_col_types = FALSE
  ) |>
  dplyr::mutate(
    flag_refit_projection = .data[["flag_refit"]] |
      stringr::str_starts(.data[["diagnostic_status"]], "new_basis_failed")
  ) |>
  dplyr::select(
    "data_source", "scale_id", "resolution_id", "flag_refit_projection"
  )

data_stores <-
  load_model_store_index() |>
  dplyr::filter(
    .data[["store_kind"]] == "spatial_unit",
    .data[["store_exists"]],
    .data[["scale_id"]] %in% data_published[["scale_id"]]
  ) |>
  dplyr::semi_join(
    dplyr::distinct(
      data_published,
      .data[["data_source"]],
      .data[["scale_id"]]
    ),
    by = dplyr::join_by(data_source, scale_id)
  ) |>
  dplyr::mutate(
    continent_id = resolve_continent_ids_from_scale_ids(
      scale_id = .data[["scale_id"]],
      file = here::here("Data/Input/spatial_grid.csv")
    )
  )


#----------------------------------------------------------#
# 1. Targets downstream of the projected coordinates -----
#----------------------------------------------------------#

# The pipeline definition does not depend on the unit, so the network is
#   read once per pipeline and profile.
data_network_keys <-
  data_stores |>
  dplyr::distinct(
    .data[["pipeline_script"]],
    .data[["profile_id"]],
    .keep_all = TRUE
  )

list_downstream <-
  data_network_keys |>
  purrr::pmap(
    .f = function(pipeline_script, profile_id, store_path, ...) {
      list_network <-
        withr::with_envvar(
          new = base::c(R_CONFIG_ACTIVE = profile_id),
          code = targets::tar_network(
            script = pipeline_script,
            store = store_path,
            targets_only = TRUE,
            outdated = FALSE,
            callr_function = NULL
          )
        )
      graph_targets <-
        igraph::graph_from_data_frame(
          d = list_network[["edges"]],
          vertices = list_network[["vertices"]]["name"]
        )
      igraph::subcomponent(
        graph = graph_targets,
        v = "data_coords_projected",
        mode = "out"
      ) |>
        base::names()
    }
  ) |>
  rlang::set_names(
    stringr::str_c(
      data_network_keys[["pipeline_script"]],
      "|",
      data_network_keys[["profile_id"]]
    )
  )


#----------------------------------------------------------#
# 2. Sum recorded runtimes per unit and component -----
#----------------------------------------------------------#

data_cost <-
  data_stores |>
  purrr::pmap(
    .f = function(data_source, scale, scale_id, continent_id, store_path,
                  pipeline_script, profile_id, ...) {
      vec_downstream <-
        list_downstream[[stringr::str_c(pipeline_script, "|", profile_id)]]

      # Branch runtimes are already summed into their pattern.
      targets::tar_meta(
        store = store_path,
        fields = tidyselect::all_of(base::c("name", "type", "seconds"))
      ) |>
        dplyr::filter(
          .data[["type"]] %in% base::c("stem", "pattern"),
          .data[["name"]] %in% vec_downstream
        ) |>
        dplyr::mutate(
          resolution_id = stringr::str_extract(
            .data[["name"]],
            stringr::str_c(
              "(?<=_)(",
              stringr::str_c(vec_resolutions, collapse = "|"),
              ")$"
            )
          ) |>
            dplyr::coalesce("shared"),
          component = dplyr::case_when(
            stringr::str_starts(
              .data[["name"]],
              "list_jsdm_variance_partition"
            ) ~ "partition",
            stringr::str_starts(.data[["name"]], "mod_jsdm") ~ "final_fit",
            stringr::str_detect(
              .data[["name"]],
              "tuning|cross_validation|_cv_"
            ) ~ "cross_validation",
            .default = "other"
          )
        ) |>
        dplyr::summarise(
          hours = base::sum(.data[["seconds"]], na.rm = TRUE) / 3600,
          .by = tidyselect::all_of(base::c("resolution_id", "component"))
        ) |>
        dplyr::mutate(
          data_source = data_source,
          continent_id = continent_id,
          scale = scale,
          scale_id = scale_id,
          .before = 1L
        )
    }
  ) |>
  purrr::list_rbind() |>
  tidyr::pivot_wider(
    names_from = "component",
    values_from = "hours",
    names_prefix = "hours_",
    values_fill = 0
  )

data_cost_published <-
  data_cost |>
  dplyr::semi_join(
    dplyr::bind_rows(
      data_published,
      dplyr::distinct(
        data_published,
        .data[["data_source"]],
        .data[["scale_id"]]
      ) |>
        dplyr::mutate(resolution_id = "shared")
    ),
    by = dplyr::join_by(data_source, scale_id, resolution_id)
  ) |>
  dplyr::left_join(
    data_projection_refit,
    by = dplyr::join_by(data_source, scale_id, resolution_id)
  ) |>
  dplyr::mutate(
    hours_refit_chain = .data[["hours_cross_validation"]] +
      .data[["hours_final_fit"]] +
      .data[["hours_partition"]] +
      .data[["hours_other"]]
  ) |>
  dplyr::arrange(
    .data[["data_source"]],
    .data[["continent_id"]],
    .data[["scale"]],
    .data[["scale_id"]],
    .data[["resolution_id"]]
  )

readr::write_csv(
  x = data_cost_published,
  file = base::file.path(path_report, "refit_cost_by_unit.csv")
)

data_cost_published |>
  dplyr::summarise(
    n_units = dplyr::n_distinct(.data[["scale_id"]]),
    n_models = base::sum(.data[["resolution_id"]] != "shared"),
    hours_cross_validation = base::sum(.data[["hours_cross_validation"]]),
    hours_final_fit = base::sum(.data[["hours_final_fit"]]),
    hours_partition = base::sum(.data[["hours_partition"]]),
    hours_refit_chain = base::sum(.data[["hours_refit_chain"]]),
    .by = tidyselect::all_of(base::c("data_source", "continent_id", "scale"))
  ) |>
  base::print(n = Inf, width = Inf)
