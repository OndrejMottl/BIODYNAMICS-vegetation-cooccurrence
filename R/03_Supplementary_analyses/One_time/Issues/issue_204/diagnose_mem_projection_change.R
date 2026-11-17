#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#        Diagnose MEM change under the new projections
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Issue #204: for every American and Asian spatial unit (fossil pollen and
#   modern plots, all scales and resolutions), rebuild the Moran eigenvector
#   maps (MEMs) from coordinates projected with the new per-continent
#   projection, regress each new MEM on the stored MEMs of the fitted model,
#   and record the smallest R^2. Production stores are only read.
# The spatial component is linear in the MEMs, so a new basis that the stored
#   one spans almost exactly leaves the fitted model practically unchanged.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

base::source(
  file = "R/___setup_project___.R"
)

# Refit threshold, fixed before the diagnostic was run (16 Nov 2026): a unit
#   needs refitting when any new MEM has R^2 < 0.99 on the stored MEMs, or
#   when the number of MEMs changes.
threshold_r2 <- 0.99

path_report <-
  here::here(
    "Documentation/Reports/Model_evaluation",
    "stage_a_model_input_corrections_2026-11"
  )

list_crs_by_continent <-
  load_config_value(
    config_id = "default",
    value = "spatial_crs_by_continent"
  )

data_units <-
  base::c("paleo", "modern") |>
  purrr::map(
    .f = ~ build_spatial_model_store_index(data_source = .x)
  ) |>
  purrr::list_rbind() |>
  dplyr::mutate(
    continent_id = resolve_continent_ids_from_scale_ids(
      scale_id = .data[["scale_id"]],
      file = here::here("Data/Input/spatial_grid.csv")
    )
  ) |>
  dplyr::filter(
    .data[["continent_id"]] %in% base::c("america", "asia"),
    .data[["store_exists"]]
  )

vec_resolutions <-
  base::list(
    paleo = base::c("genus", "family", "functional_type"),
    modern = base::c("genus", "family", "ft_modern")
  )


#----------------------------------------------------------#
# 1. Compare stored and new MEMs -----
#----------------------------------------------------------#

data_mem_change <-
  data_units |>
  dplyr::mutate(index_unit = dplyr::row_number()) |>
  purrr::pmap(
    .f = function(index_unit, data_source, scale, scale_id, store_path,
                  continent_id, ...) {
      if (
        index_unit %% 25L == 0L
      ) {
        cli::cli_inform("Unit {index_unit} of {base::nrow(data_units)}.")
      }

      data_meta <-
        targets::tar_meta(
          store = store_path,
          fields = tidyselect::all_of(base::c("name", "error"))
        )
      vec_successful <-
        data_meta[["name"]][base::is.na(data_meta[["error"]])]

      list_mev_core_new <-
        base::tryCatch(
          expr = {
            data_coords_new <-
              project_coords_to_metric(
                data_coords = targets::tar_read_raw(
                  name = "data_coords_analysis",
                  store = store_path
                ),
                target_crs = resolve_spatial_crs(
                  scale_id = scale_id,
                  crs_by_continent = list_crs_by_continent
                )
              )
            compute_shared_spatial_mev_basis(
              data_coords_projected = data_coords_new,
              config_spatial_predictors = targets::tar_read_raw(
                name = "config_spatial_predictors",
                store = store_path
              )
            ) |>
              extract_spatial_mev_basis_component(component_name = "data_mev")
          },
          error = function(error_condition) error_condition
        )

      vec_resolutions[[data_source]] |>
        purrr::map(
          .f = ~ {
            resolution_id <- .x
            target_samples <-
              stringr::str_c("data_spatial_mev_samples_", resolution_id)
            target_sample_ids <-
              stringr::str_c("data_sample_ids_checked_", resolution_id)

            data_row <-
              tibble::tibble(
                data_source = data_source,
                continent_id = continent_id,
                scale = scale,
                scale_id = scale_id,
                resolution_id = resolution_id,
                n_samples = NA_integer_,
                n_mev_stored = NA_integer_,
                n_mev_new = NA_integer_,
                r2_min = NA_real_,
                diagnostic_status = NA_character_
              )

            # A unit that stopped upstream has no stored coordinates. Reading
            #   them would fail with the misleading "no package called 'qs'":
            #   `{targets}` falls back to the legacy `qs` reader whenever the
            #   `qs2` read fails, including when the object file is missing.
            if (
              !"data_coords_analysis" %in% vec_successful
            ) {
              return(
                dplyr::mutate(
                  data_row,
                  diagnostic_status = "not_built"
                )
              )
            }
            if (
              base::inherits(list_mev_core_new, "error")
            ) {
              return(
                dplyr::mutate(
                  data_row,
                  diagnostic_status = stringr::str_c(
                    "new_basis_failed: ",
                    base::conditionMessage(list_mev_core_new)
                  )
                )
              )
            }
            if (
              !base::all(
                base::c(target_samples, target_sample_ids) %in% vec_successful
              )
            ) {
              return(
                dplyr::mutate(data_row, diagnostic_status = "no_model_input")
              )
            }

            mat_stored <-
              targets::tar_read_raw(
                name = target_samples,
                store = store_path
              ) |>
              base::as.matrix()
            mat_new <-
              prepare_spatial_predictors_for_fit(
                data_spatial = list_mev_core_new,
                data_sample_ids = targets::tar_read_raw(
                  name = target_sample_ids,
                  store = store_path
                )
              ) |>
              base::as.matrix()

            vec_r2 <-
              base::seq_len(base::ncol(mat_new)) |>
              purrr::map_dbl(
                .f = ~ {
                  vec_new <- mat_new[, .x]
                  fit_new <-
                    stats::lm.fit(
                      x = base::cbind(1, mat_stored),
                      y = vec_new
                    )
                  1 - base::sum(fit_new[["residuals"]]^2) /
                    base::sum((vec_new - base::mean(vec_new))^2)
                }
              )

            dplyr::mutate(
              data_row,
              n_samples = base::nrow(mat_stored),
              n_mev_stored = base::ncol(mat_stored),
              n_mev_new = base::ncol(mat_new),
              r2_min = if (
                base::length(vec_r2) > 0L
              ) {
                base::min(vec_r2)
              } else {
                NA_real_
              },
              diagnostic_status = "compared"
            )
          }
        ) |>
        purrr::list_rbind()
    }
  ) |>
  purrr::list_rbind() |>
  dplyr::mutate(
    threshold_r2 = threshold_r2,
    flag_refit = .data[["diagnostic_status"]] == "compared" &
      (
        .data[["r2_min"]] < threshold_r2 |
          .data[["n_mev_new"]] != .data[["n_mev_stored"]]
      )
  )


#----------------------------------------------------------#
# 2. Mark published models and save -----
#----------------------------------------------------------#

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
      dplyr::mutate(data_source = .y, flag_published = TRUE)
  ) |>
  purrr::list_rbind()

data_mem_report <-
  data_mem_change |>
  dplyr::left_join(
    data_published,
    by = dplyr::join_by(data_source, scale_id, resolution_id)
  ) |>
  dplyr::mutate(
    flag_published = dplyr::coalesce(.data[["flag_published"]], FALSE)
  )

readr::write_csv(
  x = data_mem_report,
  file = base::file.path(path_report, "mem_projection_r2_by_unit.csv")
)

data_refit_fossil <-
  data_mem_report |>
  dplyr::filter(
    .data[["data_source"]] == "paleo",
    .data[["flag_published"]],
    .data[["flag_refit"]] |
      stringr::str_starts(.data[["diagnostic_status"]], "new_basis_failed")
  )

readr::write_csv(
  x = data_refit_fossil,
  file = base::file.path(path_report, "fossil_projection_refit_list.csv")
)

data_mem_report |>
  dplyr::count(
    .data[["data_source"]],
    .data[["continent_id"]],
    .data[["scale"]],
    .data[["diagnostic_status"]],
    .data[["flag_published"]],
    .data[["flag_refit"]]
  ) |>
  base::print(n = Inf, width = Inf)
